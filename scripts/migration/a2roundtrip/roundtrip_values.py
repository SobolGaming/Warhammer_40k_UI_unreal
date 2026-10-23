"""Proposed pure reference helpers; no collector, loader, filesystem or authority."""


from dataclasses import fields, is_dataclass
import math
from pathlib import PurePath


_P = "warhammer40k_arcade_ui.preferences.schema."
_H = "warhammer40k_arcade_ui.hud.composition."
_T = "warhammer40k_arcade_ui.hud.toolkit."
_R = "warhammer40k_arcade_ui.resources.source."
SIGNATURES = {
    _P + "OverlayPreferences": ("default_on_model_selection", "default_on_unit_selection", "default_on_movement_draft", "enabled_by_default"),
    _P + "HotkeyBinding": ("command_id", "key", "modifiers", "overlay_id"),
    _P + "SelectionBehaviorPreferences": ("default_mouse_button", "cycle_overlapping_bases"),
    _P + "HudZonePreference": ("zone_id", "visible", "size_px", "collapsed"),
    _P + "HudPreferences": ("layout_preset", "composition_profile", "zones", "show_phase", "show_active_player", "show_event_log", "show_config_diagnostics", "show_assignment_hud", "assignment_hud_mode", "show_assignment_warning_markers", "assignment_target_highlight_color", "action_summary_default", "action_summary_max_labels", "movement_budget_ring_mode", "show_chain_breadcrumbs", "text_scale", "high_contrast"),
    _P + "ExperimentalPreferenceFlags": ("planned_settings", "extensions"),
    _P + "UiPreferences": ("schema_version", "profile_name", "overlays", "hotkeys", "selection", "hud", "experimental"),
    _P + "PreferencesValidationResult": ("preferences", "diagnostics"),
    "warhammer40k_arcade_ui.preferences.diagnostics.PreferenceDiagnostic": ("severity", "code", "message", "field", "value"),
    _H + "HudCompositionRegion": ("region_id", "widget"),
    _H + "HudCompositionProfile": ("schema_version", "profile_id", "layout_preset", "theme", "regions", "sample_data", "source_path", "source"),
    _H + "HudCompositionValidationResult": ("profile", "diagnostics"),
    _T + "HudLayoutSpec": ("kind", "orientation", "columns", "gap_px", "padding_px", "alignment"),
    _T + "HudComponentNode": ("widget_type", "widget_id", "attributes", "layout", "children", "icon_id", "data_ref"),
    _R + "ResourceSource": ("kind", "name", "path"),
    # Conditional diagnostic type, not a preset claim that HUD emits none.
    _H + "HudCompositionDiagnostic": ("severity", "code", "field", "message", "value"),
}
RESERVED = frozenset(("type", "id", "layout", "children", "icon_id", "data_ref"))


class PreservationError(ValueError):
    """Unsupported or lossy candidate representation; never silently continue."""


def _symbol(value):
    return type(value).__module__ + "." + type(value).__qualname__


def _require_dataclass(value, symbol):
    if not is_dataclass(value) or isinstance(value, type) or _symbol(value) != symbol:
        raise PreservationError("unexpected model type")
    if tuple(field.name for field in fields(value)) != SIGNATURES[symbol]:
        raise PreservationError("dataclass signature changed")


def _text(value):
    if type(value) is not str or not value:
        raise PreservationError("expected nonempty text")
    return value


class _Budget:
    def __init__(self):
        self.nodes = 0
        self.active = set()

    def enter(self, value, depth):
        self.nodes += 1
        if depth > 64 or self.nodes > 100000:
            raise PreservationError("projection limit")
        if id(value) in self.active:
            raise PreservationError("cycle")


def typed_snapshot(value):
    """Ordered, type-sensitive comparison representation; not a profile export."""
    budget = _Budget()

    def visit(item, depth):
        budget.enter(item, depth)
        kind = type(item)
        if item is None:
            return ("none",)
        if kind is bool:
            return ("bool", item)
        if kind is int:
            return ("int", item)
        if kind is float:
            if not math.isfinite(item):
                raise PreservationError("nonfinite float")
            return ("float_hex", item.hex())
        if kind is str:
            if len(item.encode("utf-8")) > 65536:
                raise PreservationError("scalar limit")
            return ("str", item)
        if isinstance(item, PurePath):
            return ("path", _symbol(item), visit(str(item), depth + 1))
        budget.active.add(id(item))
        try:
            if kind in (tuple, list):
                return ("tuple" if kind is tuple else "list", tuple(visit(child, depth + 1) for child in item))
            if kind is dict:
                if any(type(key) is not str for key in item):
                    raise PreservationError("non-string mapping key")
                return ("mapping", tuple((visit(key, depth + 1), visit(child, depth + 1)) for key, child in item.items()))
            symbol = _symbol(item)
            if symbol not in SIGNATURES:
                raise PreservationError("unsupported value type")
            _require_dataclass(item, symbol)
            return ("dataclass", symbol, tuple((field.name, visit(getattr(item, field.name), depth + 1)) for field in fields(item)))
        finally:
            budget.active.remove(id(item))

    return visit(value, 0)


def _json_clone(value):
    """Clone accepted payload kinds/order without coercing tuples or objects."""
    budget = _Budget()

    def clone(item, depth):
        budget.enter(item, depth)
        kind = type(item)
        if item is None or kind in (bool, int):
            return item
        if kind is float:
            if not math.isfinite(item):
                raise PreservationError("nonfinite payload float")
            return item
        if kind is str:
            if len(item.encode("utf-8")) > 65536:
                raise PreservationError("payload scalar limit")
            return item
        if kind not in (dict, list):
            raise PreservationError("unsupported payload kind")
        budget.active.add(id(item))
        try:
            if kind is list:
                return [clone(child, depth + 1) for child in item]
            if any(type(key) is not str or not key for key in item):
                raise PreservationError("invalid payload key")
            return {clone(key, depth + 1): clone(child, depth + 1) for key, child in item.items()}
        finally:
            budget.active.remove(id(item))

    return clone(value, 0)


def preference_to_payload(preferences):
    """Use the original frozen UiPreferences.to_payload; do not replace it."""
    _require_dataclass(preferences, _P + "UiPreferences")
    typed_snapshot(preferences)
    payload = preferences.to_payload()
    if type(payload) is not dict:
        raise PreservationError("preference serializer shape")
    return _json_clone(payload)


def hud_to_payload(profile, *, preview, allowed_attributes, widget_type_from_string):
    """New migration inverse, using the original frozen toolkit callbacks."""
    _require_dataclass(profile, _H + "HudCompositionProfile")
    if type(preview) is not bool or type(profile.regions) is not tuple:
        raise PreservationError("HUD context or region shape")
    typed_snapshot(profile)
    if type(profile.sample_data) is not dict or (not preview and profile.sample_data):
        raise PreservationError("production sample-data loss")

    def widget(node):
        _require_dataclass(node, _T + "HudComponentNode")
        _require_dataclass(node.layout, _T + "HudLayoutSpec")
        name = _text(node.widget_type)
        if widget_type_from_string(name) != name:
            raise PreservationError("unknown widget type")
        if type(node.attributes) is not dict or type(node.children) is not tuple:
            raise PreservationError("widget collection shape")
        allowed = allowed_attributes(name)
        if type(allowed) is not frozenset or any(type(key) is not str for key in allowed):
            raise PreservationError("attribute registry shape")
        if any(type(key) is not str or key in RESERVED or key not in allowed for key in node.attributes):
            raise PreservationError("reserved or unsupported attribute")
        layout = node.layout
        if type(layout.columns) is not int or type(layout.gap_px) is not float or type(layout.padding_px) is not float:
            raise PreservationError("layout scalar kinds")
        payload = {"type": name, "id": _text(node.widget_id)}
        payload.update(_json_clone(node.attributes))
        payload["layout"] = {"kind": _text(layout.kind), "orientation": _text(layout.orientation), "columns": layout.columns, "gap_px": layout.gap_px, "padding_px": layout.padding_px, "alignment": _text(layout.alignment)}
        payload["children"] = [widget(child) for child in node.children]
        for key in ("icon_id", "data_ref"):
            value = getattr(node, key)
            if value is not None:
                payload[key] = _text(value)
        return payload

    payload = {"schema_version": _text(profile.schema_version), "profile_id": _text(profile.profile_id), "layout_preset": _text(profile.layout_preset), "theme": _text(profile.theme)}
    if preview:
        payload["sample_data"] = _json_clone(profile.sample_data)
    regions = {}
    for region in profile.regions:
        _require_dataclass(region, _H + "HudCompositionRegion")
        region_id = _text(region.region_id)
        if region_id in regions:
            raise PreservationError("duplicate region loss")
        regions[region_id] = {"widget": widget(region.widget)}
    payload["regions"] = regions
    return _json_clone(payload)


def require_same_typed_value(before, after):
    """Includes diagnostics/provenance when passed complete result objects."""
    if typed_snapshot(before) != typed_snapshot(after):
        raise PreservationError("typed roundtrip difference")


def require_payload_fixed_point(first, second):
    require_same_typed_value(_json_clone(first), _json_clone(second))
