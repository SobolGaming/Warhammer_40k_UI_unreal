"""Guarded canonical semantic roundtrip reference. Data never grant authority."""


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
    raise ImportError("A2 roundtrip exact import boundary refused: " + name)


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



HELPER_NAME = "_warhammer_migration_roundtrip_values"
HELPERS = None
GENERATED_TRANSPORT_ITEMS = 0
SCOPE = "CANONICAL_SEMANTIC_ROUNDTRIP_REFERENCE"
CAPTURE_KIND = "A2_CANONICAL_SEMANTIC_ROUNDTRIP_REFERENCE_CAPTURE_NOT_ACCEPTANCE"
PASS_STATUS = "PASS_ROUNDTRIP_REFERENCE_CLOSED_NOT_ACCEPTANCE"
FAIL_STATUS = "FAIL_ROUNDTRIP_REFERENCE_CLOSED_NOT_ACCEPTANCE"
LIMITS = {"seconds": 60, "jsonBytes": 2093056, "maximumDepth": 64,
          "maximumProjectionNodes": 100000, "maximumAggregateTransportItems": 200000,
          "maximumTransportDepth": 64, "maximumCaptureContainerDepth": 96, "maximumExportUtf8Bytes": 65536,
          "maximumAggregateExportUtf8Bytes": 655360}
RULE_IDS = {"PREF_FIELDS", "PREF_ZONES", "PREF_EXTENSIONS", "PREF_PLANNED",
            "PREF_BINDINGS", "HUD_FIELDS", "HUD_LAYOUT", "HUD_CHILDREN",
            "HUD_OPTIONAL", "HUD_ATTRIBUTES", "HUD_SAMPLE", "HUD_SCHEMA"}


def no_unbound(value):
    if isinstance(value, str) and "__UNBOUND" in value:
        raise ValueError("missing exact roundtrip binding")
    if type(value) is dict:
        for key, child in value.items():
            no_unbound(key)
            no_unbound(child)
    elif type(value) is list:
        for child in value:
            no_unbound(child)


def snapshot(value):
    """Helper tagged tuples become JSON arrays; distinct from P0 object nodes."""
    global GENERATED_TRANSPORT_ITEMS
    tree = HELPERS.typed_snapshot(value)
    pending = [(tree, 0)]
    while pending:
        tick()
        item, depth = pending.pop()
        GENERATED_TRANSPORT_ITEMS += 1
        if depth > 64 or GENERATED_TRANSPORT_ITEMS > 200000:
            raise ValueError("generated capture transport limit exceeded")
        if type(item) in (tuple, list):
            pending.extend((child, depth + 1) for child in item)
    return tree


def diagnostic_vector(result):
    return [[item.severity, item.code, item.field, item.message, item.value]
            for item in result.diagnostics]


def validate_vector(vector):
    if type(vector) is not list:
        raise ValueError("diagnostic vector must be a list")
    for item in vector:
        if (type(item) is not list or len(item) != 5
                or any(type(part) is not str for part in item[:4])
                or (item[4] is not None and type(item[4]) is not str)):
            raise ValueError("diagnostic vector shape/type")


def pointer(base, key):
    return base + "/" + str(key).replace("~", "~0").replace("/", "~1")


def presence_ledger(payload, model, lane):
    """Purpose-specific source-rule witnesses; raw graph separately retains all keys."""
    rows = []

    def witness(raw, key, effective, base, typed, rule, materialization):
        tick()
        if type(raw) is not dict:
            raise ValueError("presence source is not an object")
        present = key in raw
        value = raw.get(key)
        rows.append({"rawPointer": pointer(base, key), "typedFieldPath": typed,
                     "presence": "absent" if not present else ("explicit-null" if value is None else "explicit-value"),
                     "rawValueKind": type(value).__name__ if present else "ABSENT",
                     "rawGraphReference": pointer(base, key) if present else None,
                     "effectiveSnapshot": snapshot(effective), "ruleId": rule,
                     "exportMaterialization": materialization})

    if lane == "preferences":
        for name in ("schema_version", "profile_name"):
            witness(payload, name, getattr(model, name), "", "preferences." + name, "PREF_FIELDS", "original serializer field")
        for section in ("overlays", "selection"):
            raw = payload[section]
            typed = getattr(model, section)
            for field in dataclasses.fields(typed):
                witness(raw, field.name, getattr(typed, field.name), "/" + section,
                        "preferences." + section + "." + field.name, "PREF_FIELDS", "original serializer field")
        for index, binding in enumerate(model.hotkeys):
            raw = payload["hotkeys"][index]
            for field in dataclasses.fields(binding):
                witness(raw, field.name, getattr(binding, field.name), "/hotkeys/" + str(index),
                        f"preferences.hotkeys[{index}].{field.name}", "PREF_BINDINGS", "original key/modifier normalization; None overlay omitted")
        raw_hud = payload["hud"]
        for field in dataclasses.fields(model.hud):
            if field.name != "zones":
                witness(raw_hud, field.name, getattr(model.hud, field.name), "/hud",
                        "preferences.hud." + field.name, "PREF_FIELDS", "original effective field, including optional default")
        zones = raw_hud.get("zones", {})
        for zone in model.hud.zones:
            witness(zones, zone.zone_id, zone, "/hud/zones", "preferences.hud.zones." + zone.zone_id,
                    "PREF_ZONES", "seven original default zones in original default order")
            raw_zone = zones.get(zone.zone_id, {})
            for name in ("visible", "size_px", "collapsed"):
                witness(raw_zone, name, getattr(zone, name), pointer("/hud/zones", zone.zone_id),
                        "preferences.hud.zones." + zone.zone_id + "." + name, "PREF_ZONES", "original effective zone value")
        witness(payload["experimental"], "planned_settings", model.experimental.planned_settings,
                "/experimental", "preferences.experimental.planned_settings", "PREF_PLANNED", "preserve inactive identifiers/values/order")
        witness(payload, "extensions", model.experimental.extensions, "", "preferences.experimental.extensions",
                "PREF_EXTENSIONS", "export at top-level extensions, not experimental.extensions")
        return rows

    for name in ("schema_version", "profile_id", "layout_preset", "theme"):
        witness(payload, name, getattr(model, name), "", "profile." + name,
                "HUD_SCHEMA" if name == "schema_version" else "HUD_FIELDS", "accepted effective value; raw kind/presence retained")
    witness(payload, "sample_data", model.sample_data, "", "profile.sample_data", "HUD_SAMPLE",
            "omit key in production; retain complete map in preview")

    def widget(raw, node, base, typed):
        for raw_key, typed_key in (("type", "widget_type"), ("id", "widget_id")):
            witness(raw, raw_key, getattr(node, typed_key), base, typed + "." + typed_key, "HUD_FIELDS", "existing accepted widget key")
        witness(raw, "layout", node.layout, base, typed + ".layout", "HUD_LAYOUT", "all effective layout fields materialized")
        raw_layout = raw.get("layout")
        if raw_layout is None:
            raw_layout = {}
        for field in dataclasses.fields(node.layout):
            witness(raw_layout, field.name, getattr(node.layout, field.name), pointer(base, "layout"),
                    typed + ".layout." + field.name, "HUD_LAYOUT", "original defaults and int-spacing-to-float conversion")
        witness(raw, "children", node.children, base, typed + ".children", "HUD_CHILDREN", "ordered tuple becomes payload list; empty materialized")
        for name in ("icon_id", "data_ref"):
            witness(raw, name, getattr(node, name), base, typed + "." + name, "HUD_OPTIONAL", "omit only effective None")
        for name, value in node.attributes.items():
            witness(raw, name, value, base, typed + ".attributes." + name, "HUD_ATTRIBUTES", "raw JSON-safe accepted value and insertion order preserved")
        raw_children = raw.get("children") or []
        if type(raw_children) is not list or len(raw_children) != len(node.children):
            raise ValueError("raw/model child membership differs")
        for index, child in enumerate(node.children):
            widget(raw_children[index], child, pointer(pointer(base, "children"), index), typed + f".children[{index}]")

    for index, region in enumerate(model.regions):
        region_base = pointer("/regions", region.region_id)
        widget(payload["regions"][region.region_id]["widget"], region.widget,
               pointer(region_base, "widget"), f"profile.regions[{index}].widget")
    return rows


def parse_same_context(row, payload, schema, composition, resources):
    tick()
    if row["lane"] == "preferences":
        result = schema.parse_preferences_payload({} if payload is None else payload)
    else:
        origin = row["origin"]
        path = Path(origin["path"]) if origin["path"] is not None else None
        source = resources.ResourceSource(kind=origin["kind"], name=origin["name"], path=path)
        result = composition.parse_hud_composition_payload(payload, source_path=path, source=source, preview=row["preview"])
    tick()
    return result


def export_payload(model, row, composition):
    tick()
    if row["lane"] == "preferences":
        result = HELPERS.preference_to_payload(model)
    else:
        result = HELPERS.hud_to_payload(model, preview=row["preview"],
                                       allowed_attributes=composition.component_allowed_attributes,
                                       widget_type_from_string=composition.widget_type_from_string)
    tick()
    return result


def write_capture(capture, root):
    tick()
    pending = [(capture, 0)]
    depth_exceeded = False
    while pending:
        tick()
        value, depth = pending.pop()
        if type(value) in (dict, list, tuple):
            if depth > 96:
                depth_exceeded = True
                break
            children = value.values() if type(value) is dict else value
            pending.extend((item, depth + 1) for item in children)
    encoded = b"" if depth_exceeded else (json.dumps(capture, ensure_ascii=True, allow_nan=False, separators=(",", ":")) + "\n").encode("utf-8")
    if depth_exceeded or len(encoded) > LIMITS["jsonBytes"]:
        summaries = [{key: value for key, value in case.items() if key in ("id", "status", "checks", "stageStatus", "failure")}
                     for case in capture["results"]]
        capture = {key: value for key, value in capture.items() if key != "results"}
        capture.update(operationStatus=FAIL_STATUS, captureCapExceeded=not depth_exceeded, captureDepthExceeded=depth_exceeded,
                       attemptedCaptureBytes=None if depth_exceeded else len(encoded), caseFailureSummaries=summaries,
                       results=[], omittedForCaptureCap="Obtained case bodies omitted for finite cap/depth; observed counts/summaries retained, no PASS")
        encoded = (json.dumps(capture, ensure_ascii=True, allow_nan=False, separators=(",", ":")) + "\n").encode("utf-8")
        if len(encoded) > LIMITS["jsonBytes"]:
            raise ValueError("bounded failure capture also exceeds cap")
    tick()
    root.mkdir()
    with (root / "canonical-roundtrip-reference.original.json").open("xb") as stream:
        if stream.write(encoded) != len(encoded):
            raise OSError("partial capture write")
    tick()
    print(json.dumps({"recordKind": "CANONICAL_ROUNDTRIP_REFERENCE_FILE_CLOSED_NOT_ACCEPTANCE",
                      "bytes": len(encoded), "sha256": hashlib.sha256(encoded).hexdigest().upper()}))
    return 0 if capture["operationStatus"] == PASS_STATUS else 1


def main():
    global HELPERS
    if tuple(sys.version_info[:3]) != (3, 14, 5):
        raise RuntimeError("requires exact bound CPython3.14.5")
    if not (sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode):
        raise RuntimeError("requires -I -B -S")
    if Path(BINDINGS_PATH).stat().st_size > 131072:
        raise ValueError("binding bytes exceed cap")
    raw_bindings = Path(BINDINGS_PATH).read_bytes()
    if len(raw_bindings) > 131072 or hashlib.sha256(raw_bindings).hexdigest().upper() != BINDINGS_SHA256:
        raise ValueError("binding identity mismatch")
    binding = json.loads(raw_bindings.decode("utf-8"))
    no_unbound(binding)
    required = {"recordKind", "state", "captureScope", "historicalArcadeBaseline", "sourceHead", "sourceBase", "runId", "nonce",
                "outputRoot", "limits", "runtime", "originalModules", "namespacePackages", "colorProjection", "yamlVersion", "yamlModules",
                "inputs", "documentCopies", "helperSource", "helperModuleName", "diagnosticExpectations", "diagnosticReferenceIdentityOnly", "presenceRuleCatalog"}
    if set(binding) != required or binding["recordKind"] != "A2_CANONICAL_SEMANTIC_ROUNDTRIP_REFERENCE_DATA":
        raise ValueError("wrong roundtrip data keys/kind")
    if binding["state"] != "BOUND_DATA_ONLY_NOT_EXECUTION_AUTHORITY" or binding["captureScope"] != SCOPE or binding["limits"] != LIMITS:
        raise ValueError("unbound state/scope/limits")
    if binding["helperModuleName"] != HELPER_NAME or set(binding["presenceRuleCatalog"]) != RULE_IDS:
        raise ValueError("wrong helper or source-rule catalog")
    if len(binding["sourceHead"]) != 40 or len(binding["sourceBase"]) != 40 or len(binding["nonce"]) != 32:
        raise ValueError("missing exact subject")
    root = Path(binding["outputRoot"])
    family = Path(r"C:\SWDev\warhammer\Warhammer_40k_UI_unreal\.local\experiments\A2CanonicalRoundtrip").resolve()
    if (not root.is_absolute() or root.resolve() != (family / binding["runId"] / "capture")
            or root.exists() or not root.parent.is_dir()):
        raise ValueError("output must be absent exact capture child in owned run")
    if Path(sys.executable).resolve() != Path(binding["runtime"]["python"]["path"]).resolve():
        raise ValueError("wrong Python executable")
    verified(binding["runtime"]["python"])
    verified(binding["runtime"]["venvConfiguration"])
    home = Path(binding["runtime"]["stdlibHome"]).resolve()
    if any(not entry or not Path(entry).resolve().is_relative_to(home) for entry in sys.path):
        raise RuntimeError("unbound interpreter search path")
    if any(forbidden(name) or name == UI or name.startswith(UI + ".") or name == HELPER_NAME
           or name == "yaml" or name.startswith("yaml.") for name in sys.modules):
        raise RuntimeError("process is not cold")
    originals, yamls = binding["originalModules"], binding["yamlModules"]
    if len(originals) != 9 or {item["name"] for item in originals} != ORIGINAL_UI_NAMES:
        raise ValueError("wrong original module membership")
    if len(yamls) != 16 or {item["name"] for item in yamls} != YAML_NAMES or set(binding["namespacePackages"]) != NAMESPACE_NAMES:
        raise ValueError("wrong YAML/namespace membership")
    modules = {item["name"]: (verified(item["descriptor"]), item["descriptor"]["path"], item["isPackage"])
               for item in originals + yamls}
    color = binding["colorProjection"]
    alias = verified(color["sourceDescriptor"]).splitlines(keepends=True)[24]
    if (color["name"] != COLOR_NAME or color["physicalLine"] != 25 or alias.decode("utf-8") != color["exactUtf8Text"]
            or alias.rstrip(b"\r\n") != b"type Color = tuple[int, int, int, int]"
            or hashlib.sha256(alias).hexdigest().upper() != color["excerptSha256"]):
        raise ValueError("Color-only source drift")
    modules[COLOR_NAME] = (alias, color["sourceDescriptor"]["path"] + "#Color-only-line-25", False)
    modules[HELPER_NAME] = (verified(binding["helperSource"]), binding["helperSource"]["path"], False)
    rows = binding["inputs"]
    ids = [f"C{i:02}" for i in range(1, 11)]
    expectations = binding["diagnosticExpectations"]
    if len(rows) != 10 or [row["id"] for row in rows] != ids or len(expectations) != 10 or [row["id"] for row in expectations] != ids:
        raise ValueError("requires exactly ordered ten contexts/expectations")
    for index, row in enumerate(rows):
        if row["lane"] != ("preferences" if index < 4 else "hud") or row["preview"] is not (index >= 6):
            raise ValueError("canonical lane/preview drift")
        if row["origin"]["kind"] != ("builtin" if index < 6 else "explicit_path"):
            raise ValueError("canonical origin drift")
        expected = expectations[index]
        if set(expected) != {"id", "beforeDiagnostics", "afterDiagnostics", "beforeHasErrors", "afterHasErrors", "sourceRuleIds"}:
            raise ValueError("expectation shape")
        validate_vector(expected["beforeDiagnostics"])
        validate_vector(expected["afterDiagnostics"])
        if type(expected["beforeHasErrors"]) is not bool or type(expected["afterHasErrors"]) is not bool:
            raise ValueError("expected hasErrors kinds")
    inputs = {row["id"]: verified(row["descriptor"]) for row in rows}
    copies = binding["documentCopies"]
    if len(copies) != 6 or len({item["descriptor"]["path"] for item in copies}) != 6 or {item["canonicalId"] for item in copies} != set(ids[:6]):
        raise ValueError("requires six distinct canonical/document-copy relations")
    copy_comparisons = []
    for item in copies:
        equal = verified(item["descriptor"]) == inputs[item["canonicalId"]]
        copy_comparisons.append({"canonicalId": item["canonicalId"], "allBytesEqual": equal})
        if item["expectedByteEqual"] is not True or not equal:
            raise ValueError("documentation copy differs")
    sys.meta_path.insert(0, ExactFinder(modules))
    yaml = importlib.import_module("yaml")
    schema = importlib.import_module(UI + ".preferences.schema")
    composition = importlib.import_module(UI + ".hud.composition")
    resources = importlib.import_module(UI + ".resources.source")
    HELPERS = importlib.import_module(HELPER_NAME)
    if yaml.__version__ != "6.0.3" or yaml.__with_libyaml__ is not False:
        raise RuntimeError("wrong YAML version/extension state")
    check_import_boundary()
    capture = {"schemaVersion": 1, "recordKind": CAPTURE_KIND, "captureScope": SCOPE,
               "sourceHead": binding["sourceHead"], "sourceBase": binding["sourceBase"], "runId": binding["runId"], "nonce": binding["nonce"],
               "bindingSha256": BINDINGS_SHA256, "helperSource": binding["helperSource"],
               "canonicalCount": 10, "plannedCanonicalCount": 10, "actualCaseCount": 0, "passedCaseCount": 0,
               "copyRelationCount": len(copies), "copyRelations": copies, "copyComparisons": copy_comparisons,
               "diagnosticReferenceIdentityOnly": binding["diagnosticReferenceIdentityOnly"],
               "presenceRuleCatalog": binding["presenceRuleCatalog"], "yamlVersion": yaml.__version__,
               "operationStatus": FAIL_STATUS, "results": [], "limits": LIMITS,
               "transport": "TAGGED_TUPLE_TRANSPORT_V1_JSON_ARRAYS_NOT_P0_OBJECTS"}
    aggregate_export_bytes = 0
    for row, expected in zip(rows, expectations):
        case = {"id": row["id"], "lane": row["lane"], "preview": row["preview"], "input": row["descriptor"],
                "logicalOrigin": row["origin"], "actualExportLocation": None, "status": "FAIL",
                "checks": {"fullResultEqual": None, "payloadFixedPoint": None,
                           "expectedBeforeDiagnosticsMatched": None, "expectedAfterDiagnosticsMatched": None},
                "stageStatus": {name: "NOT_RUN" for name in ("rawLoad", "beforeParse", "beforeCapture", "presence", "export1", "yamlEmit", "afterParse", "afterCapture", "export2", "compare")}}
        stage = "rawLoad"
        try:
            tick()
            import base64
            case["inputRawBase64"] = base64.b64encode(inputs[row["id"]]).decode("ascii")
            payload = yaml.safe_load(inputs[row["id"]].decode("utf-8"))
            case["rawParsedGraph"] = snapshot(payload)
            case["stageStatus"][stage] = "PASS"
            stage = "beforeParse"
            before = parse_same_context(row, payload, schema, composition, resources)
            case["stageStatus"][stage] = "PASS"
            stage = "beforeCapture"
            case["beforeHasErrors"] = before.has_errors
            case["beforeDiagnostics"] = diagnostic_vector(before)
            case["expectedBeforeDiagnostics"] = expected["beforeDiagnostics"]
            case["expectedAfterDiagnostics"] = expected["afterDiagnostics"]
            case["beforeResult"] = snapshot(before)
            case["checks"]["expectedBeforeDiagnosticsMatched"] = False
            HELPERS.require_same_typed_value(case["beforeDiagnostics"], expected["beforeDiagnostics"])
            if before.has_errors is not expected["beforeHasErrors"]:
                raise ValueError("before hasErrors differs")
            case["checks"]["expectedBeforeDiagnosticsMatched"] = True
            model = before.preferences if row["lane"] == "preferences" else before.profile
            if model is None or before.has_errors:
                raise ValueError("no valid model to export")
            case["stageStatus"][stage] = "PASS"
            stage = "presence"
            case["presenceAndDefaultLedger"] = presence_ledger(payload, model, row["lane"])
            case["stageStatus"][stage] = "PASS"
            stage = "export1"
            first = export_payload(model, row, composition)
            case["exportPayload1"] = snapshot(first)
            case["stageStatus"][stage] = "PASS"
            stage = "yamlEmit"
            tick()
            text = yaml.safe_dump(first, sort_keys=False, allow_unicode=False)
            tick()
            emitted = text.encode("utf-8")
            aggregate_export_bytes += len(emitted)
            if len(emitted) > 65536 or aggregate_export_bytes > 655360:
                raise ValueError("export text bound")
            case.update(yamlText=text, yamlUtf8Bytes=len(emitted), yamlSha256=hashlib.sha256(emitted).hexdigest().upper())
            case["stageStatus"][stage] = "PASS"
            stage = "afterParse"
            tick()
            reparsed = yaml.safe_load(text)
            tick()
            case["reparsedRawGraph"] = snapshot(reparsed)
            after = parse_same_context(row, reparsed, schema, composition, resources)
            case["stageStatus"][stage] = "PASS"
            stage = "afterCapture"
            case["afterHasErrors"] = after.has_errors
            case["afterDiagnostics"] = diagnostic_vector(after)
            case["afterResult"] = snapshot(after)
            case["checks"]["expectedAfterDiagnosticsMatched"] = False
            HELPERS.require_same_typed_value(case["afterDiagnostics"], expected["afterDiagnostics"])
            if after.has_errors is not expected["afterHasErrors"]:
                raise ValueError("after hasErrors differs")
            case["checks"]["expectedAfterDiagnosticsMatched"] = True
            after_model = after.preferences if row["lane"] == "preferences" else after.profile
            if after_model is None or after.has_errors:
                raise ValueError("reimport did not yield valid model")
            case["stageStatus"][stage] = "PASS"
            stage = "export2"
            second = export_payload(after_model, row, composition)
            case["exportPayload2"] = snapshot(second)
            case["stageStatus"][stage] = "PASS"
            stage = "compare"
            case["checks"]["fullResultEqual"] = False
            HELPERS.require_same_typed_value(before, after)
            case["checks"]["fullResultEqual"] = True
            case["checks"]["payloadFixedPoint"] = False
            HELPERS.require_payload_fixed_point(first, second)
            case["checks"]["payloadFixedPoint"] = True
            check_import_boundary()
            case["stageStatus"][stage] = "PASS"
            case["status"] = "PASS"
        except Exception as error:
            case["stageStatus"][stage] = "FAIL"
            case["failure"] = {"stage": stage, "type": type(error).__name__, "message": str(error)[:512]}
        capture["results"].append(case)
        capture["actualCaseCount"] = len(capture["results"])
        capture["passedCaseCount"] = sum(item["status"] == "PASS" for item in capture["results"])
        if case["status"] != "PASS":
            break
    if capture["actualCaseCount"] == 10 and capture["passedCaseCount"] == 10:
        capture["operationStatus"] = PASS_STATUS
    capture.update(generatedTransportItems=GENERATED_TRANSPORT_ITEMS, aggregateExportUtf8Bytes=aggregate_export_bytes,
                   expectedOptionalImportRefusals=DENIED_ATTEMPTS,
                   loadedSelectedModules=sorted(name for name in sys.modules if name in modules),
                   elapsedSeconds=time.monotonic() - STARTED,
                   scopeLimits="Canonical YAML semantic reference roundtrip only; no public IO/JSON/default/native/render/full-A2 acceptance")
    return write_capture(capture, root)


if __name__ == "__main__":
    raise SystemExit(main())
