#include "E04ProfileFormat.h"
#include "E04ProfileInternals.h"
#include "Modules/ModuleManager.h"

IMPLEMENT_MODULE(FDefaultModuleImpl, E04ProfileParser)

namespace Warhammer::E04A1
{
FParseResult ParseDocument(TConstArrayView<uint8> Input, EFormat Format) noexcept
{
    FParseResult Result;
    Result.InputByteCount = Input.Num();
    auto Fail = [&Result](EParseCode Code, int64 Observed = 0, int64 Limit = 0)
    {
        Result.Code = Code;
        Result.Diagnostic = FDiagnostic{Code, {}, Observed, Limit};
    };
    if (Format != EFormat::Yaml)
    { Fail(EParseCode::UnsupportedFormat); return Result; }
    // Refuse BEFORE stream construction, copying, decoding or vendor parsing.
    if (Result.InputByteCount > FLimits::MaxInputBytes)
    { Fail(EParseCode::InputTooLarge, Result.InputByteCount, FLimits::MaxInputBytes); return Result; }
    if (Input.IsEmpty())
    { Fail(EParseCode::NoDocument); return Result; }
    // Raw YAML NUL/EOT are not escaped decoded scalar bytes. Refuse before
    // vendor UTF16/32 sniffing or its raw 0x04 EOF sentinel can reinterpret them.
    for (uint8 Byte : Input)
    { if (Byte == 0 || Byte == 0x04) { Fail(EParseCode::MalformedYaml); return Result; } }
    if (!Private::IsWellFormedUtf8(Input))
    { Fail(EParseCode::MalformedYaml); return Result; }
    try
    {
        FDocument Complete = Private::ReadYamlDocument(Input);
        Complete.OriginalBytes.Append(Input.GetData(), Input.Num());
        Result.Document = MoveTemp(Complete);
        Result.Code = EParseCode::Success;
        Result.Diagnostic = {};
    }
    catch (const Private::FRefusal& Error)
    {
        Result.Code = Error.Diagnostic.Code;
        Result.Diagnostic = Error.Diagnostic;
    }
    // Unknown/std allocation exceptions intentionally terminate at noexcept.
    // No partial graph or refused original has been published into Result.
    return Result;
}
}
