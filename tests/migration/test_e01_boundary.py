"""Standard-library checks of E01 evidence code, never fake engine integration.

Run directly with the reviewed Python 3.14.5 interpreter and ``-I -B``. Canonical
contract examples below are parser fixtures; they do not count as live workflows.
"""
from __future__ import annotations

import copy
import importlib.util
import io
import json
from pathlib import Path
import tempfile
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

    def test_rejected_setup_saves_scoped_candidate_and_later_case_group_runs(self):
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
                             [("UNIT-SETUP", "BLOCKED"), ("UNIT-NEXT", "PASS")])
            path = root / "private-rejections/setup_rejected_24/playerA.json"
            diagnostic = boundary.strict_json(path.read_bytes())
            self.assertEqual(diagnostic["role"], "playerA")
            self.assertEqual(diagnostic["commandEnvelope"], command)
            self.assertEqual(diagnostic["requestBeforeSubmission"], request)
            self.assertEqual(diagnostic["authorizedViewBeforeSubmission"], view)
            self.assertEqual(diagnostic["publicResponse"]["httpStatus"], 422)
            self.assertEqual(diagnostic["publicResponse"]["body"], reply.body)
            self.assertEqual(diagnostic["publicResponse"]["rawSHA256"], boundary.sha256(reply.raw))
            self.assertEqual(report.artifacts[0]["path"], str(path))
            self.assertEqual(report.artifacts[0]["sha256"], boundary.sha256(path.read_bytes()))
            with self.assertRaisesRegex(boundary.BoundaryError, "authenticated role"):
                boundary.record_setup_rejection(client, request, view, command, reply, "playerB")
            self.assertEqual(len(report.artifacts), 1)

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
                self.assertTrue(all(0 < timeout <= 10 for timeout in transport.timeouts))

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
        boundary.secret_scan(boundary.json_bytes(payload))


if __name__ == "__main__":
    unittest.main(verbosity=2)
