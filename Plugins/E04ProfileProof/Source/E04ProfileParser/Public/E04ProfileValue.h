#pragma once

#include "CoreMinimal.h"

namespace Warhammer::E04A1
{
enum class ENodeKind : uint8 { Scalar, Sequence, Mapping, Alias };
enum class ECollectionStyle : uint8 { Unavailable, Default, Block, Flow };

// Signed vendor start observations. Units/end spans are deliberately unclaimed.
struct FSourceMark
{
    bool bAvailable = false;
    int32 Position = 0;
    int32 Line = 0;
    int32 Column = 0;
};

struct FMappingPair
{
    int32 KeyNode = INDEX_NONE;
    int32 ValueNode = INDEX_NONE;
};

struct FNode
{
    ENodeKind Kind = ENodeKind::Scalar;
    FSourceMark Mark;
    // Length-delimited decoded bytes, including any embedded/trailing zero.
    TArray<uint8> ScalarUtf8;
    TArray<uint8> TagUtf8;
    TArray<uint8> AnchorNameUtf8;
    bool bTagAvailable = false;
    int32 AnchorDefinitionId = INDEX_NONE;
    int32 AliasTarget = INDEX_NONE;
    ECollectionStyle CollectionStyle = ECollectionStyle::Unavailable;
    TArray<int32> Children;
    // Keys are nodes too. Order, equal keys and case-distinct keys survive.
    TArray<FMappingPair> Pairs;
};

struct FDocument
{
    TArray<uint8> OriginalBytes;
    TArray<FNode> Nodes;
    int32 Root = INDEX_NONE;
    int32 ObservedMaximumCollectionDepth = 0;
    int32 ObservedAliasOccurrences = 0;
};
}
