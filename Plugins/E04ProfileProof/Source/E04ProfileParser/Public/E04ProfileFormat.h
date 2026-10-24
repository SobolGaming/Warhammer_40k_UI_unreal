#pragma once

#include "Containers/ArrayView.h"
#include "E04ProfileValue.h"

namespace Warhammer::E04A1
{
enum class EFormat : uint8 { Yaml };
enum class EParseCode : uint8
{
    Success,
    UnsupportedFormat,
    InputTooLarge,
    NoDocument,
    MultipleDocuments,
    NullPropertiesUnavailable,
    UnsupportedTag,
    DepthLimit,
    NodeLimit,
    AliasLimit,
    ScalarLimit,
    MalformedYaml,
    InvalidEventStream
};

struct FLimits
{
    static constexpr int64 MaxInputBytes = 1048576;
    static constexpr int32 MaxCollectionDepth = 64;
    static constexpr int32 MaxRawNodes = 100000;
    static constexpr int32 MaxAliasOccurrences = 10000;
    static constexpr int64 MaxScalarUtf8Bytes = 65536;
};

struct FDiagnostic
{
    EParseCode Code = EParseCode::Success;
    FSourceMark Mark;
    int64 Observed = 0;
    int64 Limit = 0;
};

struct FParseResult
{
    EParseCode Code = EParseCode::NoDocument;
    int64 InputByteCount = 0;
    FDiagnostic Diagnostic;
    // Empty on EVERY refusal; the caller/harness owns the refused original.
    FDocument Document;

    bool IsSuccess() const noexcept { return Code == EParseCode::Success; }
};

// A1 raw UTF-8 YAML only. No filesystem, normalization, conversion or export.
// The input view must remain valid for the duration of this synchronous call.
E04PROFILEPARSER_API FParseResult ParseDocument(
    TConstArrayView<uint8> Input, EFormat Format = EFormat::Yaml) noexcept;
}
