"""Focused checks of E01 evidence code, never fake engine integration.

Run directly with the reviewed Python 3.14.5 interpreter and ``-I -B``. Canonical
contract examples below are parser fixtures; they do not count as live workflows.
The complete-receipt regression uses the installed local JSON Schema validator.
"""
from __future__ import annotations

import copy
from contextlib import contextmanager
import importlib.util
import io
import json
from pathlib import Path
import socket
import tempfile
import threading
import time
from types import SimpleNamespace
import unittest
from unittest.mock import MagicMock, call, patch


REPO = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "e01_boundary", REPO / "scripts/migration/e01_boundary.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("E01 evidence module is unavailable")
boundary = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(boundary)
FIXTURE = REPO / "tests/migration/fixtures" / boundary.CORE_COMMIT


def canonical(member: str) -> object:
    return boundary.strict_json((FIXTURE / "contracts" / member).read_bytes())


def http10_connection(wire: bytes):
    """Use real stdlib HTTPResponse with a tracked, in-memory socket file."""
    class SocketFile(io.BytesIO):
        def close(self):
            transport.closed = True
            super().close()

    class TrackedSocket:
        def __init__(self):
            self.closed = False
            self.timeouts = []

        def settimeout(self, value):
            if self.closed:
                raise OSError("timeout update on closed HTTP/1.0 transport")
            self.timeouts.append(value)

        def makefile(self, mode):
            if mode != "rb":
                raise AssertionError("HTTP response requested unexpected file mode")
            return SocketFile(wire)

    transport = TrackedSocket()
    connection = MagicMock()
    connection.sock = transport
    response = boundary.http_client.HTTPResponse(transport)
    response.begin()
    connection.getresponse.return_value = response
    connection.close.side_effect = lambda: setattr(transport, "closed", True)
    return connection, transport


@contextmanager
def loopback_response(parts: tuple[bytes, ...], *, interval: float = 0):
    """Own one test-only listener; send fragments until stopped or disconnected."""
    stop = threading.Event()
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(2)
    port = listener.getsockname()[1]
    failures = []

    def serve():
        try:
            with listener.accept()[0] as connection:
                connection.settimeout(2)
                request = b""
                while b"\r\n\r\n" not in request:
                    fragment = connection.recv(4096)
                    if not fragment:
                        return
                    request += fragment
                    if len(request) > 65536:
                        raise AssertionError("Unit HTTP request unexpectedly large")
                headers, _, body = request.partition(b"\r\n\r\n")
                lengths = [int(line.split(b":", 1)[1]) for line in headers.split(b"\r\n")[1:] if line.lower().startswith(b"content-length:")]
                length = lengths[0] if lengths else 0
                if len(lengths) > 1 or not 0 <= length <= 65536:
                    raise AssertionError("Unit HTTP request length is invalid")
                # Drain the submitted POST before closing a Windows socket;
                # unread request bytes may reset an otherwise complete reply.
                while len(body) < length:
                    fragment = connection.recv(min(4096, length - len(body)))
                    if not fragment:
                        raise AssertionError("Unit HTTP request body truncated")
                    body += fragment
                for index, part in enumerate(parts):
                    if index and stop.wait(interval):
                        return
                    connection.sendall(part)
        except OSError as exc:
            # Closing after a bounded client timeout is the expected test path.
            if not stop.is_set() and not isinstance(exc, (BrokenPipeError, ConnectionResetError, ConnectionAbortedError)):
                failures.append(exc)
        except BaseException as exc:
            failures.append(exc)

    worker = threading.Thread(target=serve, daemon=True)
    worker.start()
    try:
        yield f"http://127.0.0.1:{port}"
    finally:
        stop.set()
        listener.close()
        worker.join(timeout=3)
        if worker.is_alive():
            raise AssertionError("Owned unit HTTP responder failed to stop")
        if failures:
            raise failures[0]


class CanonicalEnvelopeTests(unittest.TestCase):
    def test_canonical_reserve_recipe_prioritizes_only_currently_offered_choices(self):
        complete = "complete_reserve_declarations"
        deep = "declare_deep_strike:army-alpha:deep-strike-unit"
        strategic = "declare_strategic_reserves:army-alpha:strategic-reserve-unit"
        request = {"decision_type": "select_reserve_declaration",
                   "options": [{"option_id": item} for item in (complete, deep, strategic)]}
        original = copy.deepcopy(request)
        self.assertEqual(boundary.canonical_reserve_option(request), strategic)
        self.assertEqual(request, original)
        request["options"].pop()
        self.assertEqual(boundary.canonical_reserve_option(request), deep)
        request["options"].pop()
        self.assertEqual(boundary.canonical_reserve_option(request), complete)
        request["options"] = [{"option_id": "unreviewed-choice"}]
        with self.assertRaisesRegex(boundary.Blocked, "currently offered"):
            boundary.canonical_reserve_option(request)

    def test_all_98_canonical_envelopes_round_trip_with_types_and_order(self):
        corpus = canonical("examples/decisions/interaction-conformance.json")
        manifest = boundary.strict_json((FIXTURE / "manifest.json").read_bytes())
        ids = []
        for case in corpus["cases"]:
            with self.subTest(case_id=case["case_id"]):
                restored = boundary.strict_json(boundary.json_bytes(case))
                self.assertEqual(restored, case)
                self.assertEqual(list(restored["request"]), list(case["request"]))
                self.assertIs(type(case["request"]["request_id"]), str)
                self.assertIs(type(case["request"]["is_parameterized"]), bool)
                self.assertEqual(
                    [row["option_id"] for row in restored["request"]["options"]],
                    [row["option_id"] for row in case["request"]["options"]],
                )
                ids.append(case["case_id"])
        self.assertEqual(len(ids), 98)
        self.assertEqual(len(set(ids)), 98)
        self.assertEqual(sorted(ids), sorted(manifest["CanonicalInteractionCaseIds"]))
        self.assertEqual(sum(item.startswith("finite:") for item in ids), 73)
        self.assertEqual(sum(item.startswith("nested:") for item in ids), 1)
        self.assertEqual(sum(item.startswith("parameterized:") for item in ids), 24)

    def test_json_null_boolean_number_string_and_array_order_are_distinct(self):
        value = {"id": "0009", "nullable": None, "flag": False, "number": 9,
                 "ordered": ["z", "a", "z"], "pose": {"z": 1.25}}
        restored = boundary.strict_json(boundary.json_bytes(value))
        self.assertEqual(restored, value)
        self.assertIs(type(restored["id"]), str)
        self.assertIs(type(restored["number"]), int)
        self.assertIs(type(restored["flag"]), bool)
        self.assertIsNone(restored["nullable"])

    def test_malformed_duplicate_and_nonfinite_json_fail_visibly(self):
        for raw in (b"{", b'{"x":1,"x":2}', b'{"x":NaN}', b'{"x":Infinity}'):
            with self.subTest(raw=raw), self.assertRaises((boundary.BoundaryError, ValueError)):
                boundary.strict_json(raw)

    def test_deep_json_decoder_and_encoder_fail_with_typed_diagnostics(self):
        raw = b"[" * 2000 + b"0" + b"]" * 2000
        with self.assertRaisesRegex(boundary.BoundaryError, "value nesting"):
            boundary.strict_json(raw)
        value = 0
        for _ in range(2000):
            value = [value]
        with self.assertRaisesRegex(boundary.BoundaryError, "nesting"):
            boundary.json_bytes(value)
        for leaf in (b"0", b'"[]\\\"{}\\n\\t\\u0001"', b"true", b"null", b"[]", b"{}"):
            with self.subTest(leaf=leaf):
                bounded = b"[" * boundary.MAX_JSON_DEPTH + leaf + b"]" * boundary.MAX_JSON_DEPTH
                self.assertIsInstance(boundary.strict_json(bounded), list)
                deeper = b"[" + bounded + b"]"
                with self.assertRaisesRegex(boundary.BoundaryError, "value nesting"):
                    boundary.strict_json(deeper)
        # Root depth is zero, so 129 empty nested containers are valid,
        # while their nonempty child would exceed native Value's depth 128.
        for opening, closing in ((b"[", b"]"), (b'{"k":', b"}")):
            bounded = opening * boundary.MAX_JSON_DEPTH + b"{}" + closing * boundary.MAX_JSON_DEPTH
            boundary.strict_json(bounded)
            with self.assertRaisesRegex(boundary.BoundaryError, "value nesting"):
                boundary.strict_json(opening * (boundary.MAX_JSON_DEPTH + 1) + b"0" + closing * (boundary.MAX_JSON_DEPTH + 1))
        value = {"quoted": "[" * 2000 + "\\\"\n\t\x01" + "]" * 2000, "nested": [{"safe": True}]}
        self.assertEqual(boundary.strict_json(boundary.json_bytes(value)), value)

    def test_parser_encoder_and_schema_recursion_failures_are_typed(self):
        for target, invoke, diagnostic in (
            ("loads", lambda: boundary.strict_json(b"{}"), "decoder"),
            ("dumps", lambda: boundary.json_bytes({}), "encoder"),
        ):
            with self.subTest(target=target), patch.object(boundary.json, target, side_effect=RecursionError("private parser detail")):
                with self.assertRaisesRegex(boundary.BoundaryError, diagnostic + " nesting") as raised:
                    invoke()
                self.assertIsInstance(raised.exception.__cause__, RecursionError)
                self.assertNotIn("private parser detail", str(raised.exception))
        schemas = boundary.Schemas.__new__(boundary.Schemas)
        schemas.schemas, schemas.registry = {"unit.json": {}}, None
        schemas.validator_type = MagicMock()
        schemas.validator_type.return_value.iter_errors.side_effect = RecursionError("private validator detail")
        with self.assertRaisesRegex(boundary.BoundaryError, "schema-validator nesting") as raised:
            schemas.validate("unit.json", {})
        self.assertIsInstance(raised.exception.__cause__, RecursionError)
        self.assertNotIn("private validator detail", str(raised.exception))

    def test_finite_command_retains_opaque_ids_and_complete_envelope(self):
        request = {"request_id": "00000042"}
        command = boundary.envelope("session-0007", "command-0008", 12, "finite_option",
                                    request, option="option-0009")
        self.assertEqual(command["request_id"], "00000042")
        self.assertEqual(command["result_id"], "command-0008-result")
        self.assertEqual(command["submission"], {"submission_kind": "finite_option",
                                                  "option_id": "option-0009"})
        self.assertEqual(boundary.strict_json(boundary.json_bytes(command)), command)

    def test_generated_command_matches_exact_frozen_schema_and_canonical_envelope(self):
        schema = canonical("schemas/session-command-envelope.schema.json")
        frozen = canonical("examples/sessions/session-command-envelope.json")
        generated = boundary.envelope(frozen["session_id"], frozen["command_id"],
                                      frozen["expected_session_revision"],
                                      frozen["submission"]["submission_kind"])
        self.assertEqual(generated["schema_version"], schema["properties"]["schema_version"]["const"])
        self.assertEqual(generated, frozen)
        self.assertEqual(set(generated), set(schema["required"]))

    def test_pair_rejects_outgoing_schema_failure_before_any_transport_call(self):
        # Pure client ordering check; no Core or transport result is simulated.
        local, http = MagicMock(), MagicMock()
        schemas = MagicMock()
        schemas.validate.side_effect = boundary.BoundaryError("Outgoing schema mismatch")
        pair = boundary.Pair(local, http, SimpleNamespace(schemas=schemas))
        pair.session = "session-unit"
        command = boundary.envelope(pair.session, "command-unit", 0, "start_session")
        command["schema_version"] = "incorrect-test-discriminator"
        with self.assertRaisesRegex(boundary.BoundaryError, "Outgoing schema mismatch"):
            pair.submit(command, "admin")
        schemas.validate.assert_called_once_with("session-command-envelope.schema.json", command)
        local.request.assert_not_called()
        http.request.assert_not_called()
        self.assertEqual(pair.submissions, 0)

    def test_pure_candidate_uses_complete_ordered_public_inventory_and_three_poses(self):
        view = canonical("examples/projections/post_deployment_view.json")
        proposal = {"request_id": "pure-candidate-request", "proposal_kind": "normal_move",
                    "unit_instance_id": "army-alpha:intercessor-unit-1"}
        candidate = boundary.movement_payload(proposal, view)
        paths = candidate["witness"]["model_paths"]
        expected = view["battlefield_state"]["placed_armies"][0]["unit_placements"][0]["model_placements"]
        expected = sorted(expected, key=lambda row: (-row["pose"]["position"]["x"], row["model_instance_id"]))
        self.assertEqual([row["model_id"] for row in paths],
                         [row["model_instance_id"] for row in expected])
        for row, placement in zip(paths, expected, strict=True):
            self.assertEqual(len(row["poses"]), 3)
            self.assertEqual(row["poses"][0], placement["pose"])
            self.assertEqual(row["poses"][2]["position"]["x"], placement["pose"]["position"]["x"] + 1)
            self.assertEqual(row["poses"][2]["position"]["z"], placement["pose"]["position"]["z"])
            self.assertEqual(row["poses"][2]["facing"], placement["pose"]["facing"])

    def test_fixed_translation_recipe_leads_in_direction_without_mutating_inventory(self):
        # Source-backed fixture recipe only; no geometry acceptance is inferred.
        # Canonical setup has rear/front rows at x4/x5.8, with ID tie-breaks.
        paths = []
        for model_id, x in (("rear", 4.0), ("front-z", 5.8), ("front-a", 5.8)):
            paths.append({"model_id": model_id, "poses": [
                {"position": {"x": x + step, "y": 51.0, "z": 2.25},
                 "facing": {"degrees": 37.0}} for step in (0.0, 0.5, 1.0)]})
        original = copy.deepcopy(paths)
        forward = boundary.leading_first_translation_candidate(paths, dx=1.0)
        invalid_distance = boundary.leading_first_translation_candidate(paths, dx=1000.0)
        reverse = boundary.leading_first_translation_candidate(paths, dx=-1.0)
        self.assertEqual([row["model_id"] for row in forward], ["front-a", "front-z", "rear"])
        self.assertEqual([row["model_id"] for row in invalid_distance], ["front-a", "front-z", "rear"])
        self.assertEqual([row["model_id"] for row in reverse], ["rear", "front-a", "front-z"])
        self.assertEqual(paths, original)
        self.assertEqual({row["model_id"]: row["poses"] for row in forward},
                         {row["model_id"]: row["poses"] for row in original})

    def test_observed_one_inch_model_endpoints_pass_with_actual_moved_count(self):
        view = canonical("examples/projections/post_deployment_view.json")
        candidate = boundary.movement_payload({"request_id": "unit-pose-request", "proposal_kind": "normal_move",
            "unit_instance_id": "army-alpha:intercessor-unit-1"}, view)
        before = view["battlefield_state"]
        after = copy.deepcopy(before)
        finals = {row["model_id"]: row["poses"][-1] for row in candidate["witness"]["model_paths"]}
        for army in after["placed_armies"]:
            for unit in army["unit_placements"]:
                for model in unit["model_placements"]:
                    if model["model_instance_id"] in finals:
                        model["pose"] = copy.deepcopy(finals[model["model_instance_id"]])
        observed = boundary.verify_requested_model_poses(before, after, candidate["witness"])
        self.assertEqual(observed["movedModelCount"], len(finals))
        self.assertEqual(observed["requestedModelCount"], len(finals))
        self.assertTrue(observed["positionChange"])
        self.assertTrue(all(row["xyzChanged"] for row in observed["poseEvidence"]))
        self.assertTrue(all(row["afterPose"] == row["requestedFinalPose"] for row in observed["poseEvidence"]))

    def test_metadata_change_without_requested_model_motion_cannot_pass_pose_proof(self):
        view = canonical("examples/projections/post_deployment_view.json")
        candidate = boundary.movement_payload({"request_id": "unit-pose-request", "proposal_kind": "normal_move",
            "unit_instance_id": "army-alpha:intercessor-unit-1"}, view)
        before = view["battlefield_state"]
        metadata_only = copy.deepcopy(before)
        metadata_only["removed_model_ids"] = ["unit-unrelated-metadata-change"]
        metadata_only["terrain_features"] = []
        self.assertNotEqual(before, metadata_only)
        with self.assertRaisesRegex(boundary.BoundaryError, "final pose differs"):
            boundary.verify_requested_model_poses(before, metadata_only, candidate["witness"])
        stationary = copy.deepcopy(candidate["witness"])
        for path in stationary["model_paths"]:
            path["poses"] = [copy.deepcopy(path["poses"][0]), copy.deepcopy(path["poses"][0])]
        with self.assertRaisesRegex(boundary.BoundaryError, "No authoritative requested-model XYZ"):
            boundary.verify_requested_model_poses(before, metadata_only, stationary)


class OutcomeTests(unittest.TestCase):
    def setUp(self):
        self.accepted = canonical("examples/sessions/session-command-outcome.json")

    def test_real_canonical_accepted_outcome_classifies(self):
        self.assertEqual(boundary.classify(200, self.accepted), "accepted")

    def test_two_422_shapes_have_distinct_semantics(self):
        # Pure classifier negatives/variants, explicitly not a live HTTP result.
        recorded = copy.deepcopy(self.accepted)
        recorded.update(accepted=False, outcome_code="proposal_invalid")
        uncommitted = {"schema_version": "error-envelope-v1", "error": {
            "code": "proposal_invalid", "message": "Submitted proposal was invalid."}}
        self.assertEqual(boundary.classify(422, recorded), "recorded_invalid")
        self.assertEqual(boundary.classify(422, uncommitted), "uncommitted_invalid")
        self.assertEqual(uncommitted["error"]["message"], "Submitted proposal was invalid.")
        self.assertNotIn("violations", uncommitted["error"])

    def test_422_error_envelope_variants_match_native_uncommitted_classification(self):
        # These are the same two selected-Core error codes covered by native
        # ReadOutcome's synthetic controls, not fabricated live captures.
        for code in ("proposal_invalid", "rule_path_unsupported"):
            body = {"schema_version": "error-envelope-v1", "error": {"code": code, "message": "Synthetic public error."}}
            with self.subTest(code=code):
                self.assertEqual(boundary.classify(422, body), "uncommitted_invalid")
                self.assertEqual(boundary.classify(500, body), "error")
                self.assertNotIn("accepted", body)
                self.assertNotIn("committed", body)

    def test_outcome_requires_coherent_session_checkpoint_and_event_range(self):
        mutations = {
            "revision": lambda body: body["checkpoint"].update(session_revision=body["session"]["session_revision"] + 1),
            "hash": lambda body: body["checkpoint"].update(projection_state_hash="0" * 64),
            "cursor": lambda body: body["checkpoint"].update(event_cursor="different-checkpoint-cursor"),
            "range_end": lambda body: body["event_range"].update(to_cursor="different-event-range-end"),
            "role": lambda body: body["checkpoint"].update(visibility_role="player"),
            "viewer": lambda body: body["checkpoint"].update(viewer_player_id="player-b"),
            "extra_checkpoint": lambda body: body["checkpoint"].update(extra=1),
            "extra_range": lambda body: body["event_range"].update(extra=1),
            "extra_outcome": lambda body: body.update(extra=1),
        }
        for label, mutate in mutations.items():
            body = copy.deepcopy(self.accepted)
            mutate(body)
            with self.subTest(field=label), self.assertRaises(boundary.BoundaryError):
                boundary.classify(200, body)

    def test_uncommitted_command_outcome_accepts_only_422_supported_negative_codes(self):
        # Public outcome schema permits facade pre-validator results with both
        # flags false; these remain distinct from recorded invalid attempts.
        for code in ("proposal_invalid", "rule_path_unsupported"):
            outcome = copy.deepcopy(self.accepted)
            outcome.update(accepted=False, committed=False, outcome_code=code)
            with self.subTest(code=code):
                self.assertEqual(boundary.classify(422, outcome), "uncommitted_invalid")
                with self.assertRaises(boundary.BoundaryError):
                    boundary.classify(200, outcome)

    def test_uncommitted_outcome_capture_routes_through_command_outcome_schema(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report, schemas = boundary.Report("capture", root), MagicMock()
            captures = boundary.Captures(SimpleNamespace(output_root=root), report, schemas)
            outcome = copy.deepcopy(self.accepted)
            outcome.update(accepted=False, committed=False, outcome_code="proposal_invalid")
            reply = boundary.Reply(422, boundary.json_bytes(outcome), 0.01, 0)
            path = captures.add("unit_uncommitted_outcome", "admin", "synthetic_negative", reply,
                                "Pure schema-routing unit; not live HTTP evidence", "uncommitted_invalid")
            schemas.validate.assert_called_once_with("session-command-outcome.schema.json", outcome)
            self.assertEqual(Path(path).read_bytes(), reply.raw)
            self.assertEqual(captures.entries, [])

    def test_fidelity_observation_retains_actual_response_message_and_bytes(self):
        wire = boundary.json_bytes({"schema_version": "error-envelope-v1", "error": {
            "code": "proposal_invalid", "message": "Actual supplied wire message for parser test."}})
        reply = boundary.Reply(422, wire, 0.01, 17)
        observed = boundary.fidelity_observation(reply)
        self.assertEqual(observed["httpStatus"], reply.status)
        self.assertEqual(observed["code"], reply.body["error"]["code"])
        self.assertEqual(observed["message"], reply.body["error"]["message"])
        self.assertEqual(observed["responseSHA256"], boundary.sha256(wire))
        with self.assertRaises(boundary.BoundaryError):
            boundary.fidelity_observation(boundary.Reply(200, wire, 0.01, 17))

    def test_accepted_before_unsupported_later_status_stays_accepted(self):
        outcome = copy.deepcopy(self.accepted)
        outcome["session"]["lifecycle_status"]["status_kind"] = "unsupported"
        self.assertEqual(boundary.classify(200, outcome), "accepted")

    def test_accepted_uncommitted_and_wrong_flag_types_fail(self):
        for accepted, committed in ((True, False), (True, None), (1, True),
                                    ("true", True), (False, False)):
            outcome = copy.deepcopy(self.accepted)
            outcome.update(accepted=accepted, committed=committed)
            with self.subTest(accepted=accepted, committed=committed):
                with self.assertRaises(boundary.BoundaryError):
                    boundary.classify(200, outcome)

    def test_missing_or_wrong_typed_required_outcome_fields_fail(self):
        for field in ("schema_version", "accepted", "committed", "command_id", "operation",
                      "outcome_code", "session", "checkpoint", "event_range"):
            for replacement in ("missing", None, []):
                outcome = copy.deepcopy(self.accepted)
                if replacement == "missing":
                    del outcome[field]
                else:
                    outcome[field] = replacement
                with self.subTest(field=field, replacement=replacement):
                    with self.assertRaises(boundary.BoundaryError):
                        boundary.classify(200, outcome)

    def test_revision_integer_boundary_and_boolean_rejection(self):
        for revision in (True, -1, 1.5, "12", 2**53):
            outcome = copy.deepcopy(self.accepted)
            outcome["session"]["session_revision"] = revision
            with self.subTest(revision=revision), self.assertRaises(boundary.BoundaryError):
                boundary.classify(200, outcome)
        outcome = copy.deepcopy(self.accepted)
        outcome["session"]["session_revision"] = 2**53 - 1
        outcome["checkpoint"]["session_revision"] = 2**53 - 1
        self.assertEqual(boundary.classify(200, outcome), "accepted")

    def test_error_missing_wrong_type_or_extra_detail_fails(self):
        valid = {"schema_version": "error-envelope-v1", "error": {
            "code": "access_denied", "message": "Access denied."}}
        self.assertEqual(boundary.classify(403, valid), "error")
        for mutate in (lambda x: x.pop("schema_version"),
                       lambda x: x["error"].pop("message"),
                       lambda x: x["error"].update(message=None),
                       lambda x: x["error"].update(hidden_count=7),
                       lambda x: x.update(accepted=False)):
            value = copy.deepcopy(valid)
            mutate(value)
            with self.assertRaises(boundary.BoundaryError):
                boundary.classify(403, value)


class EvidenceSafetyTests(unittest.TestCase):
    @staticmethod
    def owned_host(root):
        host = boundary.OwnedHost.__new__(boundary.OwnedHost)
        host.root, host.shutdown = root, root / "shutdown"
        host.report = boundary.Report("capture", root)
        host.record = {"owner": "unit-owned-host", "pid": 12345, "maximumSeconds": 1800}
        host.lock, host.timer, host.process = threading.Lock(), MagicMock(), MagicMock()
        host.log = (root / "host.log").open("xb")
        state = {"running": True}
        host.process.poll.side_effect = lambda: None if state["running"] else 0

        def exited(timeout):
            state["running"] = False
            return 0

        host.process.wait.side_effect = exited
        return host, state

    def test_marker_write_failure_stops_owned_handle_and_finalizes_process_log(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host, state = self.owned_host(root)
            log = host.log
            host.timer.cancel.side_effect = lambda: self.assertFalse(state["running"])
            with patch.object(Path, "touch", side_effect=PermissionError("private marker write detail")):
                with self.assertRaisesRegex(boundary.BoundaryError, "write-owned-shutdown-marker"):
                    host.stop()
            self.assertFalse(state["running"])
            host.process.terminate.assert_called_once()
            host.process.kill.assert_not_called()
            host.timer.cancel.assert_called_once()
            self.assertTrue(log.closed)
            self.assertIsNone(host.log)
            self.assertEqual(host.record["exitCode"], 0)
            self.assertEqual(host.record["cleanupStatus"], "STOPPED_WITH_ERRORS")
            self.assertEqual(host.record["cleanupErrors"][0]["exceptionType"], "PermissionError")
            self.assertEqual(host.report.details["processes"], [host.record])
            self.assertNotIn(b"private marker write detail", boundary.json_bytes(host.report.payload()))
            host.stop()
            self.assertEqual(len(host.report.details["processes"]), 1)

    def test_marker_wait_error_still_uses_handle_cleanup_and_keeps_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host, state = self.owned_host(root)
            calls = []

            def wait(timeout):
                calls.append(timeout)
                if len(calls) == 1:
                    raise OSError("private wait detail")
                state["running"] = False
                return 0

            host.process.wait.side_effect = wait
            with self.assertRaisesRegex(boundary.BoundaryError, "wait-owned-marker-exit"):
                host.stop()
            host.process.terminate.assert_called_once()
            self.assertFalse(state["running"])
            self.assertTrue(host.record["logClosed"])
            self.assertEqual(host.record["exitCode"], 0)
            self.assertEqual(calls, [10, 10])
            self.assertEqual(host.report.details["processes"], [host.record])

    def test_unconfirmed_owned_exit_retains_original_watchdog_and_complete_ledger(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host, _ = self.owned_host(root)
            host.process.wait.side_effect = boundary.subprocess.TimeoutExpired("unit-owned-host", 10)
            with self.assertRaises(boundary.BoundaryError):
                host.stop()
            host.process.terminate.assert_called_once()
            host.process.kill.assert_called_once()
            host.timer.cancel.assert_not_called()
            self.assertEqual(host.record["watchdog"], "retained-for-unconfirmed-exit")
            self.assertEqual(host.record["cleanupStatus"], "EXIT_UNCONFIRMED")
            self.assertIsNone(host.record["exitCode"])
            self.assertNotIn("exitUTC", host.record)
            self.assertTrue(host.record["logClosed"])
            self.assertEqual(host.report.details["processes"], [host.record])
            self.assertTrue(all(item == call(timeout=10) for item in host.process.wait.call_args_list))

    def test_owned_log_close_failure_cannot_omit_process_record_or_handle_cleanup(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host, state = self.owned_host(root)
            host.log.close()
            log = MagicMock()
            log.close.side_effect = [OSError("private log close detail"), None]
            host.log = log
            with self.assertRaisesRegex(boundary.BoundaryError, "close-owned-log"):
                host.stop()
            self.assertFalse(state["running"])
            self.assertEqual(log.close.call_count, 2)
            self.assertTrue(host.record["logClosed"])
            self.assertEqual(host.record["exitCode"], 0)
            self.assertEqual(host.report.details["processes"], [host.record])

    def test_capture_finalizer_keeps_artifact_and_case_records_after_stop_failure(self):
        report, host, captures = boundary.Report("capture", REPO), MagicMock(), MagicMock()
        report.case("FINITE-01", "PASS", "Earlier actual observation", "Retained")
        host.stop.side_effect = boundary.BoundaryError("Unit owned cleanup failure")
        with self.assertRaisesRegex(boundary.BoundaryError, "Unit owned cleanup failure"):
            boundary.finish_capture(host, captures, report)
        captures.finish.assert_called_once()
        self.assertEqual(report.cases[0]["status"], "PASS")
        self.assertEqual({case["id"] for case in report.cases}, set(boundary.CASE_IDS))
        self.assertTrue(all(case["status"] == "BLOCKED" for case in report.cases[1:]))

    def test_capture_unknown_survives_owned_cleanup_failure_in_exported_phase(self):
        for failure_point in ("creation", "first_start"):
            with self.subTest(failure_point=failure_point), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args = SimpleNamespace(phase="capture", attach_worker=False, fixture_root=FIXTURE, output_root=root, report_file=root / "report.json")
                host, captures, pair = MagicMock(), MagicMock(), MagicMock()
                host.stop.side_effect = boundary.BoundaryError("private cleanup diagnostic")
                pair.army_by_player = {}
                created = SimpleNamespace(status=201, body={"engine_build_id": boundary.BUILD_ID, "server_contract_version": boundary.CONTRACT_VERSION, "session_id": "opaque-unit"})
                pair.request.return_value = (SimpleNamespace(body={"event_cursor": "local-cursor"}), SimpleNamespace(body={"event_cursor": "http-cursor"}))
                unknown = boundary.CompletionUnknown("private uncertain transport diagnostic")
                unknown.__cause__ = TimeoutError("private transport detail")
                create = MagicMock(return_value=(created, created))
                if failure_point == "creation":
                    create.side_effect = unknown
                else:
                    pair.submit.side_effect = unknown
                with patch.object(boundary, "arguments", return_value=args), \
                     patch.object(boundary, "verify_runtime"), patch.object(boundary, "Schemas"), \
                     patch.object(boundary, "scope_case"), patch.object(boundary, "credentials", return_value={}), \
                     patch.object(boundary, "Captures", return_value=captures), patch.object(boundary, "OwnedHost", return_value=host), \
                     patch.object(boundary, "Pair", return_value=pair), patch.object(boundary, "create_session_attempt", create), \
                     patch.object(boundary, "run_case_groups") as groups, patch("builtins.print"):
                    self.assertEqual(boundary.main([]), 2)
                exported = boundary.strict_json(args.report_file.read_bytes())
                phase = next(row for row in exported["cases"] if row["id"] == "PHASE")
                self.assertEqual(phase["status"], "FAIL")
                self.assertEqual(phase["actual"]["completionOutcome"], "UNKNOWN")
                self.assertEqual(phase["actual"]["causeType"], "TimeoutError")
                self.assertEqual(exported["captureFailure"]["completionOutcome"], "UNKNOWN")
                self.assertEqual(exported["captureCleanupFailures"], [{"stage": "stop-owned-host", "exceptionType": "BoundaryError", "causeType": None}])
                self.assertTrue(all(row["actual"]["completionOutcome"] == "UNKNOWN" for row in exported["cases"] if row["id"] in boundary.CASE_IDS))
                self.assertNotIn("private", args.report_file.read_text())
                host.stop.assert_called_once()
                captures.finish.assert_called_once()
                create.assert_called_once()
                self.assertEqual(pair.submit.call_count, int(failure_point == "first_start"))
                groups.assert_not_called()

    def test_windows_exclusive_prelaunch_probe_rejects_busy_port_without_spawning(self):
        # Socket and child process are mocked; no network or Core host runs.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host = boundary.OwnedHost.__new__(boundary.OwnedHost)
            host.root, host.port, host.record = root, 12345, {}
            probe = MagicMock()
            probe.__enter__.return_value = probe
            probe.bind.side_effect = OSError("Synthetic occupied exclusive address")
            with patch.object(boundary.socket, "socket", return_value=probe), \
                 patch.object(boundary.socket, "SO_EXCLUSIVEADDRUSE", 123, create=True), \
                 patch.object(boundary.sys, "platform", "win32"), \
                 patch.object(boundary.subprocess, "Popen") as spawn:
                with self.assertRaises(boundary.PortUnavailable):
                    host.start()
            probe.setsockopt.assert_called_once_with(boundary.socket.SOL_SOCKET, 123, 1)
            probe.bind.assert_called_once_with(("127.0.0.1", 12345))
            self.assertLess(probe.method_calls.index(call.setsockopt(boundary.socket.SOL_SOCKET, 123, 1)),
                            probe.method_calls.index(call.bind(("127.0.0.1", 12345))))
            probe.__exit__.assert_called_once()
            spawn.assert_not_called()
            self.assertFalse((root / "host.log").exists())

    def test_cross_scope_denial_trace_keeps_only_hashes_of_hidden_command_fields(self):
        # Deliberate injected actor inputs may be sent under denied scopes, but
        # they must never be exported as that submitted scope's visible data.
        local, http = MagicMock(), MagicMock()
        pair = boundary.Pair(local, http, SimpleNamespace())
        command = boundary.envelope("known-session", "actor-hidden-command", 2, "finite_option",
                                    {"request_id": "actor-hidden-request"}, option="actor-hidden-option")
        for role in ("playerB", "delayed", "replay", "missing", "invalid"):
            status = 401 if role in ("missing", "invalid") else 403
            denied = boundary.Reply(status, boundary.json_bytes({"schema_version": "error-envelope-v1",
                "error": {"code": "access_denied", "message": "Access denied."}}), 0.01, 0)
            local.request.return_value = http.request.return_value = denied
            pair.request("POST", "/sessions/known-session/commands", role, command)
        serialized = boundary.json_bytes(pair.trace).decode()
        for hidden in ("actor-hidden-command", "actor-hidden-request", "actor-hidden-option", "commandEnvelope"):
            self.assertNotIn(hidden, serialized)
        self.assertEqual(len(pair.trace), 5)
        for row in pair.trace:
            self.assertEqual(set(row), {"method", "path", "role", "status", "requestSHA256", "responseSHA256"})
            self.assertEqual(row["requestSHA256"], boundary.sha256(boundary.json_bytes(command)))

    def test_exception_after_case_pass_keeps_actual_result_and_fails_group(self):
        for error in (boundary.BoundaryError("Synthetic cleanup failure."),
                      boundary.Blocked("Synthetic post-result blocker.")):
            report = boundary.Report("capture", REPO)

            def pass_then_fail():
                report.case("UNIT-LIFETIME", "PASS", "Pure client control check", {"observed": "retained"})
                raise error

            boundary.run_case_groups(report, ((("UNIT-LIFETIME",), pass_then_fail),))
            self.assertEqual(report.cases[0]["status"], "PASS")
            self.assertEqual(report.cases[0]["actual"], {"observed": "retained"})
            self.assertEqual(len(report.cases), 2)
            self.assertIn(report.cases[1]["status"], ("FAIL", "BLOCKED"))
            self.assertEqual(report.cases[1]["actual"]["message"], str(error))
            self.assertTrue(report.cases[1]["actual"]["priorCaseResultsRetained"])
            self.assertIn(report.payload()["status"], ("FAIL", "BLOCKED"))

    def test_rejected_setup_saves_scoped_candidate_and_abandons_later_groups(self):
        # Pure client-control regression: a mocked adapter reply is never counted
        # as a real Core/HTTP result or written into the proposed-wire index.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report = boundary.Report("capture", root)
            request = {"request_id": "unit-request", "actor_id": "player-a",
                       "decision_type": "select_secondary_missions", "options": [
                           {"option_id": "fixed:assassination:bring_it_down"}]}
            view = {"viewer_player_id": "player-a", "pending_decision": request,
                    "pending_proposal": None}
            command = boundary.envelope("unit-session", "unit-command", 2, "finite_option",
                                        request, option="fixed:assassination:bring_it_down")
            reply = boundary.Reply(422, boundary.json_bytes({"schema_version": "error-envelope-v1",
                "error": {"code": "proposal_invalid", "message": "Synthetic unit rejection."}}), 0.01, 0)
            captures = SimpleNamespace(report=report, add=MagicMock(return_value=str(root / "unit-only-wire.json")))
            client = MagicMock()
            client.captures, client.submissions = captures, 24
            client.pending.return_value = (request, view)
            client.intent.return_value = command
            client.submit.return_value = (reply, reply)
            boundary.run_case_groups(report, (
                (("UNIT-SETUP",), lambda: boundary.setup_to_move(client)),
                (("UNIT-NEXT",), lambda: report.case("UNIT-NEXT", "PASS", "Pure client continuation", "Invoked")),
            ))
            self.assertEqual([(case["id"], case["status"]) for case in report.cases],
                             [("UNIT-SETUP", "BLOCKED"), ("UNIT-NEXT", "BLOCKED")])
            self.assertEqual(report.cases[1]["actual"]["sessionDisposition"], "ABANDONED")
            path = root / "private-rejections/setup_rejected_24/playerA.json"
            diagnostic = boundary.strict_json(path.read_bytes())
            self.assertEqual(diagnostic["role"], "playerA")
            self.assertEqual(diagnostic["commandEnvelope"], command)
            self.assertEqual(diagnostic["requestBeforeSubmission"], request)
            self.assertEqual(diagnostic["authorizedViewBeforeSubmission"], view)
            self.assertEqual(diagnostic["publicResponse"]["httpStatus"], 422)
            self.assertEqual(diagnostic["publicResponse"]["body"], reply.body)
            self.assertEqual(diagnostic["publicResponse"]["rawSHA256"], boundary.sha256(reply.raw))
            artifact = next(row for row in report.artifacts if row["path"] == str(path))
            self.assertEqual(artifact["sha256"], boundary.sha256(path.read_bytes()))
            with self.assertRaisesRegex(boundary.BoundaryError, "authenticated role"):
                boundary.record_setup_rejection(client, request, view, command, reply, "playerB")
            self.assertEqual(len(report.artifacts), 2)

    def test_authorized_candidate_is_retained_before_timed_out_submission(self):
        # Pure client-control timeout; no engine or HTTP result is fabricated.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report = boundary.Report("capture", root)
            request = {"request_id": "unit-timeout-request", "actor_id": "player-a",
                       "decision_type": "select_secondary_missions", "options": [
                           {"option_id": "fixed:assassination:bring_it_down"}]}
            view = {"viewer_player_id": "player-a", "pending_decision": request,
                    "pending_proposal": None}
            command = boundary.envelope("unit-session", "unit-timeout-command", 2, "finite_option",
                                        request, option="fixed:assassination:bring_it_down")
            captures = SimpleNamespace(report=report, add=MagicMock())
            client = MagicMock()
            client.captures, client.submissions = captures, 7
            client.pending.return_value = (request, view)
            client.intent.return_value = command
            client.submit.side_effect = TimeoutError("Synthetic completion unknown")
            boundary.run_case_groups(report, ((("UNIT-TIMEOUT",), lambda: boundary.setup_to_move(client)),))
            snapshot = boundary.strict_json((root / "private-attempts/command_8/playerA.json").read_bytes())
            self.assertEqual(snapshot["commandEnvelope"], command)
            self.assertEqual(snapshot["authorizedViewBeforeSubmission"], view)
            self.assertNotIn("publicResponse", snapshot)
            self.assertIn("no completion outcome asserted", snapshot["observation"])
            self.assertEqual(report.cases[0]["status"], "FAIL")
            client.submit.assert_called_once_with(command, "playerA")
            captures.add.assert_not_called()
            with self.assertRaisesRegex(boundary.BoundaryError, "authenticated role"):
                boundary.record_authorized_attempt(client, request, view, command, "playerB")
            self.assertFalse((root / "private-attempts/command_8/playerB.json").exists())

    def test_committed_but_unreceived_finite_command_retains_scope_and_stops_submissions(self):
        # Mocked commitment is a failure-control unit, never live Core evidence.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report = boundary.Report("capture", root)
            request = {"request_id": "finite-unknown-request", "actor_id": "player-a",
                       "options": [{"option_id": "finite-offered-option"}]}
            view = {"viewer_player_id": "player-a", "pending_decision": request,
                    "pending_proposal": None}
            captures = SimpleNamespace(report=report, add=MagicMock(), schemas=MagicMock())
            local, http = MagicMock(), MagicMock()
            pair = boundary.Pair(local, http, captures)
            pair.session = "unit-unknown-session"
            pair.pending = MagicMock(return_value=(request, view))
            pair.metadata = MagicMock(return_value={"session_revision": 3})
            committed = []

            def response(method, path, role, command, query):
                kind = command["submission"]["submission_kind"]
                if kind == "advance_session" or command["command_id"].endswith("-stale"):
                    code = "advance_not_required" if kind == "advance_session" else "session_revision_conflict"
                    return boundary.Reply(409, boundary.json_bytes({"schema_version": "error-envelope-v1",
                        "error": {"code": code, "message": "Synthetic expected conflict."}}), 0, 0)
                committed.append(copy.deepcopy(command))
                return boundary.Reply(200, b"{}", 0, 0)

            def received(method, path, role, command, query):
                if command["command_id"] == "e01-finite-finite-unknown-request":
                    raise TimeoutError("private transport detail: Authorization unit-only-secret")
                return response(method, path, role, command, query)

            local.request.side_effect, http.request.side_effect = response, received
            later = MagicMock(side_effect=lambda: pair.submit({"new": "command"}, "playerA"))
            report.case("UNIT-EARLIER", "PASS", "Previous actual observation", "Retained")
            boundary.run_case_groups(report, (
                (("FINITE-01", "RETRY-01", "STALE-01"), lambda: boundary.finite_and_retry(pair, report)),
                (("UNIT-LATER-MOVE",), later),
            ))
            self.assertEqual(len(committed), 1)
            self.assertEqual(pair.submissions, 3)
            later.assert_not_called()
            self.assertEqual(local.request.call_count, 3)
            self.assertEqual(http.request.call_count, 3)
            snapshot = boundary.strict_json((root / "private-attempts/command_3/playerA.json").read_bytes())
            self.assertEqual(snapshot["commandEnvelope"], committed[0])
            self.assertEqual(snapshot["requestBeforeSubmission"], request)
            self.assertEqual(snapshot["authorizedViewBeforeSubmission"], view)
            self.assertNotIn("publicResponse", snapshot)
            ledger = boundary.strict_json((root / "privileged-submission-attempts/command_3.json").read_bytes())
            self.assertEqual(ledger["commandEnvelope"], committed[0])
            self.assertEqual(ledger["submittedRole"], "playerA")
            self.assertEqual(ledger["sessionId"], pair.session)
            self.assertEqual(ledger["envelopeBytesSHA256"], boundary.sha256(boundary.json_bytes(committed[0])))
            self.assertNotIn("authorizedViewBeforeSubmission", ledger)
            self.assertEqual(report.cases[0]["status"], "PASS")
            self.assertEqual(report.cases[-1]["status"], "BLOCKED")
            self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
            self.assertEqual(report.details["sessionAbandonment"]["causeType"], "TimeoutError")
            rendered = boundary.json_bytes(report.payload())
            self.assertIn(b"Command completion UNKNOWN", rendered)
            self.assertNotIn(b"unit-only-secret", rendered)
            self.assertNotIn(b"private transport detail", rendered)
            self.assertFalse((root / "private-attempts/command_3/playerB.json").exists())
            self.assertTrue(pair.submission_unknown)
            before_artifacts = copy.deepcopy(report.artifacts)
            for retry_command in (committed[0], {**committed[0], "command_id": "must-not-retry-new-id"}):
                with self.assertRaisesRegex(boundary.BoundaryError, "Session abandoned after UNKNOWN"):
                    pair.submit(retry_command, "playerA")
            self.assertEqual(report.artifacts, before_artifacts)
            self.assertEqual(pair.submissions, 3)
            self.assertEqual(local.request.call_count, 3)
            self.assertEqual(http.request.call_count, 3)
            self.assertFalse((root / "privileged-submission-attempts/command_4.json").exists())

    def test_pre_submission_schema_failure_is_not_completion_unknown(self):
        schemas = MagicMock()
        schemas.validate.side_effect = boundary.BoundaryError("Synthetic local schema failure")
        local, http = MagicMock(), MagicMock()
        pair = boundary.Pair(local, http, SimpleNamespace(schemas=schemas))
        with self.assertRaisesRegex(boundary.BoundaryError, "Synthetic local schema failure") as observed:
            pair.submit({}, "playerA")
        self.assertNotIsInstance(observed.exception, boundary.CompletionUnknown)
        self.assertEqual(pair.submissions, 0)
        local.request.assert_not_called()
        http.request.assert_not_called()

    def test_all_submission_roles_keep_exact_private_control_envelope_before_unknown(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for role in ("admin", "missing", "invalid", "playerB", "coach", "delayed", "replay"):
                # Each unknown result abandons its independent unit session.
                report = boundary.Report("capture", root / role)
                local, http = MagicMock(), MagicMock()
                pair = boundary.Pair(local, http, SimpleNamespace(schemas=MagicMock(), report=report))
                pair.session = "unit-ledger-session-" + role
                local.request.side_effect = TimeoutError("private transport detail")
                request = {"request_id": "actor-private-request"}
                command = boundary.envelope(pair.session, "unit-ledger-" + role, 0,
                    "start_session" if role == "admin" else "finite_option",
                    None if role == "admin" else request,
                    option=None if role == "admin" else "actor-private-option")
                with self.assertRaises(boundary.CompletionUnknown) as observed:
                    pair.submit(command, role)
                self.assertIsInstance(observed.exception.__cause__, TimeoutError)
                ledger = boundary.strict_json((report.output / "privileged-submission-attempts/command_1.json").read_bytes())
                self.assertEqual(ledger["commandEnvelope"], command)
                self.assertEqual(ledger["submittedRole"], role)
                self.assertEqual(ledger["sessionId"], pair.session)
                self.assertNotIn("authorizedViewBeforeSubmission", ledger)
                self.assertIn("never publish", ledger["recordScope"])
                self.assertFalse((report.output / "proposed-wire").exists())
                self.assertFalse((report.output / "private-attempts").exists())
                self.assertEqual(pair.trace, [])
                http.request.assert_not_called()

    def test_real_http_status_headers_and_continue_share_short_absolute_deadline(self):
        body = b'{"transport":"short-deadline"}'
        final = b"HTTP/1.0 200 OK\r\nContent-Length: " + str(len(body)).encode() + b"\r\n\r\n" + body
        cases = {
            "partial_status": tuple(bytes((value,)) for value in final),
            "header_trickle": (b"HTTP/1.0 200 OK\r\nX-Slow: ", *(b"x" for _ in range(32)), b"\r\n\r\n" + body),
            "many_headers": (b"HTTP/1.0 200 OK\r\n", *(b"X-Slow: x\r\n" for _ in range(32)), b"\r\n" + body),
            "informational_continue": (*(b"HTTP/1.1 100 Continue\r\nX-Slow: x\r\n\r\n" for _ in range(32)), final),
        }
        for name, parts in cases.items():
            with self.subTest(case=name), loopback_response(parts, interval=0.025) as url:
                endpoint = boundary.Endpoint({"playerA": None}, base_url=url)
                started = time.monotonic()
                # A remaining readiness budget must override the 120s default,
                # even when each individual fragment arrives well within it.
                with self.assertRaises((TimeoutError, boundary.BoundaryError)):
                    endpoint.request("GET", "/unit-short-readiness", "playerA", request_budget_seconds=0.18)
                self.assertLess(time.monotonic() - started, 0.55)
                self.assertEqual(endpoint.metrics["requests"], 0)
                self.assertEqual(boundary.REQUEST_DEADLINE_SECONDS, 120)

    def test_real_http10_normal_close_length_and_chunked_bodies(self):
        body = b'{"transport":"real-http10"}'
        for framing in ("length", "eof", "chunked"):
            if framing == "length":
                headers, encoded = b"Content-Length: " + str(len(body)).encode() + b"\r\n", body
            elif framing == "chunked":
                headers = b"Transfer-Encoding: chunked\r\n"
                encoded = format(len(body), "x").encode() + b"\r\n" + body + b"\r\n0\r\n\r\n"
            else:
                headers, encoded = b"", body
            with self.subTest(framing=framing), loopback_response((b"HTTP/1.0 200 OK\r\n" + headers + b"\r\n" + encoded,)) as url:
                reply = boundary.Endpoint({"playerA": None}, base_url=url).request("GET", "/unit-real-http10", "playerA", request_budget_seconds=1)
                self.assertEqual(reply.status, 200)
                self.assertEqual(reply.raw, body)

    def test_real_http10_body_failures_close_detached_response_socket(self):
        body = b'{"transport":"must-close"}'
        cases = {
            "invalid_length": ((b"HTTP/1.0 200 OK\r\nContent-Length: invalid\r\n\r\n" + body,), 0),
            "truncated_body": ((b"HTTP/1.0 200 OK\r\nContent-Length: 999\r\n\r\n" + body,), 0),
            "invalid_json": ((b"HTTP/1.0 200 OK\r\nContent-Length: 1\r\n\r\n{",), 0),
            "slow_body": ((b"HTTP/1.0 200 OK\r\nContent-Length: 999\r\n\r\n{", *(b"x" for _ in range(32))), 0.025),
        }
        for name, (parts, interval) in cases.items():
            with self.subTest(case=name), loopback_response(parts, interval=interval) as url:
                connection = boundary.http_client.HTTPConnection("127.0.0.1", int(url.rsplit(":", 1)[1]), timeout=1)
                original_connect = connection.connect
                sockets = []

                def observe_connect():
                    original_connect()
                    sockets.append(connection.sock)

                with patch.object(connection, "connect", side_effect=observe_connect), \
                     patch.object(boundary.http_client, "HTTPConnection", return_value=connection):
                    with self.assertRaises((TimeoutError, boundary.BoundaryError, ValueError)):
                        boundary.Endpoint({"playerA": None}, base_url=url).request("GET", "/unit-detached-close", "playerA", request_budget_seconds=0.18)
                self.assertEqual(len(sockets), 1)
                self.assertEqual(sockets[0].fileno(), -1)
                self.assertIsNone(connection.sock)

    def test_deadline_socket_caps_each_separate_send_without_resetting_budget(self):
        transport = MagicMock()
        guarded = boundary.DeadlineSocket(transport, 10)
        with patch.object(boundary.time, "monotonic", side_effect=(2, 7, 11)):
            guarded.sendall(b"headers")
            guarded.sendall(b"body")
            with self.assertRaisesRegex(boundary.BoundaryError, "total budget"):
                guarded.sendall(b"must-not-send")
        self.assertEqual(transport.settimeout.call_args_list, [call(8), call(3)])
        self.assertEqual(transport.sendall.call_args_list, [call(b"headers"), call(b"body")])

    def test_http10_body_completion_never_updates_a_closed_socket(self):
        # Real HTTPResponse.read1() closes the file on Content-Length completion
        # or EOF; this exercises the original closed-socket failure directly.
        body = b'{"transport":"http10"}'
        for with_length in (True, False):
            headers = b"Content-Length: " + str(len(body)).encode() + b"\r\n" if with_length else b""
            connection, transport = http10_connection(b"HTTP/1.0 200 OK\r\n" + headers + b"\r\n" + body)
            with self.subTest(content_length=with_length):
                with patch.object(boundary.http_client, "HTTPConnection", return_value=connection):
                    reply = boundary.Endpoint({"playerA": None}, base_url="http://127.0.0.1:12345").request("GET", "/transport-unit", "playerA")
                self.assertEqual(reply.status, 200)
                self.assertEqual(reply.raw, body)
                self.assertTrue(transport.closed)
                self.assertTrue(all(0 < timeout <= 120 for timeout in transport.timeouts))

    def test_socket_read_timeouts_are_capped_by_remaining_total_deadline(self):
        body = b'{"transport":"remaining-deadline"}'
        wire = b"HTTP/1.0 200 OK\r\nContent-Length: " + str(len(body)).encode() + b"\r\n\r\n" + body
        for budget, expected in ((120, [115, 110, 105]), (30, [25, 20, 15])):
            connection, transport = http10_connection(wire)
            clock = iter(range(0, 100, 5))
            with self.subTest(request_budget_seconds=budget):
                with patch.object(boundary.http_client, "HTTPConnection", return_value=connection), \
                     patch.object(boundary.time, "monotonic", side_effect=lambda: next(clock)):
                    reply = boundary.Endpoint({"playerA": None}, base_url="http://127.0.0.1:12345").request("GET", "/transport-unit", "playerA", request_budget_seconds=budget)
                self.assertEqual(reply.raw, body)
                self.assertEqual(transport.timeouts, expected)
                self.assertLessEqual(reply.elapsed, budget)

    def test_request_budget_cannot_exceed_the_authorized_diagnostic(self):
        endpoint = boundary.Endpoint({"playerA": None}, base_url="http://127.0.0.1:12345")
        with patch.object(boundary.http_client, "HTTPConnection") as transport:
            for budget in (0, -1, 121, True, float("inf"), float("nan")):
                with self.subTest(budget=budget), self.assertRaises(boundary.BoundaryError):
                    endpoint.request("GET", "/transport-unit", "playerA", request_budget_seconds=budget)
            transport.assert_not_called()

    def test_owned_readiness_keeps_its_remaining_30_second_budget(self):
        # Pure ownership-control unit: no Core child or actual network runs.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host = boundary.OwnedHost.__new__(boundary.OwnedHost)
            host.root, host.port, host.tokens = root, 12345, {}
            host.args = SimpleNamespace(core_launcher=root / "selected-launcher.py")
            host.shutdown, host.record = root / "shutdown", {}
            child = MagicMock()
            child.pid, child.poll.return_value = 23456, None
            endpoint = MagicMock()
            endpoint.request.return_value = boundary.Reply(200, b"{}", 0.01, 0)

            def spawned(*args, **kwargs):
                kwargs["stdout"].write(b"Serving Phase 18M reference contract at http://127.0.0.1:12345\n")
                kwargs["stdout"].flush()
                return child

            clock = iter((0, 5, 10))
            try:
                with patch.object(boundary.subprocess, "Popen", side_effect=spawned), \
                     patch.object(boundary.threading, "Timer"), \
                     patch.object(boundary, "require_available_loopback_port"), \
                     patch.object(boundary, "Endpoint", return_value=endpoint), \
                     patch.object(boundary.time, "monotonic", side_effect=lambda: next(clock)):
                    self.assertIs(host.start(), endpoint)
                endpoint.request.assert_called_once_with("GET", "/rules-catalog", "admin", request_budget_seconds=20)
                self.assertEqual(host.record["readinessRequestBudgetSeconds"], 20)
                self.assertEqual(boundary.REQUEST_DEADLINE_SECONDS, 120)
            finally:
                if host.log is not None:
                    host.log.close()

    def test_http10_truncated_declared_body_fails_before_json_classification(self):
        body = b'{"transport":"truncated"}'
        wire = b"HTTP/1.0 200 OK\r\nContent-Length: " + str(len(body) + 7).encode() + b"\r\n\r\n" + body
        connection, transport = http10_connection(wire)
        with patch.object(boundary.http_client, "HTTPConnection", return_value=connection):
            with self.assertRaisesRegex(boundary.BoundaryError, "Truncated declared response body"):
                boundary.Endpoint({"playerA": None}, base_url="http://127.0.0.1:12345").request("GET", "/transport-unit", "playerA")
        self.assertTrue(transport.closed)

    def test_unrelated_catalog_responder_cannot_authorize_owned_readiness(self):
        # Pure process-supervision control test: no child or HTTP server runs.
        # The owned child appears alive once, then reports a bind-failure exit.
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            host = boundary.OwnedHost.__new__(boundary.OwnedHost)
            host.root, host.port, host.tokens = root, 12345, {}
            host.args = SimpleNamespace(core_launcher=root / "selected-launcher.py")
            host.shutdown, host.record = root / "shutdown", {}
            child = MagicMock()
            child.pid = 23456
            child.poll.side_effect = [None, 1]
            unrelated = MagicMock()
            unrelated.request.return_value = boundary.Reply(200, b"{}", 0.001, 0)
            try:
                with patch.object(boundary.subprocess, "Popen", return_value=child), \
                     patch.object(boundary.threading, "Timer"), \
                     patch.object(boundary, "require_available_loopback_port"), \
                     patch.object(boundary, "Endpoint", return_value=unrelated), \
                     patch.object(boundary.time, "sleep"):
                    with self.assertRaises(boundary.BoundaryError):
                        host.start()
                unrelated.request.assert_not_called()
                self.assertNotIn("readyUTC", host.record)
            finally:
                if host.log is not None:
                    host.log.close()

    def test_owned_bind_marker_requires_exact_selected_endpoint(self):
        with tempfile.TemporaryDirectory() as temporary:
            log = Path(temporary) / "host.log"
            log.write_bytes(b"Serving Phase 18M reference contract at http://127.0.0.1:9999\n")
            self.assertIsNone(boundary.owned_bind_marker(log, 12345))
            log.write_bytes(b"Interpreter advisory\r\nServing Phase 18M reference contract at http://127.0.0.1:12345\r\n")
            self.assertEqual(boundary.owned_bind_marker(log, 12345),
                             "Serving Phase 18M reference contract at http://127.0.0.1:12345")

    def test_http_endpoint_rejects_remote_credentials_redirect_or_implicit_port(self):
        for endpoint in ("https://127.0.0.1:1234", "http://example.org:1234",
                         "http://127.0.0.1", "http://user@127.0.0.1:1234",
                         "http://127.0.0.1:1234/path"):
            with self.subTest(endpoint=endpoint), self.assertRaises(boundary.BoundaryError):
                boundary.Endpoint({}, base_url=endpoint)

    def test_role_switch_invalidates_old_callbacks_cursors_and_drafts(self):
        reducer = boundary.ScopeReducer()
        first = reducer.switch("session-one", "playerA")
        self.assertTrue(reducer.accept(first, 3, {"a": "visible"}, "cursor-A"))
        reducer.draft = {"advisory": True}
        second = reducer.switch("session-one", "playerB")
        self.assertIsNone(reducer.body)
        self.assertIsNone(reducer.cursor)
        self.assertIsNone(reducer.draft)
        self.assertFalse(reducer.accept(first, 4, {"a": "hidden"}, "cursor-A"))
        self.assertTrue(reducer.accept(second, 6, {"b": "visible"}, "cursor-B"))
        self.assertFalse(reducer.accept(second, 5, {"b": "old"}, "old-cursor"))
        self.assertEqual(reducer.revision, 6)
        third = reducer.switch("session-two", "playerB")
        self.assertNotEqual(second, third)
        self.assertFalse(reducer.accept(second, 7, {"b": "old-session"}, "old-cursor"))

    def test_secret_scanner_rejects_credentials_before_creating_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / "rejected.json"
            with self.assertRaises(boundary.BoundaryError):
                boundary.write_new(target, b'{"value":"unit-test-secret"}', ("unit-test-secret",))
            self.assertFalse(target.exists())
        for raw in (b'{"Authorization":"value"}', b'{"GH_TOKEN":"value"}',
                    b'{"text":"Bearer abcdefghijklmnopqrstuvwxyz012345"}'):
            with self.subTest(raw=raw), self.assertRaises(boundary.BoundaryError):
                boundary.secret_scan(raw)
        boundary.secret_scan(b'{"role":"playerA","credentialScopeGeneration":2}')

    def test_new_artifact_never_overwrites_previous_attempt(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / "evidence.json"
            boundary.write_new(target, b"{}")
            with self.assertRaises(FileExistsError):
                boundary.write_new(target, b"[]")
            self.assertEqual(target.read_bytes(), b"{}")

    def test_inventory_paths_reject_escape_and_absolute_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for member in ("../escape", "safe/../../escape", "/absolute", "safe\\escape"):
                with self.subTest(member=member), self.assertRaises(boundary.BoundaryError):
                    boundary.member_path(root, member)
            self.assertEqual(boundary.member_path(root, "contracts/example.json"),
                             root / "contracts/example.json")

    def test_comparison_only_normalizes_operational_fields(self):
        value = {"request_id": "opaque-001", "event_cursor": "opaque-cursor",
                 "projection_state_hash": "original-hash", "session_revision": 3,
                 "path": [3, 1, 2], "created_at": "different-clock"}
        normalized = boundary.operational_normalize(value)
        self.assertEqual(normalized["event_cursor"], "<operational>")
        self.assertEqual(normalized["request_id"], value["request_id"])
        self.assertEqual(normalized["projection_state_hash"], value["projection_state_hash"])
        self.assertEqual(normalized["path"], [3, 1, 2])
        self.assertEqual(value["event_cursor"], "opaque-cursor")

    def test_empty_or_blocked_report_cannot_be_success(self):
        report = boundary.Report("capture", REPO)
        self.assertEqual(report.payload()["status"], "NOT_RUN")
        report.case("MOVE-01", "BLOCKED", "Core accepts one-inch candidate", "External recipe unavailable")
        payload = report.payload()
        self.assertEqual(payload["status"], "BLOCKED")
        self.assertEqual(payload["caseCounts"]["passed"], 0)
        self.assertEqual(payload["diagnostic"]["label"], "E01-SLOW120")
        self.assertEqual(payload["diagnostic"]["requestBudgetSeconds"], 120)
        self.assertEqual(payload["diagnostic"]["readinessBudgetSeconds"], 30)
        boundary.secret_scan(boundary.json_bytes(payload))


class LifecycleCommandSafetyTests(unittest.TestCase):
    @staticmethod
    def args(root):
        return SimpleNamespace(output_root=root, report_file=root / "attach-worker.json",
            fixture_root=FIXTURE, core_root=REPO.parent / "Warhammer_40k_AI",
            attach_role="playerA", attach_session="unit-attach-session",
            attach_endpoint="http://127.0.0.1:12345")

    @staticmethod
    def accepted(command, session, operation):
        body = canonical("examples/sessions/session-command-outcome.json")
        body["command_id"], body["session"]["session_id"], body["operation"] = command, session, operation
        revision = 1 if operation == "start_session" else 4 if operation == "submit_finite_decision" else 2
        body["session"]["session_revision"] = body["checkpoint"]["session_revision"] = revision
        if operation == "submit_finite_decision":
            body["checkpoint"].update(visibility_role="player", viewer_player_id="player-a")
            body["session"]["visibility"].update(role="player", player_id="player-a", may_mutate_lifecycle=False, may_submit_decision=True, omniscient=False)
        return boundary.Reply(200, boundary.json_bytes(body), 0, 0)

    @staticmethod
    def created(config, session="opaque-created-session"):
        body = canonical("examples/sessions/session-metadata-created.json")
        body["session_id"], body["game_id"] = session, config["config"]["game_id"]
        return boundary.Reply(201, boundary.json_bytes(body), 0, 0)

    def terminal_fixture(self, root, status, *, error_status=403, committed=None, received_accepted=False, receipt_damage="missing"):
        """Create a real driver-format terminal using a mocked scoped adapter."""
        args, endpoint = self.args(root), MagicMock()
        request = {"request_id": "unit-terminal-request", "actor_id": "player-a", "options": [{"option_id": "unit-option"}]}
        view = {"viewer_player_id": "player-a", "pending_decision": request}
        if status == "ACCEPTED" or (status == "FAILED_EVIDENCE" and received_accepted):
            final = self.accepted("e01-attach-unit-terminal-request", args.attach_session, "submit_finite_decision")
        elif status == "UNKNOWN":
            final = TimeoutError("private untrusted transport detail")
        elif committed is not None:
            body = self.accepted("e01-attach-unit-terminal-request", args.attach_session, "submit_finite_decision").body
            body.update({"accepted": False, "committed": committed, "outcome_code": "proposal_invalid"})
            body["session"]["session_revision"] = body["checkpoint"]["session_revision"] = 4 if committed else 3
            final = boundary.Reply(422, boundary.json_bytes(body), 0, 0)
        else:
            final = boundary.Reply(error_status, boundary.json_bytes({"schema_version": "error-envelope-v1",
                "error": {"code": "access_denied" if error_status == 403 else "proposal_invalid" if error_status == 422 else "internal_error",
                          "message": "Synthetic received error."}}), 0, 0)
        endpoint.request.side_effect = [boundary.Reply(200, boundary.json_bytes({"projection": view}), 0, 0),
            boundary.Reply(200, b'{"session_revision":3}', 0, 0), final]
        if status == "FAILED_PREPARATION":
            endpoint.request.side_effect = TimeoutError("private preparation error")
        original_write = boundary.write_new

        def write_or_fail(path, data, secrets=()):
            if status == "FAILED_EVIDENCE" and path.name.endswith(".response.json"):
                if receipt_damage == "partial":
                    path.write_bytes(data[:max(1, len(data) // 2)])
                elif receipt_damage == "unreadable":
                    path.write_bytes(data)
                raise PermissionError("Unit evidence save failure")
            return original_write(path, data, secrets)

        with patch.object(boundary.importlib, "import_module", return_value=SimpleNamespace(DEV_PLAYER_A_TOKEN="unit-credential")), \
             patch.object(boundary, "Endpoint", return_value=endpoint), \
             patch.object(boundary, "Schemas", return_value=MagicMock()), \
             patch.object(boundary, "write_new", side_effect=write_or_fail):
            code = boundary.attach_worker(args)
        return args, code, boundary.strict_json(args.report_file.read_bytes())

    def test_http_lifecycle_unknown_keeps_exact_input_and_refuses_all_reuse(self):
        for operation in ("start_session", "close_session"):
            with self.subTest(operation=operation), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                report, endpoint = boundary.Report("capture", root), MagicMock()
                endpoint.request.side_effect = TimeoutError("private transport detail Authorization unit-only-secret")
                lane = boundary.HttpCommandLane(endpoint, report, MagicMock(), "unit-session", "supervisor")
                command = boundary.envelope("unit-session", "unit-" + operation, 0, operation)
                with self.assertRaises(boundary.CompletionUnknown) as observed:
                    lane.submit(command, "admin")
                self.assertIsInstance(observed.exception.__cause__, TimeoutError)
                self.assertNotIn("unit-only-secret", str(observed.exception))
                ledger = boundary.strict_json((root / "privileged-submission-attempts/supervisor/command_1.json").read_bytes())
                self.assertEqual(ledger["commandEnvelope"], command)
                self.assertEqual(ledger["submittedRole"], "admin")
                for retry in (command, {**command, "command_id": "new-id-forbidden"}):
                    with self.assertRaisesRegex(boundary.BoundaryError, "Session abandoned"):
                        lane.submit(retry, "admin")
                self.assertEqual(lane.submissions, 1)
                self.assertEqual(len(report.artifacts), 1)
                endpoint.request.assert_called_once()

    def test_http_lifecycle_known_rejection_preserves_receipt_without_unknown(self):
        for status, code in ((403, "access_denied"), (422, "proposal_invalid")):
            with self.subTest(status=status), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                report, endpoint = boundary.Report("capture", root), MagicMock()
                reply = boundary.Reply(status, boundary.json_bytes({"schema_version": "error-envelope-v1",
                    "error": {"code": code, "message": "Synthetic known rejection."}}), 0, 0)
                endpoint.request.return_value = reply
                lane = boundary.HttpCommandLane(endpoint, report, MagicMock(), "unit-session", "supervisor")
                command = boundary.envelope("unit-session", "unit-known-rejection", 0, "start_session")
                self.assertIs(lane.submit(command, "admin"), reply)
                self.assertFalse(lane.submission_unknown)
                self.assertEqual((root / "privileged-submission-attempts/supervisor/command_1.response.json").read_bytes(), reply.raw)

    def test_both_submission_guards_reject_unusable_or_unbound_receipts_as_unknown(self):
        mutations = {
            "empty_matching_payload": lambda body: body.clear(),
            "checkpoint_revision": lambda body: body["checkpoint"].update(session_revision=99),
            "checkpoint_hash": lambda body: body["checkpoint"].update(projection_state_hash="0" * 64),
            "checkpoint_cursor": lambda body: body["checkpoint"].update(event_cursor="wrong-cursor"),
            "event_range_end": lambda body: body["event_range"].update(to_cursor="wrong-range"),
            "command_id": lambda body: body.update(command_id="wrong-command"),
            "session_id": lambda body: body["session"].update(session_id="wrong-session"),
            "operation": lambda body: body.update(operation="close_session"),
            "coherent_wrong_revision": lambda body: (body["session"].update(session_revision=5), body["checkpoint"].update(session_revision=5)),
            "invalid_flags": lambda body: body.update(committed=False),
            "wrong_credential_viewer": lambda body: (body["session"]["visibility"].update(player_id="player-b"), body["checkpoint"].update(viewer_player_id="player-b")),
        }
        for transport in ("http", "paired"):
            for label, mutate in mutations.items():
                with self.subTest(transport=transport, field=label), tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    report, schemas, local, http = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
                    command = boundary.envelope("unit-session", "unit-command", 3, "finite_option", {"request_id": "unit-request"}, option="unit-option")
                    body = self.accepted("unit-command", "unit-session", "submit_finite_decision").body
                    mutate(body)
                    local.request.return_value = http.request.return_value = boundary.Reply(200, boundary.json_bytes(body), 0, 0)
                    lane = boundary.HttpCommandLane(http, report, schemas, "unit-session", "unit") if transport == "http" else boundary.Pair(local, http, SimpleNamespace(report=report, schemas=schemas))
                    lane.session = "unit-session"
                    later = MagicMock()
                    boundary.run_case_groups(report, (
                        (("UNIT-COMMAND",), lambda: lane.submit(command, "playerA")),
                        (("UNIT-LATER",), later),
                    ))
                    self.assertTrue(lane.submission_unknown)
                    self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
                    self.assertEqual(lane.submissions, 1)
                    with self.assertRaisesRegex(boundary.BoundaryError, "Session abandoned"):
                        lane.submit(command, "playerA")
                    later.assert_not_called()
                    self.assertEqual(http.request.call_count, 1)
                    self.assertEqual(local.request.call_count, 1 if transport == "paired" else 0)

    def test_both_submission_guards_validate_complete_received_controls(self):
        for transport in ("http", "paired"):
            for accepted, committed in ((True, True), (False, True), (False, False)):
                with self.subTest(transport=transport, accepted=accepted, committed=committed), tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    report, schemas, local, http = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
                    command = boundary.envelope("unit-session", "unit-command", 3, "finite_option", {"request_id": "unit-request"}, option="unit-option")
                    body = self.accepted("unit-command", "unit-session", "submit_finite_decision").body
                    body.update(accepted=accepted, committed=committed, outcome_code="command_committed" if accepted else "proposal_invalid")
                    body["session"]["session_revision"] = body["checkpoint"]["session_revision"] = 4 if committed else 3
                    reply = boundary.Reply(200 if accepted else 422, boundary.json_bytes(body), 0, 0)
                    local.request.return_value = http.request.return_value = reply
                    lane = boundary.HttpCommandLane(http, report, schemas, "unit-session", "unit") if transport == "http" else boundary.Pair(local, http, SimpleNamespace(report=report, schemas=schemas))
                    lane.session = "unit-session"
                    result = lane.submit(command, "playerA")
                    self.assertIs(result if transport == "http" else result[1], reply)
                    self.assertFalse(lane.submission_unknown)
                    self.assertIn(call("session-command-outcome.schema.json", body), schemas.validate.call_args_list)

    def test_both_submission_guards_apply_real_frozen_schema_to_complete_receipts(self):
        schemas = boundary.Schemas(FIXTURE)
        for transport in ("http", "paired"):
            with self.subTest(transport=transport), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                report, local, http = boundary.Report("capture", root), MagicMock(), MagicMock()
                command = boundary.envelope("unit-session", "unit-command", 3, "finite_option", {"request_id": "unit-request"}, option="unit-option")
                body = self.accepted("unit-command", "unit-session", "submit_finite_decision").body
                # Coherence alone passes; this required metadata field is
                # checked by the exact selected public schema inside the guard.
                del body["session"]["catalog_id"]
                self.assertEqual(boundary.classify(200, body), "accepted")
                local.request.return_value = http.request.return_value = boundary.Reply(200, boundary.json_bytes(body), 0, 0)
                lane = boundary.HttpCommandLane(http, report, schemas, "unit-session", "unit") if transport == "http" else boundary.Pair(local, http, SimpleNamespace(report=report, schemas=schemas))
                lane.session = "unit-session"
                with self.assertRaises(boundary.CompletionUnknown):
                    lane.submit(command, "playerA")
                self.assertTrue(lane.submission_unknown)

    def test_create_commit_before_timeout_retains_exact_config_and_stops_downstream(self):
        for paired in (False, True):
            with self.subTest(paired=paired), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                report, schemas = boundary.Report("capture", root), MagicMock()
                config = canonical("examples/sessions/session-create.json")
                config["config"]["game_id"] = "unit-exact-create"
                local, http = MagicMock(), MagicMock()
                committed = []

                def commit(method, path, role, body, query=None):
                    committed.append(copy.deepcopy(body))
                    return boundary.Reply(201, b'{"session_id":"unit-created"}', 0, 0)

                if paired:
                    local.request.side_effect = commit
                    http.request.side_effect = TimeoutError("private create receipt lost")
                    client = boundary.Pair(local, http, SimpleNamespace(report=report, schemas=schemas))
                else:
                    def lost_receipt(*args, **kwargs):
                        commit(*args, **kwargs)
                        raise TimeoutError("private create receipt lost")
                    http.request.side_effect = lost_receipt
                    client = http
                downstream = MagicMock()
                boundary.run_case_groups(report, (
                    (("UNIT-CREATE",), lambda: boundary.create_session_attempt(client, config, report, schemas, "unit", paired=paired)),
                    (("UNIT-START", "UNIT-ACTION"), downstream),
                ))
                self.assertEqual(committed, [config])
                ledger_path = root / "privileged-session-create-attempts/unit.json"
                ledger = boundary.strict_json(ledger_path.read_bytes())
                self.assertEqual(ledger["requestBody"], config)
                self.assertEqual(ledger["requestBytesSHA256"], boundary.sha256(boundary.json_bytes(config)))
                self.assertEqual(ledger["submittedRole"], "admin")
                self.assertIn("No creation idempotency", ledger["retryPolicy"])
                self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
                self.assertIs(client.creation_unknown, True)
                if paired:
                    self.assertTrue(client.submission_unknown)
                    self.assertEqual(client.submissions, 0)
                before = ledger_path.read_bytes()
                with self.assertRaisesRegex(boundary.BoundaryError, "creation UNKNOWN"):
                    boundary.create_session_attempt(client, config, report, schemas, "must-not-recreate", paired=paired)
                self.assertEqual(ledger_path.read_bytes(), before)
                self.assertFalse((root / "privileged-session-create-attempts/must-not-recreate.json").exists())
                downstream.assert_not_called()
                self.assertEqual(http.request.call_count, 1)
                if not paired:
                    lane = boundary.HttpCommandLane(http, report, schemas, "unknown-session", "blocked")
                    with self.assertRaisesRegex(boundary.BoundaryError, "creation UNKNOWN"):
                        lane.submit(boundary.envelope("unknown-session", "no-start", 0, "start_session"), "admin")
                    self.assertEqual(lane.submissions, 0)

    def test_create_preflight_schema_failure_is_not_unknown_and_sends_nothing(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report, schemas, endpoint = boundary.Report("capture", root), MagicMock(), MagicMock()
            schemas.validate.side_effect = boundary.BoundaryError("Unit local create schema failure")
            with self.assertRaisesRegex(boundary.BoundaryError, "local create schema") as observed:
                boundary.create_session_attempt(endpoint, {}, report, schemas, "unit")
            self.assertNotIsInstance(observed.exception, boundary.CompletionUnknown)
            self.assertEqual(report.artifacts, [])
            endpoint.request.assert_not_called()

    def test_creation_guards_reject_incomplete_or_wrong_metadata_before_downstream(self):
        schemas = boundary.Schemas(FIXTURE)
        mutations = {
            "only_session_id": lambda body: {"session_id": body["session_id"]},
            "missing_schema_field": lambda body: {key: value for key, value in body.items() if key != "catalog_id"},
            "wrong_game": lambda body: {**body, "game_id": "other-game"},
            "wrong_build": lambda body: {**body, "engine_build_id": "other-runtime-build"},
            "wrong_contract": lambda body: {**body, "server_contract_version": "44.3.32"},
            "wrong_state": lambda body: {**body, "session_state": "active"},
            "wrong_revision": lambda body: {**body, "session_revision": 1},
            "wrong_scope": lambda body: {**body, "visibility": {**body["visibility"], "role": "player", "player_id": "player-a"}},
            "wrong_admin_policy": lambda body: {**body, "visibility": {**body["visibility"], "may_submit_decision": True}},
            "wrong_ruleset": lambda body: {**body, "ruleset_id": {"different": "ruleset"}},
            "wrong_overlays": lambda body: {**body, "rules_overlay_ids": ["other-overlay"]},
            "wrong_catalog": lambda body: {**body, "catalog_id": "other-catalog"},
            "wrong_source_package": lambda body: {**body, "source_package_id": "other-package"},
        }
        for paired in (False, True):
            for label, mutate in mutations.items():
                with self.subTest(paired=paired, metadata=label), tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    report, local, http, later = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
                    config = canonical("examples/sessions/session-create.json")
                    config["config"]["game_id"] = "unit-retained-create-game"
                    body = mutate(self.created(config).body)
                    local.request.return_value = http.request.return_value = boundary.Reply(201, boundary.json_bytes(body), 0, 0)
                    client = boundary.Pair(local, http, SimpleNamespace(report=report, schemas=schemas)) if paired else http
                    boundary.run_case_groups(report, (
                        (("UNIT-CREATE",), lambda: boundary.create_session_attempt(client, config, report, schemas, "unit", paired=paired)),
                        (("UNIT-START",), later),
                    ))
                    self.assertIs(client.creation_unknown, True)
                    self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
                    ledger = boundary.strict_json((root / "privileged-session-create-attempts/unit.json").read_bytes())
                    self.assertEqual(ledger["requestBody"], config)
                    later.assert_not_called()
                    self.assertEqual(http.request.call_count, 1)
                    self.assertEqual(local.request.call_count, 1 if paired else 0)

    def test_complete_creation_metadata_keeps_opaque_returned_session_identity(self):
        schemas = boundary.Schemas(FIXTURE)
        for paired in (False, True):
            with self.subTest(paired=paired), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                report, local, http = boundary.Report("capture", root), MagicMock(), MagicMock()
                config = canonical("examples/sessions/session-create.json")
                config["config"]["game_id"] = "unit-created-game"
                reply = self.created(config, "opaque:unrelated-session-42")
                local.request.return_value = http.request.return_value = reply
                client = boundary.Pair(local, http, SimpleNamespace(report=report, schemas=schemas)) if paired else http
                result = boundary.create_session_attempt(client, config, report, schemas, "unit", paired=paired)
                self.assertIs(result[1] if paired else result, reply)
                self.assertEqual((result[1] if paired else result).body["session_id"], "opaque:unrelated-session-42")
                self.assertEqual((root / "privileged-session-create-attempts/unit.response.json").read_bytes(), reply.raw)

    def test_deep_http_receipt_uses_typed_unknown_submission_guard(self):
        raw = b"[" * 2000 + b"0" + b"]" * 2000
        wire = b"HTTP/1.0 200 OK\r\nContent-Length: " + str(len(raw)).encode() + b"\r\n\r\n" + raw
        with tempfile.TemporaryDirectory() as temporary, loopback_response((wire,)) as url:
            report = boundary.Report("capture", Path(temporary))
            endpoint = boundary.Endpoint({"playerA": None}, base_url=url)
            lane = boundary.HttpCommandLane(endpoint, report, MagicMock(), "unit-session", "unit")
            command = boundary.envelope("unit-session", "unit-deep-command", 3, "finite_option", {"request_id": "unit-request"}, option="unit-option")
            with self.assertRaises(boundary.CompletionUnknown) as observed:
                lane.submit(command, "playerA")
            self.assertIsInstance(observed.exception.__cause__, boundary.BoundaryError)
            self.assertIn("nesting", str(observed.exception.__cause__))
            self.assertTrue(lane.submission_unknown)
            self.assertEqual(lane.submissions, 1)

    def test_lifetime_create_unknown_stops_before_start_or_worker(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, report, endpoint = self.args(root), boundary.Report("capture", root), MagicMock()
            endpoint.request.side_effect = TimeoutError("Unit created but receipt lost")
            with patch.object(boundary, "Schemas", return_value=MagicMock()), \
                 patch.object(boundary, "run_attach_worker") as worker:
                with self.assertRaises(boundary.CompletionUnknown):
                    boundary.lifetime_cases(args, report, MagicMock(), endpoint, {}, "main", {"config": {"game_id": "unit"}})
            endpoint.request.assert_called_once()
            worker.assert_not_called()

    def test_attach_worker_retains_scoped_attempt_and_types_received_or_unknown(self):
        for outcome in ("ACCEPTED", "REJECTED", "UNKNOWN"):
            with self.subTest(outcome=outcome), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args, endpoint = self.args(root), MagicMock()
                request = {"request_id": "unit-actor-request", "actor_id": "player-a",
                    "options": [{"option_id": "unit-offered-option"}]}
                view = {"viewer_player_id": "player-a", "pending_decision": request, "pending_proposal": None}
                projection = boundary.Reply(200, boundary.json_bytes({"projection": view}), 0, 0)
                metadata = boundary.Reply(200, b'{"session_revision":3}', 0, 0)
                if outcome == "ACCEPTED":
                    terminal = self.accepted("e01-attach-unit-actor-request", args.attach_session, "submit_finite_decision")
                elif outcome == "REJECTED":
                    terminal = boundary.Reply(403, boundary.json_bytes({"schema_version": "error-envelope-v1",
                        "error": {"code": "access_denied", "message": "Synthetic known rejection."}}), 0, 0)
                else:
                    terminal = TimeoutError("private transport detail Authorization unit-only-secret")
                endpoint.request.side_effect = [projection, metadata, terminal]
                access = SimpleNamespace(DEV_PLAYER_A_TOKEN="unit-worker-credential")
                with patch.object(boundary.importlib, "import_module", return_value=access), \
                     patch.object(boundary, "Endpoint", return_value=endpoint), \
                     patch.object(boundary, "Schemas", return_value=MagicMock()):
                    exit_code = boundary.attach_worker(args)
                result = boundary.strict_json(args.report_file.read_bytes())
                self.assertEqual(result["status"], outcome)
                self.assertEqual(exit_code, 0 if outcome == "ACCEPTED" else 2)
                self.assertEqual(result["commandCompletion"], "UNKNOWN" if outcome == "UNKNOWN" else "RECEIVED")
                self.assertEqual(result["accepted"], True if outcome == "ACCEPTED" else None)
                self.assertEqual(result["committed"], True if outcome == "ACCEPTED" else None)
                snapshot = boundary.strict_json((root / "attach-worker-private/private-attempts/command_1/playerA.json").read_bytes())
                ledger = boundary.strict_json((root / "attach-worker-private/privileged-submission-attempts/worker/command_1.json").read_bytes())
                self.assertEqual(snapshot["authorizedViewBeforeSubmission"], view)
                self.assertEqual(snapshot["commandEnvelope"], ledger["commandEnvelope"])
                self.assertEqual(ledger["commandEnvelope"], endpoint.request.call_args.args[3])
                self.assertFalse((root / "attach-worker-private/private-attempts/command_1/playerB.json").exists())
                self.assertEqual(endpoint.request.call_count, 3)
                self.assertNotIn(b"unit-only-secret", args.report_file.read_bytes())
                self.assertNotIn(b"unit-worker-credential", args.report_file.read_bytes())

    def test_attach_preparation_failure_never_claims_unknown_or_submits(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, endpoint = self.args(root), MagicMock()
            endpoint.request.side_effect = TimeoutError("private preparation error")
            with patch.object(boundary.importlib, "import_module", return_value=SimpleNamespace(DEV_PLAYER_A_TOKEN="unit-credential")), \
                 patch.object(boundary, "Endpoint", return_value=endpoint), \
                 patch.object(boundary, "Schemas", return_value=MagicMock()):
                self.assertEqual(boundary.attach_worker(args), 2)
            result = boundary.strict_json(args.report_file.read_bytes())
            self.assertEqual(result["status"], "FAILED_PREPARATION")
            self.assertEqual(result["commandCompletion"], "NOT_SUBMITTED")
            self.assertEqual(result["artifacts"], [])
            endpoint.request.assert_called_once()

    def test_attach_error_envelopes_preserve_absent_flags_and_outcomes_keep_exact_flags(self):
        cases = ((403, None), (422, None), (500, None), (422, True), (422, False))
        for status, committed in cases:
            with self.subTest(status=status, committed=committed), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args, endpoint = self.args(root), MagicMock()
                request = {"request_id": "unit-flags-request", "actor_id": "player-a", "options": [{"option_id": "unit-option"}]}
                view = {"viewer_player_id": "player-a", "pending_decision": request}
                if committed is None:
                    body = {"schema_version": "error-envelope-v1", "error": {
                        "code": "access_denied" if status == 403 else "proposal_invalid" if status == 422 else "internal_error",
                        "message": "Synthetic received error without flags."}}
                else:
                    body = self.accepted("e01-attach-unit-flags-request", args.attach_session, "submit_finite_decision").body
                    body.update({"accepted": False, "committed": committed, "outcome_code": "proposal_invalid"})
                    body["session"]["session_revision"] = body["checkpoint"]["session_revision"] = 4 if committed else 3
                endpoint.request.side_effect = [boundary.Reply(200, boundary.json_bytes({"projection": view}), 0, 0),
                    boundary.Reply(200, b'{"session_revision":3}', 0, 0), boundary.Reply(status, boundary.json_bytes(body), 0, 0)]
                with patch.object(boundary.importlib, "import_module", return_value=SimpleNamespace(DEV_PLAYER_A_TOKEN="unit-credential")), \
                     patch.object(boundary, "Endpoint", return_value=endpoint), \
                     patch.object(boundary, "Schemas", return_value=MagicMock()):
                    self.assertEqual(boundary.attach_worker(args), 2)
                result = boundary.strict_json(args.report_file.read_bytes())
                self.assertEqual(result["status"], "REJECTED")
                self.assertEqual(result["commandCompletion"], "RECEIVED")
                self.assertIs(result["committed"], committed)
                self.assertIs(result["accepted"], None if committed is None else False)
                self.assertEqual(endpoint.request.call_count, 3)

    def test_attach_known_rejection_stays_received_when_evidence_write_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, endpoint = self.args(root), MagicMock()
            request = {"request_id": "unit-known-request", "actor_id": "player-a", "options": [{"option_id": "unit-option"}]}
            view = {"viewer_player_id": "player-a", "pending_decision": request}
            endpoint.request.side_effect = [boundary.Reply(200, boundary.json_bytes({"projection": view}), 0, 0),
                boundary.Reply(200, b'{"session_revision":3}', 0, 0),
                boundary.Reply(403, boundary.json_bytes({"schema_version": "error-envelope-v1",
                    "error": {"code": "access_denied", "message": "Synthetic known rejection."}}), 0, 0)]
            original_write = boundary.write_new

            def fail_response_write(path, data, secrets=()):
                if path.name.endswith(".response.json"):
                    raise PermissionError("Unit response evidence write failure")
                return original_write(path, data, secrets)

            with patch.object(boundary.importlib, "import_module", return_value=SimpleNamespace(DEV_PLAYER_A_TOKEN="unit-credential")), \
                 patch.object(boundary, "Endpoint", return_value=endpoint), \
                 patch.object(boundary, "Schemas", return_value=MagicMock()), \
                 patch.object(boundary, "write_new", side_effect=fail_response_write):
                self.assertEqual(boundary.attach_worker(args), 2)
            result = boundary.strict_json(args.report_file.read_bytes())
            self.assertEqual(result["status"], "FAILED_EVIDENCE")
            self.assertEqual(result["commandCompletion"], "RECEIVED")
            self.assertIsNone(result["accepted"])
            self.assertIsNone(result["committed"])
            self.assertEqual(result["httpStatus"], 403)

    def test_failed_evidence_preserves_validated_accepted_and_rejected_receipts_when_raw_damaged(self):
        for accepted in (True, False):
            for damage in ("missing", "partial", "unreadable"):
                with self.subTest(accepted=accepted, damage=damage), tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    args, code, result = self.terminal_fixture(root, "FAILED_EVIDENCE", received_accepted=accepted, receipt_damage=damage)
                    self.assertEqual(result["commandCompletion"], "RECEIVED")
                    self.assertIs(result["accepted"], True if accepted else None)
                    self.assertEqual(set(result["receivedReceipt"]), {"httpStatus", "body", "rawSHA256"})
                    report, endpoint, child, later = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
                    endpoint.base_url = args.attach_endpoint
                    child.pid, child.wait.return_value = 56796, code
                    receipt = root / "attach-worker-private/privileged-submission-attempts/worker/command_1.response.json"
                    original_open = Path.open

                    def read_or_deny(path, *args, **kwargs):
                        if damage == "unreadable" and path == receipt:
                            raise PermissionError("private untrusted artifact error")
                        return original_open(path, *args, **kwargs)

                    with patch.object(boundary.subprocess, "Popen", return_value=child), patch.object(Path, "open", new=read_or_deny):
                        with self.assertRaises(boundary.BoundaryError) as observed:
                            boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
                    self.assertNotIsInstance(observed.exception, boundary.CompletionUnknown)
                    terminal = report.details["processes"][0]["terminalResult"]
                    self.assertEqual(terminal["evidenceStatus"], "FAIL")
                    self.assertIs(terminal["knownCompletion"]["accepted"], True if accepted else None)
                    self.assertIs(terminal["knownCompletion"]["committed"], True if accepted else None)
                    self.assertNotIn(b"private untrusted artifact error", boundary.json_bytes(report.payload()))
                    later.assert_not_called()
                    endpoint.request.assert_not_called()

    def test_worker_incoherent_receipt_never_emits_received_or_accepted(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, endpoint = self.args(root), MagicMock()
            request = {"request_id": "unit-bad-checkpoint", "actor_id": "player-a", "options": [{"option_id": "unit-option"}]}
            view = {"viewer_player_id": "player-a", "pending_decision": request}
            body = self.accepted("e01-attach-unit-bad-checkpoint", args.attach_session, "submit_finite_decision").body
            body["checkpoint"]["session_revision"] += 1
            endpoint.request.side_effect = [boundary.Reply(200, boundary.json_bytes({"projection": view}), 0, 0),
                boundary.Reply(200, b'{"session_revision":3}', 0, 0), boundary.Reply(200, boundary.json_bytes(body), 0, 0)]
            with patch.object(boundary.importlib, "import_module", return_value=SimpleNamespace(DEV_PLAYER_A_TOKEN="unit-credential")), \
                 patch.object(boundary, "Endpoint", return_value=endpoint), \
                 patch.object(boundary, "Schemas", return_value=MagicMock()):
                self.assertEqual(boundary.attach_worker(args), 2)
            result = boundary.strict_json(args.report_file.read_bytes())
            self.assertEqual(result["status"], "UNKNOWN")
            self.assertEqual(result["commandCompletion"], "UNKNOWN")
            self.assertIsNone(result["accepted"])
            self.assertNotIn("receivedReceipt", result)
            self.assertEqual(endpoint.request.call_count, 3)

    def test_parent_records_exited_unknown_worker_and_performs_no_more_commands(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, report, endpoint = self.args(root), boundary.Report("capture", root), MagicMock()
            endpoint.base_url = args.attach_endpoint
            self.terminal_fixture(root, "UNKNOWN")
            child = MagicMock()
            child.pid, child.wait.return_value = 34567, 2
            with patch.object(boundary.subprocess, "Popen", return_value=child):
                with self.assertRaisesRegex(boundary.CompletionUnknown, "UNKNOWN"):
                    boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
            self.assertEqual(len(report.details["processes"]), 1)
            process = report.details["processes"][0]
            self.assertEqual((process["owner"], process["pid"], process["exitCode"]), ("attach-worker", 34567, 2))
            self.assertEqual(process["maximumSeconds"], 1800)
            self.assertFalse(process["timedOut"])
            self.assertEqual(process["cleanup"], "normal-exit")
            self.assertEqual(process["scriptSHA256"], boundary.sha256(Path(boundary.__file__).read_bytes()))
            self.assertIn("startUTC", process)
            self.assertIn("exitUTC", process)
            self.assertTrue(process["executableSHA256"])
            self.assertEqual(process["terminalResult"]["validation"], "PASS")
            endpoint.request.assert_not_called()

    def test_parent_unreadable_terminal_forms_are_unknown_with_safe_raw_descriptor(self):
        forms = {"absent": None, "empty": b"", "truncated": b'{"status":"ACCEPTED",',
            "deeply_nested": b"[" * 2000 + b"0" + b"]" * 2000,
            "invalid_utf8": b'\xffprivate-untrusted-message', "null": b"null", "array": b"[]", "scalar": b"23"}
        for label, raw in forms.items():
            with self.subTest(form=label), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args = self.args(root)
                if raw is not None:
                    args.report_file.write_bytes(raw)
                report, endpoint, child, later = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
                endpoint.base_url = args.attach_endpoint
                child.pid, child.wait.return_value = 56789, 2
                with patch.object(boundary.subprocess, "Popen", return_value=child):
                    boundary.run_case_groups(report, (
                        (("UNIT-WORKER",), lambda: boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())),
                        (("UNIT-LATER",), later),
                    ))
                self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
                process = report.details["processes"][0]
                self.assertEqual(process["exitCode"], 2)
                self.assertIn("exitUTC", process)
                self.assertEqual(process["terminalResult"]["validation"], "FAIL")
                if raw is not None:
                    self.assertEqual(process["terminalResult"]["sha256"], boundary.sha256(raw))
                    self.assertEqual(args.report_file.read_bytes(), raw)
                self.assertNotIn(b"private-untrusted-message", boundary.json_bytes(report.payload()))
                later.assert_not_called()
                endpoint.request.assert_not_called()

    def test_parent_inconsistent_terminal_matrix_is_unknown_without_later_submissions(self):
        mutations = {
            "schema_bool": lambda row: row.update(schemaVersion=True),
            "schema_version": lambda row: row.update(schemaVersion=2),
            "role": lambda row: row.update(role="playerB"),
            "session": lambda row: row.update(session="other-session"),
            "missing_status": lambda row: row.pop("status"),
            "status_type": lambda row: row.update(status=[]),
            "status_value": lambda row: row.update(status="untrusted-status"),
            "accepted_flag": lambda row: row.update(accepted=True),
            "committed_flag": lambda row: row.update(committed=False),
            "missing_flag": lambda row: row.pop("committed"),
            "completion": lambda row: row.update(commandCompletion="RECEIVED"),
            "ownership": lambda row: row.update(ownership="other-owner"),
            "cause_message": lambda row: row.update(causeType="private-untrusted-message with spaces"),
            "missing_artifacts": lambda row: row.pop("artifacts"),
            "artifact_type": lambda row: row.update(artifacts=None),
            "artifact_scalar": lambda row: row["artifacts"].append("not-a-descriptor"),
            "artifact_missing_bytes": lambda row: row["artifacts"][0].pop("bytes"),
            "artifact_bool_bytes": lambda row: row["artifacts"][0].update(bytes=True),
            "artifact_bad_hash": lambda row: row["artifacts"][0].update(sha256="g" * 64),
            "artifact_hash_drift": lambda row: row["artifacts"][0].update(sha256="0" * 64),
            "artifact_duplicate": lambda row: row["artifacts"].append(copy.deepcopy(row["artifacts"][0])),
            "artifact_foreign_path": lambda row: row["artifacts"][0].update(path=str(REPO / "AGENTS.md")),
            "missing_command": lambda row: row.pop("commandId"),
            "envelope_hash": lambda row: row.update(envelopeBytesSHA256="0" * 64),
        }
        for label, mutate in mutations.items():
            with self.subTest(field=label), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args, code, result = self.terminal_fixture(root, "UNKNOWN")
                mutate(result)
                raw = boundary.json_bytes(result)
                args.report_file.write_bytes(raw)
                report, endpoint, child, later = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
                endpoint.base_url = args.attach_endpoint
                child.pid, child.wait.return_value = 56790, code
                with patch.object(boundary.subprocess, "Popen", return_value=child):
                    boundary.run_case_groups(report, (
                        (("UNIT-WORKER",), lambda: boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())),
                        (("UNIT-LATER",), later),
                    ))
                self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
                self.assertEqual(report.details["processes"][0]["terminalResult"]["sha256"], boundary.sha256(raw))
                self.assertEqual(report.details["processes"][0]["exitCode"], code)
                self.assertNotIn(b"private-untrusted-message", boundary.json_bytes(report.payload()))
                later.assert_not_called()
                endpoint.request.assert_not_called()

    def test_parent_valid_typed_statuses_keep_exact_known_or_unknown_disposition(self):
        variants = (("ACCEPTED", 403, None), ("UNKNOWN", 403, None), ("FAILED_PREPARATION", 403, None),
            ("FAILED_EVIDENCE", 403, None), ("REJECTED", 403, None), ("REJECTED", 422, None),
            ("REJECTED", 500, None), ("REJECTED", 422, True), ("REJECTED", 422, False))
        for status, http_status, committed in variants:
            with self.subTest(status=status, http_status=http_status, committed=committed), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args, code, result = self.terminal_fixture(root, status, error_status=http_status, committed=committed)
                report, endpoint, child = boundary.Report("capture", root), MagicMock(), MagicMock()
                endpoint.base_url = args.attach_endpoint
                child.pid, child.wait.return_value = 56791, code
                with patch.object(boundary.subprocess, "Popen", return_value=child):
                    if status == "ACCEPTED":
                        self.assertEqual(boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock()), {key: value for key, value in result.items() if key != "receivedReceipt"})
                    else:
                        with self.assertRaises(boundary.BoundaryError) as observed:
                            boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
                        self.assertEqual(isinstance(observed.exception, boundary.CompletionUnknown), status == "UNKNOWN")
                terminal = report.details["processes"][0]["terminalResult"]
                self.assertEqual(terminal["validation"], "PASS")
                if result["commandCompletion"] == "RECEIVED":
                    self.assertIs(terminal["knownCompletion"]["accepted"], result["accepted"])
                    self.assertIs(terminal["knownCompletion"]["committed"], result["committed"])
                endpoint.request.assert_not_called()

    def test_parent_validated_receipt_survives_later_manifest_failure_without_unknown(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, code, result = self.terminal_fixture(root, "ACCEPTED")
            foreign = root / "unrelated-private-data.json"
            foreign.write_bytes(b"private-unrelated-data-must-not-be-read")
            result["artifacts"][0]["path"] = str(foreign)
            args.report_file.write_bytes(boundary.json_bytes(result))
            report, endpoint, child, later = boundary.Report("capture", root), MagicMock(), MagicMock(), MagicMock()
            endpoint.base_url = args.attach_endpoint
            child.pid, child.wait.return_value = 56792, code
            original_open = Path.open

            def forbid_foreign(path, *args, **kwargs):
                if path == foreign:
                    raise AssertionError("Unvalidated artifact path was read")
                return original_open(path, *args, **kwargs)

            with patch.object(boundary.subprocess, "Popen", return_value=child), patch.object(Path, "open", new=forbid_foreign):
                with self.assertRaises(boundary.BoundaryError) as observed:
                    boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
            self.assertNotIsInstance(observed.exception, boundary.CompletionUnknown)
            terminal = report.details["processes"][0]["terminalResult"]
            self.assertEqual(terminal["validation"], "FAIL")
            self.assertIs(terminal["knownCompletion"]["accepted"], True)
            self.assertIs(terminal["knownCompletion"]["committed"], True)
            self.assertIn("Validated retained raw receipt", terminal["receiptEvidence"])
            self.assertNotIn(b"private-unrelated-data", boundary.json_bytes(report.payload()))
            later.assert_not_called()
            endpoint.request.assert_not_called()

    def test_parent_received_core_or_receipt_inconsistency_is_unknown_before_trust(self):
        mutations = {
            "missing_http": lambda row: row.pop("httpStatus"),
            "boolean_http": lambda row: row.update(httpStatus=True),
            "wrong_http": lambda row: row.update(httpStatus=500),
            "wrong_outcome": lambda row: row.update(outcome="error"),
            "absent_committed": lambda row: row.update(committed=None),
            "wrong_exit_status": lambda row: row.update(status="REJECTED"),
            "missing_representation": lambda row: row.pop("receivedReceipt"),
            "representation_scalar": lambda row: row.update(receivedReceipt=None),
            "representation_http": lambda row: row["receivedReceipt"].update(httpStatus=422),
            "representation_body": lambda row: row["receivedReceipt"].update(body={}),
            "representation_revision": lambda row: row["receivedReceipt"]["body"]["checkpoint"].update(session_revision=99),
            "representation_operation": lambda row: row["receivedReceipt"]["body"].update(operation="close_session"),
            "representation_command": lambda row: row["receivedReceipt"]["body"].update(command_id="other-command"),
            "representation_hash": lambda row: row["receivedReceipt"].update(rawSHA256="bad-hash"),
        }
        for label, mutate in mutations.items():
            with self.subTest(field=label), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args, code, result = self.terminal_fixture(root, "ACCEPTED")
                mutate(result)
                args.report_file.write_bytes(boundary.json_bytes(result))
                report, endpoint, child = boundary.Report("capture", root), MagicMock(), MagicMock()
                endpoint.base_url = args.attach_endpoint
                child.pid, child.wait.return_value = 56793, code
                with patch.object(boundary.subprocess, "Popen", return_value=child):
                    with self.assertRaises(boundary.CompletionUnknown):
                        boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
                endpoint.request.assert_not_called()
        for raw in (b"{", b'{"accepted":true}', b"null"):
            with self.subTest(receipt=raw), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                args, code, _ = self.terminal_fixture(root, "ACCEPTED")
                receipt = root / "attach-worker-private/privileged-submission-attempts/worker/command_1.response.json"
                receipt.write_bytes(raw)
                report, endpoint, child = boundary.Report("capture", root), MagicMock(), MagicMock()
                endpoint.base_url = args.attach_endpoint
                child.pid, child.wait.return_value = 56794, code
                with patch.object(boundary.subprocess, "Popen", return_value=child):
                    with self.assertRaises(boundary.BoundaryError) as observed:
                        boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
                self.assertNotIsInstance(observed.exception, boundary.CompletionUnknown)
                self.assertTrue(report.details["processes"][0]["terminalResult"]["knownCompletion"]["accepted"])
                self.assertEqual(report.details["processes"][0]["terminalResult"]["evidenceStatus"], "FAIL")
                endpoint.request.assert_not_called()
        for artifact in ("snapshot", "ledger"):
            for raw in (b"null", b"[]", b"{", b"\xff"):
                with self.subTest(artifact=artifact, raw=raw), tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    args, code, _ = self.terminal_fixture(root, "ACCEPTED")
                    target = root / ("attach-worker-private/private-attempts/command_1/playerA.json" if artifact == "snapshot"
                        else "attach-worker-private/privileged-submission-attempts/worker/command_1.json")
                    target.write_bytes(raw)
                    report, endpoint, child = boundary.Report("capture", root), MagicMock(), MagicMock()
                    endpoint.base_url = args.attach_endpoint
                    child.pid, child.wait.return_value = 56795, code
                    with patch.object(boundary.subprocess, "Popen", return_value=child):
                        with self.assertRaises(boundary.CompletionUnknown):
                            boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
                    endpoint.request.assert_not_called()

    def test_parent_worker_timeout_records_owned_termination_and_unknown(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, report, endpoint = self.args(root), boundary.Report("capture", root), MagicMock()
            endpoint.base_url = args.attach_endpoint
            child = MagicMock()
            child.pid = 45678
            child.wait.side_effect = [boundary.subprocess.TimeoutExpired("unit-worker", 1800), 1]
            with patch.object(boundary.subprocess, "Popen", return_value=child):
                with self.assertRaisesRegex(boundary.CompletionUnknown, "UNKNOWN"):
                    boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
            child.terminate.assert_called_once()
            child.kill.assert_not_called()
            process = report.details["processes"][0]
            self.assertTrue(process["timedOut"])
            self.assertEqual(process["exitCode"], 1)
            self.assertEqual(process["cleanup"], "owned-process-handle-terminate")
            endpoint.request.assert_not_called()

    def test_parent_wait_failure_cleans_up_owned_worker_and_records_unknown(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, report, endpoint = self.args(root), boundary.Report("capture", root), MagicMock()
            endpoint.base_url = args.attach_endpoint
            child = MagicMock()
            child.pid, child.poll.return_value = 45679, None
            child.wait.side_effect = [OSError("Unit failed wait"), 1]
            with patch.object(boundary.subprocess, "Popen", return_value=child):
                with self.assertRaises(boundary.CompletionUnknown):
                    boundary.run_attach_worker(args, report, endpoint, args.attach_session, MagicMock())
            child.terminate.assert_called_once()
            process = report.details["processes"][0]
            self.assertEqual(process["exitCode"], 1)
            self.assertEqual(process["cleanup"], "owned-process-handle-finally-terminate")
            endpoint.request.assert_not_called()

    def test_lifetime_worker_unknown_stops_before_close_restart_or_further_reads(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args, report, endpoint, host = self.args(root), boundary.Report("capture", root), MagicMock(), MagicMock()
            config = canonical("examples/sessions/session-create.json")
            config["config"]["game_id"] = "unit-game"
            attach_config = copy.deepcopy(config)
            attach_config["config"]["game_id"] += "-attach"
            endpoint.request.side_effect = [self.created(attach_config, args.attach_session),
                self.accepted("e01-attach-start", args.attach_session, "start_session")]
            later = MagicMock()
            with patch.object(boundary, "Schemas", return_value=MagicMock()), \
                 patch.object(boundary, "run_attach_worker", side_effect=boundary.CompletionUnknown("Unit worker UNKNOWN")), \
                 patch.object(boundary, "OwnedHost") as restart:
                boundary.run_case_groups(report, (
                    (("LIFETIME-01",), lambda: boundary.lifetime_cases(args, report, host, endpoint, {}, "main-session", config)),
                    (("UNIT-LATER",), later),
                ))
            self.assertEqual(endpoint.request.call_count, 2)
            self.assertEqual(report.details["sessionAbandonment"]["completionOutcome"], "UNKNOWN")
            self.assertEqual(report.cases[-1]["status"], "BLOCKED")
            host.stop.assert_not_called()
            restart.assert_not_called()
            later.assert_not_called()


if __name__ == "__main__":
    unittest.main(verbosity=2)
