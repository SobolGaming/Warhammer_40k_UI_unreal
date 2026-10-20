#include "E04ProfileInternals.h"

#include <yaml-cpp/eventhandler.h>
#include <yaml-cpp/exceptions.h>
#include <yaml-cpp/mark.h>
#include <yaml-cpp/parser.h>
#include <sstream>
#include <string>

// Source-bound to acquired 56e3bb550c91fd7005566f19c079cb7a503223cf:
// parser.h/parser.cpp confirm stream lifetime and complete HandleNextDocument
// driving; callback/mark/anchor/style/exception declarations match below.
// Source inspection is not compilation/ABI/runtime evidence. All OnNull events
// refuse; pinned scalar escapes producing invalid UTF8 refuse before copying.

namespace Warhammer::E04A1::Private
{
namespace
{
FSourceMark Observe(const YAML::Mark& Mark)
{
    return FSourceMark{!Mark.is_null(), Mark.pos, Mark.line, Mark.column};
}

bool IsSupportedTag(const std::string& Tag)
{
    // Compare BEFORE copying expanded text. Explicit null is not supported A1.
    return Tag == "?" || Tag == "!" ||
        Tag == "tag:yaml.org,2002:str" || Tag == "tag:yaml.org,2002:bool" ||
        Tag == "tag:yaml.org,2002:int" || Tag == "tag:yaml.org,2002:float" ||
        Tag == "tag:yaml.org,2002:seq" || Tag == "tag:yaml.org,2002:map";
}

void CopyBytes(TArray<uint8>& Destination, const std::string& Source)
{
    if (Source.size() > static_cast<size_t>(MAX_int32))
    { Refuse(EParseCode::InvalidEventStream); }
    if (!Source.empty())
    {
        Destination.Append(reinterpret_cast<const uint8*>(Source.data()),
            static_cast<int32>(Source.size()));
    }
}

ECollectionStyle ObserveStyle(YAML::EmitterStyle::value Style)
{
    switch (Style)
    {
    case YAML::EmitterStyle::Default: return ECollectionStyle::Default;
    case YAML::EmitterStyle::Block: return ECollectionStyle::Block;
    case YAML::EmitterStyle::Flow: return ECollectionStyle::Flow;
    default: Refuse(EParseCode::InvalidEventStream);
    }
}

struct FFrame
{
    int32 Node = INDEX_NONE;
    int32 PendingKey = INDEX_NONE;
};

class FEventGraph final : public YAML::EventHandler
{
public:
    explicit FEventGraph(int64 InInputBytes) : InputBytes(InInputBytes) {}

    void OnDocumentStart(const YAML::Mark& Mark) override
    {
        if (DocumentCount != 0) { Refuse(EParseCode::MultipleDocuments, Observe(Mark)); }
        DocumentCount = 1;
        bDocumentOpen = true;
    }

    void OnDocumentEnd() override
    {
        if (!bDocumentOpen || !Stack.IsEmpty() || !PendingAnchor.IsEmpty() ||
            Document.Root == INDEX_NONE) { Refuse(EParseCode::InvalidEventStream); }
        bDocumentOpen = false;
        bDocumentComplete = true;
    }

    void OnNull(const YAML::Mark& Mark, YAML::anchor_t) override
    {
        // Includes tag-only EOF: the callback does not expose those properties.
        // Observe the rejected raw node, but EVERY OnNull takes this refusal.
        Refuse(EParseCode::NullPropertiesUnavailable, Observe(Mark), RawNodeCount + 1);
    }

    void OnAlias(const YAML::Mark& Mark, YAML::anchor_t Anchor) override
    {
        if (!PendingAnchor.IsEmpty()) { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
        const int64 NextAliases = static_cast<int64>(Document.ObservedAliasOccurrences) + 1;
        if (NextAliases > FLimits::MaxAliasOccurrences)
        { Refuse(EParseCode::AliasLimit, Observe(Mark), NextAliases, FLimits::MaxAliasOccurrences); }
        const int32* Target = Anchors.Find(static_cast<uint64>(Anchor));
        if (Target == nullptr) { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
        const int32 TargetIndex = *Target;
        CountNode(Mark);
        FNode Node;
        Node.Kind = ENodeKind::Alias;
        Node.Mark = Observe(Mark);
        Node.AliasTarget = TargetIndex;
        const int32 Index = Document.Nodes.Add(MoveTemp(Node));
        ++Document.ObservedAliasOccurrences;
        Attach(Index);
    }

    void OnScalar(const YAML::Mark& Mark, const std::string& Tag,
        YAML::anchor_t Anchor, const std::string& Value) override
    {
        CheckTag(Tag, Mark);
        if (Value.size() > static_cast<size_t>(FLimits::MaxScalarUtf8Bytes))
        { Refuse(EParseCode::ScalarLimit, Observe(Mark), static_cast<int64>(Value.size()), FLimits::MaxScalarUtf8Bytes); }
        // Pinned Exp::Escape emits single-byte 0x85/0xA0 for \\N/\\_. Do not
        // publish invalid UTF8 as an authoritative value; decoded NUL is valid.
        if (!IsWellFormedUtf8(TConstArrayView<uint8>(
            reinterpret_cast<const uint8*>(Value.data()), static_cast<int32>(Value.size()))))
        { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
        CountNode(Mark);
        FNode Node;
        Node.Kind = ENodeKind::Scalar;
        Node.Mark = Observe(Mark);
        Node.bTagAvailable = true;
        CopyBytes(Node.ScalarUtf8, Value);
        CopyBytes(Node.TagUtf8, Tag);
        AddDefinition(MoveTemp(Node), Anchor, Mark);
    }

    void OnSequenceStart(const YAML::Mark& Mark, const std::string& Tag,
        YAML::anchor_t Anchor, YAML::EmitterStyle::value Style) override
    { BeginCollection(ENodeKind::Sequence, Mark, Tag, Anchor, Style); }

    void OnSequenceEnd() override { EndCollection(ENodeKind::Sequence); }

    void OnMapStart(const YAML::Mark& Mark, const std::string& Tag,
        YAML::anchor_t Anchor, YAML::EmitterStyle::value Style) override
    { BeginCollection(ENodeKind::Mapping, Mark, Tag, Anchor, Style); }

    void OnMapEnd() override { EndCollection(ENodeKind::Mapping); }

    void OnAnchor(const YAML::Mark& Mark, const std::string& Name) override
    {
        // Names are source text, copied once per definition, never per alias.
        if (!PendingAnchor.IsEmpty() || Name.empty() ||
            Name.size() > static_cast<size_t>(InputBytes) ||
            TotalAnchorBytes + static_cast<int64>(Name.size()) > InputBytes)
        { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
        TotalAnchorBytes += static_cast<int64>(Name.size());
        CopyBytes(PendingAnchor, Name);
    }

    FDocument TakeComplete()
    {
        if (DocumentCount == 0) { Refuse(EParseCode::NoDocument); }
        if (!bDocumentComplete || bDocumentOpen || !Stack.IsEmpty() ||
            !PendingAnchor.IsEmpty() || Document.Root == INDEX_NONE ||
            RawNodeCount != Document.Nodes.Num()) { Refuse(EParseCode::InvalidEventStream); }
        return MoveTemp(Document);
    }

private:
    void CountNode(const YAML::Mark& Mark)
    {
        if (!bDocumentOpen) { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
        const int64 Next = RawNodeCount + 1;
        if (Next > FLimits::MaxRawNodes)
        { Refuse(EParseCode::NodeLimit, Observe(Mark), Next, FLimits::MaxRawNodes); }
        RawNodeCount = Next;
    }

    static void CheckTag(const std::string& Tag, const YAML::Mark& Mark)
    {
        if (!IsSupportedTag(Tag)) { Refuse(EParseCode::UnsupportedTag, Observe(Mark)); }
    }

    void Attach(int32 Index)
    {
        if (Stack.IsEmpty())
        {
            if (Document.Root != INDEX_NONE) { Refuse(EParseCode::InvalidEventStream); }
            Document.Root = Index;
            return;
        }
        // Obtain references only AFTER Nodes.Add; never retain across growth.
        FFrame& Frame = Stack.Last();
        FNode& Parent = Document.Nodes[Frame.Node];
        if (Parent.Kind == ENodeKind::Sequence) { Parent.Children.Add(Index); }
        else if (Parent.Kind == ENodeKind::Mapping)
        {
            if (Frame.PendingKey == INDEX_NONE) { Frame.PendingKey = Index; }
            else
            {
                Parent.Pairs.Add(FMappingPair{Frame.PendingKey, Index});
                Frame.PendingKey = INDEX_NONE;
            }
        }
        else { Refuse(EParseCode::InvalidEventStream); }
    }

    int32 AddDefinition(FNode&& Node, YAML::anchor_t Anchor, const YAML::Mark& Mark)
    {
        const uint64 Id = static_cast<uint64>(Anchor);
        if (Anchor != YAML::NullAnchor)
        {
            if (Id > static_cast<uint64>(MAX_int32) || Anchors.Contains(Id) || PendingAnchor.IsEmpty())
            { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
            Node.AnchorDefinitionId = static_cast<int32>(Id);
            Node.AnchorNameUtf8 = MoveTemp(PendingAnchor);
        }
        else if (!PendingAnchor.IsEmpty()) { Refuse(EParseCode::InvalidEventStream, Observe(Mark)); }
        const int32 Index = Document.Nodes.Add(MoveTemp(Node));
        // Register before collection children so an alias can target its ancestor.
        if (Anchor != YAML::NullAnchor) { Anchors.Add(Id, Index); }
        Attach(Index);
        return Index;
    }

    void BeginCollection(ENodeKind Kind, const YAML::Mark& Mark,
        const std::string& Tag, YAML::anchor_t Anchor, YAML::EmitterStyle::value Style)
    {
        CheckTag(Tag, Mark);
        const int64 Depth = static_cast<int64>(Stack.Num()) + 1;
        if (Depth > FLimits::MaxCollectionDepth)
        { Refuse(EParseCode::DepthLimit, Observe(Mark), Depth, FLimits::MaxCollectionDepth); }
        CountNode(Mark);
        FNode Node;
        Node.Kind = Kind;
        Node.Mark = Observe(Mark);
        Node.bTagAvailable = true;
        Node.CollectionStyle = ObserveStyle(Style);
        CopyBytes(Node.TagUtf8, Tag);
        const int32 Index = AddDefinition(MoveTemp(Node), Anchor, Mark);
        Stack.Add(FFrame{Index, INDEX_NONE});
        Document.ObservedMaximumCollectionDepth = FMath::Max(
            Document.ObservedMaximumCollectionDepth, static_cast<int32>(Depth));
    }

    void EndCollection(ENodeKind Kind)
    {
        if (Stack.IsEmpty() || Document.Nodes[Stack.Last().Node].Kind != Kind ||
            Stack.Last().PendingKey != INDEX_NONE) { Refuse(EParseCode::InvalidEventStream); }
        Stack.Pop();
    }

    FDocument Document;
    TArray<FFrame> Stack;
    TMap<uint64, int32> Anchors;
    TArray<uint8> PendingAnchor;
    int64 InputBytes;
    int64 TotalAnchorBytes = 0;
    int64 RawNodeCount = 0;
    int32 DocumentCount = 0;
    bool bDocumentOpen = false;
    bool bDocumentComplete = false;
};
}

FDocument ReadYamlDocument(TConstArrayView<uint8> Input)
{
    // Binary/length-delimited input; no strlen, ANSI conversion or borrowed data.
    const std::string Bytes(reinterpret_cast<const char*>(Input.GetData()),
        static_cast<size_t>(Input.Num()));
    std::istringstream Stream(Bytes, std::ios::in | std::ios::binary);
    try
    {
        YAML::Parser Parser(Stream);
        FEventGraph Graph(Input.Num());
        while (Parser.HandleNextDocument(Graph)) {}
        return Graph.TakeComplete();
    }
    catch (const YAML::ParserException& Error)
    {
        Refuse(EParseCode::MalformedYaml, Observe(Error.mark));
    }
}
}
