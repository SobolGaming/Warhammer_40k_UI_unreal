"""Guarded canonical payload capture. Binding data never supply execution authority."""

BINDINGS_PATH = "__UNBOUND_EXACT_BINDINGS_PATH__"
BINDINGS_SHA256 = "__UNBOUND_EXACT_BINDINGS_SHA256__"
if "__UNBOUND" in BINDINGS_PATH or "__UNBOUND" in BINDINGS_SHA256:
    raise SystemExit("UNBOUND source proposal: do not execute or import")

# Run only a separately frozen bound copy after SOURCE admission and exact runtime GO.
import dataclasses
import hashlib
import importlib
import importlib.abc
import importlib.machinery
import importlib.util
import json
import math
import os
from pathlib import Path
import sys
import time

STARTED = time.monotonic()
DEADLINE = STARTED + 60
UI = "warhammer40k_arcade_ui"
DENIED_PREFIXES = (
    "warhammer40k_core", "arcade", "pyglet", "orjson", "platformdirs",
    "socket", "ssl", "subprocess", "multiprocessing", "ctypes", "site",
    "urllib", "http",
)
ORIGINAL_UI_NAMES = {
    UI, UI + ".config", UI + ".preferences.diagnostics",
    UI + ".preferences.registries", UI + ".preferences.schema",
    UI + ".hud.toolkit", UI + ".hud.composition", UI + ".resources",
    UI + ".resources.source",
}
NAMESPACE_NAMES = {UI + ".hud", UI + ".preferences", UI + ".render"}
COLOR_NAME = UI + ".render.primitives"
YAML_NAMES = {"yaml"} | {
    "yaml." + name for name in (
        "composer", "constructor", "dumper", "emitter", "error", "events",
        "loader", "nodes", "parser", "reader", "representer", "resolver",
        "scanner", "serializer", "tokens",
    )
}
EXPECTED_OPTIONAL_REFUSALS = {"yaml.cyaml", "yaml._yaml"}
DENIED_ATTEMPTS: list[str] = []


def tick() -> None:
    if time.monotonic() >= DEADLINE:
        raise RuntimeError("reference capture internal deadline exceeded")


def forbidden(name: str) -> bool:
    return any(name == prefix or name.startswith(prefix + ".")
               for prefix in DENIED_PREFIXES)


def verified(descriptor: dict) -> bytes:
    tick()
    path = Path(descriptor["path"])
    size = descriptor["bytes"]
    if not path.is_absolute() or type(size) is not int or not 0 <= size <= 1048576:
        raise ValueError("invalid or oversized exact descriptor")
    if path.stat().st_size != size:
        raise ValueError("descriptor size drift: " + str(path))
    raw = path.read_bytes()
    if len(raw) != size or hashlib.sha256(raw).hexdigest().upper() != descriptor["sha256"]:
        raise ValueError("descriptor hash drift: " + str(path))
    return raw


def reject(name: str) -> None:
    DENIED_ATTEMPTS.append(name)
    raise ImportError("A2P0 exact import boundary refused: " + name)


class OriginalBytesLoader(importlib.abc.Loader):
    def __init__(self, raw: bytes, filename: str):
        self.raw, self.filename = raw, filename

    def create_module(self, spec):
        return None

    def exec_module(self, module):
        tick()
        module.__file__ = self.filename
        exec(compile(self.raw, self.filename, "exec", dont_inherit=True), module.__dict__)


class ExactFinder(importlib.abc.MetaPathFinder):
    def __init__(self, modules: dict):
        self.modules = modules

    def find_spec(self, fullname, path=None, target=None):
        if fullname in EXPECTED_OPTIONAL_REFUSALS:
            reject(fullname)  # Original yaml.__init__ handles its optional cyaml ImportError.
        if fullname in NAMESPACE_NAMES:
            spec = importlib.machinery.ModuleSpec(fullname, loader=None, is_package=True)
            spec.submodule_search_locations = []
            return spec
        if fullname in self.modules:
            raw, filename, package = self.modules[fullname]
            loader = OriginalBytesLoader(raw, filename)
            spec = importlib.util.spec_from_loader(fullname, loader, is_package=package)
            if package:
                spec.submodule_search_locations = []
            return spec
        if forbidden(fullname) or fullname == UI or fullname.startswith(UI + "."):
            reject(fullname)
        if fullname == "yaml" or fullname.startswith("yaml."):
            reject(fullname)
        if fullname.split(".", 1)[0] not in sys.stdlib_module_names:
            reject(fullname)
        return None


def check_import_boundary() -> None:
    unexpected = set(DENIED_ATTEMPTS) - EXPECTED_OPTIONAL_REFUSALS
    loaded = [name for name in sys.modules if forbidden(name)]
    if unexpected or loaded:
        raise RuntimeError("forbidden import attempted/present: " + repr((unexpected, loaded)))
    tick()


PROJECTION_NODES = 0


def snapshot(value, depth=0, ancestors=frozenset()):
    """Typed capture format only: this is not a legacy/target export format."""
    global PROJECTION_NODES
    PROJECTION_NODES += 1
    if depth > 64 or PROJECTION_NODES > 100000:
        raise ValueError("capture projection bound exceeded")
    if value is None or type(value) in (str, bool, int):
        return {"kind": type(value).__name__, "value": value}
    if type(value) is float:
        if not math.isfinite(value):
            raise ValueError("nonfinite float outside capture projection")
        return {"kind": "float", "hex": value.hex()}
    if isinstance(value, Path):
        return {"kind": "path", "value": str(value)}
    identity = id(value)
    if identity in ancestors:
        raise ValueError("cycle in capture projection")
    nested = ancestors | {identity}
    convert = lambda item: snapshot(item, depth + 1, nested)
    if dataclasses.is_dataclass(value) and not isinstance(value, type):
        return {"kind": "dataclass", "type": type(value).__module__ + "." + type(value).__qualname__,
                "fields": [[field.name, convert(getattr(value, field.name))]
                           for field in dataclasses.fields(value)]}
    if type(value) is dict and all(type(key) is str for key in value):
        return {"kind": "mapping", "items": [[key, convert(item)] for key, item in value.items()]}
    if type(value) in (list, tuple):
        return {"kind": type(value).__name__, "items": [convert(item) for item in value]}
    raise TypeError("unsupported capture value type: " + type(value).__name__)


def main() -> None:
    if tuple(sys.version_info[:3]) != (3, 14, 5):
        raise RuntimeError("requires the exact bound CPython 3.14.5 runtime")
    if not (sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode):
        raise RuntimeError("requires -I -B -S")
    raw_bindings = Path(BINDINGS_PATH).read_bytes()
    if len(raw_bindings) > 131072 or hashlib.sha256(raw_bindings).hexdigest().upper() != BINDINGS_SHA256:
        raise ValueError("binding identity mismatch")
    binding = json.loads(raw_bindings.decode("utf-8"))
    if binding["state"] != "BOUND_DATA_ONLY_NOT_EXECUTION_AUTHORITY":
        raise RuntimeError("binding data remain unbound")
    if binding["captureScope"] != "PAYLOAD_SEMANTICS_ONLY":
        raise ValueError("unexpected reference capture scope")
    if binding["limits"] != {"seconds": 60, "jsonBytes": 2093056,
                              "maximumDepth": 64, "maximumProjectionNodes": 100000}:
        raise ValueError("unexpected proposed limits")
    if Path(sys.executable).resolve() != Path(binding["runtime"]["python"]["path"]).resolve():
        raise ValueError("wrong Python executable")
    verified(binding["runtime"]["python"])
    verified(binding["runtime"]["venvConfiguration"])
    home = Path(binding["runtime"]["stdlibHome"]).resolve()
    if any(not entry or not Path(entry).resolve().is_relative_to(home) for entry in sys.path):
        raise RuntimeError("unbound interpreter search path")
    if any(forbidden(name) or name == UI or name.startswith(UI + ".") or name == "yaml"
           or name.startswith("yaml.") for name in sys.modules):
        raise RuntimeError("process is not a cold reference process")
    originals, yamls = binding["originalModules"], binding["yamlModules"]
    if len(originals) != 9 or {item["name"] for item in originals} != ORIGINAL_UI_NAMES:
        raise ValueError("unexpected original module membership")
    if len(yamls) != 16 or {item["name"] for item in yamls} != YAML_NAMES:
        raise ValueError("unexpected PyYAML source membership")
    if set(binding["namespacePackages"]) != NAMESPACE_NAMES:
        raise ValueError("unexpected namespace membership")
    modules = {item["name"]: (verified(item["descriptor"]), item["descriptor"]["path"],
                              item["isPackage"]) for item in originals + yamls}
    color = binding["colorProjection"]
    full_color_source = verified(color["sourceDescriptor"])
    alias = full_color_source.splitlines(keepends=True)[24]
    if (color["name"] != COLOR_NAME or color["physicalLine"] != 25
            or alias.decode("utf-8") != color["exactUtf8Text"]
            or alias.rstrip(b"\r\n") != b"type Color = tuple[int, int, int, int]"
            or hashlib.sha256(alias).hexdigest().upper() != color["excerptSha256"]):
        raise ValueError("Color-only projection drift")
    modules[COLOR_NAME] = (alias, color["sourceDescriptor"]["path"] + "#Color-only-line-25", False)
    rows = binding["inputs"]
    if len(rows) != 10 or [row["id"] for row in rows] != [f"C{i:02}" for i in range(1, 11)]:
        raise ValueError("requires exactly ordered C01..C10")
    inputs = {row["id"]: verified(row["descriptor"]) for row in rows}
    copies = binding["documentCopies"]
    if len(copies) != 6 or len({item["descriptor"]["path"] for item in copies}) != 6:
        raise ValueError("requires six distinct documentation-copy relations")
    for item in copies:
        if item["expectedByteEqual"] is not True or verified(item["descriptor"]) != inputs[item["canonicalId"]]:
            raise ValueError("documentation copy differs from its canonical bytes")
    sys.meta_path.insert(0, ExactFinder(modules))
    yaml = importlib.import_module("yaml")
    schema = importlib.import_module(UI + ".preferences.schema")
    composition = importlib.import_module(UI + ".hud.composition")
    resources = importlib.import_module(UI + ".resources.source")
    if yaml.__version__ != "6.0.3" or yaml.__with_libyaml__ is not False:
        raise RuntimeError("unexpected PyYAML version/optional-extension state")
    check_import_boundary()
    results = []
    for index, row in enumerate(rows):
        tick()
        payload = yaml.safe_load(inputs[row["id"]].decode("utf-8"))
        if index < 4:
            if row["lane"] != "preferences" or row["preview"] is not False:
                raise ValueError("unexpected canonical preference context")
            result = schema.parse_preferences_payload({} if payload is None else payload)
            projection = "SAFELOAD_SCHEMA_PROJECTION_NOT_PUBLIC_TEXT_WRAPPER"
        else:
            if row["lane"] != "hud" or row["preview"] is not (index >= 6):
                raise ValueError("unexpected canonical HUD context")
            origin = row["origin"]
            expected_kind = "builtin" if index < 6 else "explicit_path"
            if origin["kind"] != expected_kind:
                raise ValueError("unexpected canonical HUD origin")
            source_path = Path(origin["path"]) if origin["path"] is not None else None
            source = resources.ResourceSource(kind=origin["kind"], name=origin["name"], path=source_path)
            result = composition.parse_hud_composition_payload(
                payload, source_path=source_path, source=source, preview=row["preview"])
            projection = "SAFELOAD_HUD_PAYLOAD_MEMORY_ENTRY_NOT_FILE_FACADE"
        results.append({"id": row["id"], "input": row["descriptor"], "originSidecar": row["origin"],
                        "projection": projection, "hasErrors": result.has_errors,
                        "result": snapshot(result)})
        check_import_boundary()
    capture = {"recordKind": "A2P0_CANONICAL_REFERENCE_DATA_CAPTURE_NOT_ACCEPTANCE",
               "captureScope": "PAYLOAD_SEMANTICS_ONLY",
               "bindingSha256": BINDINGS_SHA256, "canonicalCount": len(results),
               "copyRelationCount": len(copies), "copyRelations": copies,
               "expectedOptionalImportRefusals": DENIED_ATTEMPTS,
               "loadedSelectedModules": sorted(name for name in sys.modules if name in modules),
               "elapsedSeconds": time.monotonic() - STARTED, "results": results,
               "limits": "Memory projections only; no public IO/export/roundtrip/native/A2 PASS claim"}
    encoded = (json.dumps(capture, ensure_ascii=True, allow_nan=False, separators=(",", ":")) + "\n").encode()
    if len(encoded) > 2093056:
        raise ValueError("retained JSON cap exceeded")
    root = Path(binding["outputRoot"])
    permitted = Path(r"C:\SWDev\warhammer\Warhammer_40k_UI_unreal\.local\experiments\A2P0").resolve()
    if not root.is_absolute() or root.resolve() == permitted or not root.resolve().is_relative_to(permitted):
        raise ValueError("output is outside the new owned A2P0 root")
    if root.exists() or not root.parent.is_dir():
        raise ValueError("output must be create-new under an existing owned parent")
    tick()
    root.mkdir()
    with (root / "reference-capture.json").open("xb") as stream:
        stream.write(encoded)
    tick()
    print(json.dumps({"recordKind": "REFERENCE_CAPTURE_FILE_CLOSED_NOT_ACCEPTANCE",
                      "bytes": len(encoded), "sha256": hashlib.sha256(encoded).hexdigest().upper()}))


if __name__ == "__main__":
    main()
