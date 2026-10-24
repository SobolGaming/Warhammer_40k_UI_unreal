#pragma once

#include "E04ProfileFormat.h"

namespace Warhammer::E04A1::Private
{
// Private signal only: caught before crossing the exported noexcept boundary.
struct FRefusal
{
    FDiagnostic Diagnostic;
};

[[noreturn]] inline void Refuse(EParseCode Code, FSourceMark Mark = {},
    int64 Observed = 0, int64 Limit = 0)
{
    throw FRefusal{FDiagnostic{Code, Mark, Observed, Limit}};
}

// Checks encoding, not YAML tokens. No conversion or null-terminated strings.
inline bool IsWellFormedUtf8(TConstArrayView<uint8> Bytes) noexcept
{
    for (int32 Index = 0; Index < Bytes.Num();)
    {
        const uint8 Lead = Bytes[Index++];
        if (Lead < 0x80) { continue; }
        uint32 Value;
        uint32 Minimum;
        int32 Remaining;
        if (Lead >= 0xC2 && Lead <= 0xDF)
        { Value = Lead & 0x1F; Minimum = 0x80; Remaining = 1; }
        else if (Lead >= 0xE0 && Lead <= 0xEF)
        { Value = Lead & 0x0F; Minimum = 0x800; Remaining = 2; }
        else if (Lead >= 0xF0 && Lead <= 0xF4)
        { Value = Lead & 0x07; Minimum = 0x10000; Remaining = 3; }
        else { return false; }
        if (Remaining > Bytes.Num() - Index) { return false; }
        while (Remaining-- > 0)
        {
            const uint8 Next = Bytes[Index++];
            if ((Next & 0xC0) != 0x80) { return false; }
            Value = (Value << 6) | (Next & 0x3F);
        }
        if (Value < Minimum || Value > 0x10FFFF ||
            (Value >= 0xD800 && Value <= 0xDFFF)) { return false; }
    }
    return true;
}

// Full pinned public Parser/callback entry source was inspected after acquisition.
// This source binding is not compile, ABI, runtime or compatibility evidence.
FDocument ReadYamlDocument(TConstArrayView<uint8> Input);
}
