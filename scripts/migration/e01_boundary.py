"""Bounded E01 evidence driver; no rules, host implementation, or private Core access.

Preflight uses only the standard library. Runtime phases must be invoked with the
packet's isolated interpreter, ``-I -B``, and explicit absolute paths. Captures are
proposals in ignored output, never automatically published canonical fixtures.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import http.client as http_client
import importlib
import importlib.metadata
import json
import math
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import threading
import time
from datetime import UTC, datetime
from urllib.parse import urlencode, urlsplit

CORE_COMMIT = "5f509724da25a2f6ded0c2739a8e7c84bdf59c91"
CONTRACT_VERSION = "44.3.33"
BUILD_ID = "warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a"
RESOURCE_COUNT = 3116
REQUEST_LIMIT = 16 * 1024 * 1024
RESPONSE_LIMIT = 64 * 1024 * 1024
MAX_SECONDS = 30 * 60
REQUEST_DEADLINE_SECONDS = 30
SOCKET_READ_CAP_SECONDS = 30
MAX_EXACT_INTEGER = 2**53 - 1
CASE_IDS = ("SOURCE-01", "FINITE-01", "MOVE-01", "MOVE-02", "RETRY-01", "STALE-01", "AUTH-01", "VIEW-01", "ERROR-01", "FIDELITY-01", "SCOPE-01", "LIFETIME-01")
SLUG = re.compile(r"^[A-Za-z0-9_-]+$")


class BoundaryError(RuntimeError):
    """A bounded proof failed with a credential-free diagnostic."""


class Blocked(BoundaryError):
    """An actual external prerequisite or canonical procedure is unavailable."""


class PortUnavailable(Blocked):
    """The client prelaunch bind probe cannot exclusively claim its loopback port."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise BoundaryError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, sort_keys=True, indent=2, ensure_ascii=True, allow_nan=False) + "\n").encode("utf-8")


def strict_json(data: bytes) -> object:
    def reject_constant(value: str) -> None:
        raise BoundaryError("Non-finite JSON number")

    def unique_pairs(pairs: list[tuple[str, object]]) -> dict:
        result = {}
        for key, value in pairs:
            require(key not in result, "Duplicate JSON object key")
            result[key] = value
        return result

    return json.loads(data.decode("utf-8"), parse_constant=reject_constant, object_pairs_hook=unique_pairs)


def object_field(value: object, key: str) -> dict:
    require(type(value) is dict and type(value.get(key)) is dict, f"Expected object field {key}")
    return value[key]


def string_field(value: object, key: str) -> str:
    require(type(value) is dict and type(value.get(key)) is str and bool(value[key]), f"Expected nonempty string field {key}")
    return value[key]


def int_field(value: object, key: str) -> int:
    require(type(value) is dict and type(value.get(key)) is int and 0 <= value[key] <= MAX_EXACT_INTEGER, f"Expected exact nonnegative integer field {key}")
    return value[key]


def no_reparse(path: Path) -> None:
    for part in (path, *path.parents):
        if part.exists():
            require(not part.is_symlink() and not part.is_junction(), "Reparse/symlink path is forbidden")


def absolute_path(value: str) -> Path:
    path = Path(value)
    require(path.is_absolute(), "All proof paths must be absolute")
    no_reparse(path)
    return path.resolve()


def beneath(path: Path, root: Path) -> bool:
    return path == root or root in path.parents


def member_path(root: Path, member: str) -> Path:
    require(type(member) is str and "\\" not in member and not member.startswith("/"), "Invalid inventory path")
    relative = Path(member)
    require(not relative.is_absolute() and all(part not in ("..", ".") for part in relative.parts), "Inventory path traversal")
    candidate = root.joinpath(relative)
    no_reparse(candidate)
    require(beneath(candidate.resolve(), root.resolve()), "Inventory member escapes root")
    return candidate


def secret_scan(data: bytes, secrets: tuple[str, ...] = ()) -> None:
    lowered = data.lower()
    require(not any(secret and secret.encode("utf-8") in data for secret in secrets), "REDACTION_REJECTED: credential value detected; output quarantined")
    require(not re.search(rb'"(?:authorization|gh_token|github_token|access_token|password)"\s*:', lowered), "REDACTION_REJECTED: credential field detected; output quarantined")
    require(not re.search(rb"\bbearer\s+(?:core-v2-dev-|gh[pousr]_|github_pat_|[a-z0-9_.-]{24,})", lowered), "REDACTION_REJECTED: credential header detected; output quarantined")
    require(not re.search(rb"core-v2-dev-(?:administrator|player-|coach-|delayed-|replay-)|gh[pousr]_[a-z0-9]{20,}|github_pat_[a-z0-9_]{20,}", lowered), "REDACTION_REJECTED: credential-shaped value detected; output quarantined")


def write_new(path: Path, data: bytes, secrets: tuple[str, ...] = ()) -> None:
    no_reparse(path)
    secret_scan(data, secrets)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as stream:
        stream.write(data)


class Report:
    def __init__(self, phase: str, output: Path):
        self.phase, self.output = phase, output
        self.cases: list[dict] = []
        self.artifacts: list[dict] = []
        self.secrets: tuple[str, ...] = ()
        self.details: dict = {}

    def case(self, case_id: str, status: str, expected: object, actual: object, artifacts: list[str] | None = None) -> None:
        self.cases.append({"id": case_id, "status": status, "expected": expected, "actual": actual, "artifacts": artifacts or []})

    def artifact(self, path: Path) -> None:
        data = path.read_bytes()
        secret_scan(data, self.secrets)
        self.artifacts.append({"path": str(path), "sha256": sha256(data), "bytes": len(data)})

    def payload(self) -> dict:
        statuses = [case["status"] for case in self.cases]
        success = {"preflight": "SOURCE_INVENTORY_PASS", "verify-runtime": "INSTALLED_RUNTIME_PASS", "capture": "LOCAL_HTTP_BOUNDARY_PASS", "audit": "EVIDENCE_AUDIT_PASS"}[self.phase]
        status = "FAIL" if "FAIL" in statuses else "BLOCKED" if "BLOCKED" in statuses else "NOT_RUN" if not statuses or "NOT_RUN" in statuses else success
        return {"schemaVersion": 1, "phase": self.phase, "status": status, "utc": datetime.now(UTC).isoformat(), "caseCounts": {"discovered": len(statuses), "executed": statuses.count("PASS") + statuses.count("FAIL"), "passed": statuses.count("PASS"), "failed": statuses.count("FAIL"), "blocked": statuses.count("BLOCKED"), "notRun": statuses.count("NOT_RUN")}, "cases": self.cases, "artifacts": self.artifacts, "redaction": {"status": "PASS", "policy": "credential values/fields and authorization-header patterns rejected before export; roles separated"}, **self.details}


def git(core: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(core), *args], capture_output=True, timeout=30, check=False)
    require(result.returncode == 0, "Read-only Git identity operation failed")
    return result.stdout.decode("utf-8").strip()


def preflight(args: argparse.Namespace, report: Report) -> None:
    core, fixture = args.core_root, args.fixture_root
    require(git(core, "rev-parse", "HEAD") == CORE_COMMIT, "Selected Core HEAD mismatch")
    require(not git(core, "status", "--porcelain", "--untracked-files=all"), "Core checkout is dirty")
    manifest_path = fixture / "manifest.json"
    manifest = strict_json(manifest_path.read_bytes())
    require(manifest["CoreCommit"] == CORE_COMMIT and manifest["ContractVersion"] == CONTRACT_VERSION and manifest["RuntimeBuildId"] == BUILD_ID, "Frozen inventory identity mismatch")
    members = manifest["SourceFiles"]
    require(len(members) == 127 and len({row["Path"] for row in members}) == 127, "Expected 127 unique frozen source members")
    for row in members:
        source = member_path(core, row["Path"])
        data = source.read_bytes()
        require(sha256(data) == row["SHA256"].lower(), "Frozen checkout-byte hash mismatch: " + row["Path"])
        require(git(core, "rev-parse", f"{CORE_COMMIT}:{row['Path']}") == row["GitBlob"], "Frozen Git blob mismatch")
        if row["Path"].startswith("contracts/"):
            require(member_path(fixture, row["Path"]).read_bytes() == data, "Canonical copy missing or changed: " + row["Path"])
    contract = strict_json((core / "contracts/manifest.json").read_bytes())
    require(contract["contract_version"] == CONTRACT_VERSION, "Contract manifest version mismatch")
    hashes = contract["file_sha256"]
    require(len(hashes) == 234, "Expected all 234 committed contract members")
    for member, expected in hashes.items():
        raw = member_path(core / "contracts", member).read_bytes()
        normalized = raw.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n").encode("utf-8")
        require(sha256(normalized) == expected, "Normalized canonical hash mismatch: " + member)
    conformance = strict_json((fixture / "contracts/examples/decisions/interaction-conformance.json").read_bytes())
    ids = [row["case_id"] for row in conformance["cases"]]
    require(len(ids) == len(set(ids)) == 98 and sorted(ids) == sorted(manifest["CanonicalInteractionCaseIds"]), "98 canonical case IDs mismatch")
    require(sum(item.startswith("finite:") for item in ids) == 73 and sum(item.startswith("nested:") for item in ids) == 1 and sum(item.startswith("parameterized:") for item in ids) == 24, "Canonical variant counts mismatch")
    report.details["identities"] = {"coreCommit": CORE_COMMIT, "contractVersion": CONTRACT_VERSION, "runtimeBuildId": BUILD_ID, "sourceInventorySHA256": sha256(manifest_path.read_bytes()), "sourceFileCount": 127, "normalizedContractHashesVerified": 234, "canonicalEnvelopeCount": 98, "scriptSHA256": sha256(Path(__file__).read_bytes()), "python": sys.version, "executable": sys.executable, "launcherSHA256": sha256(args.core_launcher.read_bytes())}
    report.case("SOURCE-01", "PASS", "Exact clean Core, 127 source members, 234 canonical hashes, 98 unique envelopes", report.details["identities"])


def verify_runtime(args: argparse.Namespace, report: Report) -> None:
    preflight(args, report)
    expected_env = Path(__file__).resolve().parents[2] / ".local/core-44.3.33"
    require(Path(sys.prefix).resolve() == expected_env.resolve(), "Runtime interpreter is outside the approved isolated environment")
    require(sys.version_info[:3] == (3, 14, 5) and sys.flags.isolated and sys.dont_write_bytecode, "Runtime requires Python 3.14.5 -I -B")
    core_package = importlib.import_module("warhammer40k_core")
    package_path = Path(core_package.__file__).resolve()
    require(beneath(package_path, expected_env.resolve()), "Core imported outside isolated installed environment")
    identity = importlib.import_module("warhammer40k_core.build_identity").verified_engine_build_identity()
    require(identity.build_id == BUILD_ID and identity.resource_count == RESOURCE_COUNT, "Installed runtime build/resource mismatch")
    modules = {}
    for name in ("orjson", "msgspec", "pydantic", "shapely", "numpy", "jsonschema", "referencing", "z3"):
        module = importlib.import_module(name)
        module_path = Path(module.__file__).resolve()
        require(beneath(module_path, expected_env.resolve()), "Dependency imported outside isolated environment: " + name)
        modules[name] = {"path": str(module_path), "loaded": True}
    inventory = sorted([{"name": item.metadata["Name"], "version": item.version} for item in importlib.metadata.distributions()], key=lambda item: item["name"].lower())
    report.details["runtime"] = {"prefix": str(expected_env), "packagePath": str(package_path), "buildId": identity.build_id, "resourceCount": identity.resource_count, "modules": modules, "installedDistributions": inventory}
    report.case("RUNTIME-01", "PASS", "Exact installed build + 3116 resources + isolated native imports", report.details["runtime"])


class Schemas:
    def __init__(self, fixture: Path):
        from jsonschema import Draft202012Validator
        from referencing import Registry, Resource
        from referencing.jsonschema import DRAFT202012

        self.validator_type = Draft202012Validator
        self.schemas = {}
        registry = Registry()  # No retrieve callback: unresolved references fail locally.
        for path in sorted((fixture / "contracts/schemas").glob("*.json")):
            payload = strict_json(path.read_bytes())
            Draft202012Validator.check_schema(payload)
            resource = Resource.from_contents(payload, default_specification=DRAFT202012)
            registry = registry.with_resource(payload["$id"], resource)
            self.schemas[path.name] = payload
        self.registry = registry

    def validate(self, name: str, payload: object) -> None:
        require(name in self.schemas, "Frozen local schema missing: " + name)
        errors = list(self.validator_type(self.schemas[name], registry=self.registry).iter_errors(payload))
        require(not errors, "JSON schema rejected payload: " + name)


def classify(status: int, body: object) -> str:
    require(type(status) is int and 100 <= status <= 599 and type(body) is dict, "Invalid status/object")
    if "error" in body:
        require(set(body) == {"schema_version", "error"} and body["schema_version"] == "error-envelope-v1", "Error envelope fields/schema mismatch")
        error = object_field(body, "error")
        require(set(error) == {"code", "message"}, "Unexpected error detail fields")
        string_field(error, "code")
        string_field(error, "message")
        require(status >= 400 and "accepted" not in body and "committed" not in body, "Mixed error/outcome envelope")
        return "uncommitted_invalid" if status == 422 and error["code"] == "proposal_invalid" else "error"
    if "accepted" in body or "committed" in body:
        require(type(body.get("accepted")) is bool and type(body.get("committed")) is bool, "Outcome flags missing/wrong type")
        require(not body["accepted"] or body["committed"], "Accepted uncommitted outcome is invalid")
        require(body.get("schema_version") == "session-command-outcome-v44-contract", "Outcome schema mismatch")
        string_field(body, "command_id")
        require(string_field(body, "operation") in ("start_session", "advance_session", "submit_finite_decision", "submit_parameterized_decision", "close_session"), "Unknown outcome operation")
        code = string_field(body, "outcome_code")
        session = object_field(body, "session")
        checkpoint = object_field(body, "checkpoint")
        int_field(session, "session_revision")
        int_field(checkpoint, "session_revision")
        string_field(session, "session_id")
        require(re.fullmatch(r"[0-9a-f]{64}", string_field(checkpoint, "projection_state_hash")) is not None, "Invalid checkpoint hash")
        string_field(checkpoint, "event_cursor")
        require(checkpoint.get("visibility_role") in ("player", "coach", "delayed_spectator", "administrator"), "Invalid checkpoint role")
        require("viewer_player_id" in checkpoint and (checkpoint["viewer_player_id"] is None or type(checkpoint["viewer_player_id"]) is str), "Invalid checkpoint viewer")
        for key in ("from_cursor", "to_cursor"):
            string_field(object_field(body, "event_range"), key)
        if body["accepted"]:
            require(status == 200 and code == "command_committed", "Accepted status/code mismatch")
            return "accepted"
        require(status == 422 and code in ("proposal_invalid", "rule_path_unsupported"), "Rejected outcome status/code mismatch")
        return "recorded_invalid" if body["committed"] else "uncommitted_invalid"
    return "payload"


class ScopeReducer:
    """Small deterministic evidence reducer, not an Unreal network implementation."""
    def __init__(self):
        self.generation = 0
        self.session = self.viewer = None
        self.revision = -1
        self.body = self.cursor = self.draft = None

    def switch(self, session: str, viewer: str) -> int:
        self.generation += 1
        self.session, self.viewer = session, viewer
        self.revision = -1
        self.body = self.cursor = self.draft = None
        return self.generation

    def accept(self, generation: int, revision: int, body: object, cursor: str) -> bool:
        if generation != self.generation or revision < self.revision:
            return False
        self.revision, self.body, self.cursor = revision, body, cursor
        return True


def credentials() -> dict[str, str | None]:
    access = importlib.import_module("warhammer40k_core.adapters.access_control")
    names = {"admin": "DEV_ADMIN_TOKEN", "playerA": "DEV_PLAYER_A_TOKEN", "playerB": "DEV_PLAYER_B_TOKEN", "coach": "DEV_COACH_A_TOKEN", "delayed": "DEV_SPECTATOR_TOKEN", "replay": "DEV_REPLAY_TOKEN"}
    return {**{role: getattr(access, name) for role, name in names.items()}, "missing": None, "invalid": "e01-invalid-disposable-principal"}


def child_environment() -> dict[str, str]:
    rejected = ("TOKEN", "SECRET", "PASSWORD", "PYTHONPATH", "PYTHONHOME", "PIP_", "UV_INDEX", "UV_EXTRA_INDEX", "UV_DEFAULT_INDEX")
    env = {key: value for key, value in os.environ.items() if not any(part in key.upper() for part in rejected)}
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return env


class Reply:
    def __init__(self, status: int, raw: bytes, elapsed: float, sent: int):
        self.status, self.raw, self.elapsed, self.sent = status, raw, elapsed, sent
        self.body = strict_json(raw)


class Endpoint:
    def __init__(self, tokens: dict[str, str | None], *, base_url: str | None = None):
        self.tokens, self.base_url = tokens, base_url
        self.metrics = {"requests": 0, "largestRequestBytes": 0, "largestResponseBytes": 0, "maxLatencySeconds": 0.0}
        self.started = time.monotonic()
        self.server = None
        if base_url is None:
            self.server = importlib.import_module("warhammer40k_core.adapters.server").AdapterGameServer()
        else:
            parsed = urlsplit(base_url)
            require(parsed.scheme == "http" and parsed.hostname == "127.0.0.1" and parsed.port and not parsed.username and parsed.path in ("", "/") and not parsed.query and not parsed.fragment, "Proof endpoint must be explicit positive loopback HTTP")
            self.port = parsed.port

    def request(self, method: str, path: str, role: str, body: object = None, query: dict | None = None, malformed: bool = False) -> Reply:
        require(time.monotonic() - self.started < MAX_SECONDS, "Endpoint proof exceeded 30 minute limit")
        require(path.startswith("/") and "?" not in path and "#" not in path, "Invalid public route")
        payload = b"{" if malformed else json_bytes(body) if body is not None else b""
        require(len(payload) <= REQUEST_LIMIT, "Request exceeds 16 MiB")
        token = self.tokens[role]
        authorization = None if token is None else "Bearer " + token
        start = time.monotonic()
        if self.server is not None:
            require(not malformed, "Malformed wire case requires real HTTP")
            response = self.server.handle(method=method, path=path, query=query, body=body, authorization=authorization)
            reply = Reply(response.status_code, json_bytes(response.payload), time.monotonic() - start, len(payload))
        else:
            connection = http_client.HTTPConnection("127.0.0.1", self.port, timeout=3)
            try:
                connection.connect()
                transport_socket = connection.sock
                remaining = REQUEST_DEADLINE_SECONDS - (time.monotonic() - start)
                require(remaining > 0, "Request exceeded 30 second deadline; completion unknown")
                transport_socket.settimeout(min(SOCKET_READ_CAP_SECONDS, remaining))
                headers = {"Content-Type": "application/json"}
                if authorization is not None:
                    headers["Authorization"] = authorization
                connection.request(method, path + ("?" + urlencode(query) if query else ""), body=payload if payload else None, headers=headers)
                remaining = REQUEST_DEADLINE_SECONDS - (time.monotonic() - start)
                require(remaining > 0, "Request exceeded 30 second deadline; completion unknown")
                transport_socket.settimeout(min(SOCKET_READ_CAP_SECONDS, remaining))
                response = connection.getresponse()
                length = response.getheader("Content-Length")
                declared_length = None if length is None else int(length)
                require(declared_length is None or 0 <= declared_length <= RESPONSE_LIMIT, "Invalid response length or response exceeds 64 MiB")
                chunks, total = [], 0
                # HTTPResponse.read1 closes its file (and the last reference to
                # an HTTP/1.0 socket) immediately at the declared body length.
                # Do not update a closed socket's timeout on the next iteration.
                while not response.isclosed():
                    remaining = REQUEST_DEADLINE_SECONDS - (time.monotonic() - start)
                    require(remaining > 0, "Request exceeded 30 second deadline; completion unknown")
                    transport_socket.settimeout(min(SOCKET_READ_CAP_SECONDS, remaining))
                    chunk = response.read1(min(65536, RESPONSE_LIMIT - total + 1))
                    if not chunk:
                        break
                    chunks.append(chunk)
                    total += len(chunk)
                    require(total <= RESPONSE_LIMIT, "Response exceeds 64 MiB; completion unknown")
                require(declared_length is None or total == declared_length, "Truncated declared response body; completion unknown")
                reply = Reply(response.status, b"".join(chunks), time.monotonic() - start, len(payload))
                require(reply.elapsed <= REQUEST_DEADLINE_SECONDS, "Request exceeded 30 second total deadline")
            finally:
                connection.close()
        self.metrics["requests"] += 1
        self.metrics["largestRequestBytes"] = max(self.metrics["largestRequestBytes"], reply.sent)
        self.metrics["largestResponseBytes"] = max(self.metrics["largestResponseBytes"], len(reply.raw))
        self.metrics["maxLatencySeconds"] = max(self.metrics["maxLatencySeconds"], reply.elapsed)
        return reply


def require_available_loopback_port(port: int) -> None:
    """Probe before launch; never attach to or alter an existing listener.

    Windows SO_REUSEADDR allows a second development host to co-bind. Set
    SO_EXCLUSIVEADDRUSE before this probe's bind, as Microsoft documents at
    https://learn.microsoft.com/en-us/windows/win32/winsock/using-so-reuseaddr-and-so-exclusiveaddruse
    The probe closes before launching the unchanged Core host; it does not
    establish exclusive ownership against a later co-bind to that host.
    """
    require(type(port) is int and 0 < port <= 65535, "Prelaunch probe requires an explicit positive port")
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.settimeout(3)
        if sys.platform == "win32":
            require(hasattr(socket, "SO_EXCLUSIVEADDRUSE"), "Windows exclusive-address socket option unavailable")
            probe.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        try:
            probe.bind(("127.0.0.1", port))
        except OSError as exc:
            raise PortUnavailable("Loopback port unavailable to client prelaunch bind probe; no host was launched") from exc


class OwnedHost:
    """Own one selected development-host child and its shutdown marker/handle."""
    def __init__(self, args: argparse.Namespace, report: Report, tokens: dict, name: str):
        self.args, self.report, self.tokens = args, report, tokens
        self.root = args.output_root / name
        self.root.mkdir(exist_ok=False)
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            self.port = probe.getsockname()[1]
        self.shutdown = self.root / "shutdown"
        self.process = None
        self.log = None
        self.timer = None
        self.record = {"owner": name, "port": self.port, "maximumSeconds": MAX_SECONDS, "launcherSHA256": sha256(args.core_launcher.read_bytes()), "executable": sys.executable, "portSafetyLimit": "Client prelaunch availability probe only; selected Core development host does not ensure Windows late co-bind exclusivity"}
        self.lock = threading.Lock()

    def start(self) -> Endpoint:
        require_available_loopback_port(self.port)
        self.record["prelaunchPortProbe"] = "PASS: Windows exclusive-address bind" if sys.platform == "win32" else "PASS: loopback bind"
        self.log = (self.root / "host.log").open("xb")
        command = [sys.executable, "-I", "-B", str(self.args.core_launcher), "--host", "127.0.0.1", "--port", str(self.port), "--shutdown-file", str(self.shutdown)]
        self.record.update({"command": command, "startUTC": datetime.now(UTC).isoformat()})
        self.process = subprocess.Popen(command, cwd=self.root, env=child_environment(), stdout=self.log, stderr=subprocess.STDOUT, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        self.record["pid"] = self.process.pid
        self.timer = threading.Timer(MAX_SECONDS, lambda: self.stop(timed_out=True))
        self.timer.daemon = True
        self.timer.start()
        endpoint = Endpoint(self.tokens, base_url=f"http://127.0.0.1:{self.port}")
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            require(self.process.poll() is None, "Owned host exited before readiness; inspect quarantined owned log")
            # The selected launcher flushes this exact line only after its
            # create_http_server call has bound the socket. A catalog response
            # alone could come from a process that won the released-port race.
            marker = owned_bind_marker(self.root / "host.log", self.port)
            if marker is None:
                time.sleep(0.1)
                continue
            require(self.process.poll() is None, "Owned host exited after bind marker")
            try:
                ready = endpoint.request("GET", "/rules-catalog", "admin")
                require(ready.status == 200, "Owned host authenticated catalog readiness failed")
                require(self.process.poll() is None, "Unexpected responder after owned child exit")
                self.record["observedBindMarker"] = marker
                self.record["readyUTC"] = datetime.now(UTC).isoformat()
                return endpoint
            except (ConnectionError, TimeoutError, OSError, http_client.HTTPException):
                time.sleep(0.1)
        raise Blocked("Owned host readiness exceeded 30 seconds")

    def stop(self, *, timed_out: bool = False) -> None:
        with self.lock:
            if timed_out:
                self.record["timedOut"] = True
            if self.timer is not None:
                self.timer.cancel()
            if self.process is not None and self.process.poll() is None:
                self.shutdown.touch(exist_ok=False)
                try:
                    self.process.wait(timeout=10)
                    self.record["shutdown"] = "owned-marker"
                except subprocess.TimeoutExpired:
                    # Popen retains the original process handle; no PID/port/name lookup.
                    self.process.terminate()
                    try:
                        self.process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        self.process.kill()
                        self.process.wait(timeout=10)
                    self.record["shutdown"] = "owned-process-handle-fallback"
            if self.process is not None:
                self.record["exitCode"] = self.process.returncode
                self.record["exitUTC"] = datetime.now(UTC).isoformat()
            if self.log is not None:
                self.log.close()
                self.log = None
            self.report.details.setdefault("processes", [])
            if self.record not in self.report.details["processes"]:
                self.report.details["processes"].append(self.record)


def owned_bind_marker(log_path: Path, port: int) -> str | None:
    """Read only this child's unique log; no endpoint can supply bind evidence."""
    expected = f"Serving Phase 18M reference contract at http://127.0.0.1:{port}"
    with log_path.open("rb") as stream:
        data = stream.read(65537)
    require(len(data) <= 65536, "Owned host startup log exceeded 64 KiB bound")
    for line in data.splitlines():
        if line == expected.encode("utf-8"):
            return line.decode("utf-8")
    return None


class Captures:
    def __init__(self, args: argparse.Namespace, report: Report, schemas: Schemas):
        self.root, self.report, self.schemas = args.output_root / "proposed-wire", report, schemas
        self.entries: list[dict] = []

    def add(self, case_id: str, role: str, kind: str, reply: Reply, recipe: str, expected: str | None = None) -> str:
        slug = case_id.lower().replace(":", "_").replace(".", "_")
        require(SLUG.fullmatch(slug) is not None and SLUG.fullmatch(role) is not None, "Unsafe capture slug")
        outcome = classify(reply.status, reply.body)
        if expected is not None:
            require(outcome == expected, "Actual wire outcome differs: " + case_id)
        if "error" in reply.body:
            self.schemas.validate("error-envelope.schema.json", reply.body)
        elif outcome in ("accepted", "recorded_invalid", "uncommitted_invalid"):
            self.schemas.validate("session-command-outcome.schema.json", reply.body)
        relative = f"{slug}/{role}.json"
        require(not any(entry["path"] == relative for entry in self.entries), "Duplicate proposed capture")
        privileged = role == "admin"
        path = (self.report.output / "privileged-wire" if privileged else self.root) / relative
        # The original body bytes preserve opaque IDs, order, JSON types and wire error text.
        write_new(path, reply.raw, self.report.secrets)
        self.report.artifact(path)
        if not privileged:
            self.entries.append({"case_id": case_id, "role": role, "kind": kind, "recipe": recipe, "path": relative, "sha256": sha256(reply.raw), "http_status": reply.status, "expected_outcome": outcome})
        return str(path)

    def finish(self) -> None:
        path = self.root / "index.json"
        write_new(path, json_bytes({"format_version": 1, "cases": self.entries}), self.report.secrets)
        self.report.artifact(path)


def envelope(session: str, command: str, revision: int, kind: str, request: dict | None = None, *, option: str | None = None, payload: object = None) -> dict:
    submission = {"submission_kind": kind}
    if option is not None:
        submission["option_id"] = option
    if kind == "parameterized_payload":
        submission["payload"] = payload
    return {"schema_version": "session-command-envelope-v2-weapon-instances", "command_id": command, "session_id": session, "expected_session_revision": revision, "request_id": None if request is None else string_field(request, "request_id"), "result_id": None if request is None else command + "-result", "submission": submission}


def role_for_actor(request: dict) -> str:
    actor = string_field(request, "actor_id")
    require(actor in ("player-a", "player-b"), "Canonical actor is not an explicitly bound proof player")
    return "playerA" if actor == "player-a" else "playerB"


def projection_body(reply: Reply) -> dict:
    require(reply.status == 200, "Authorized projection unavailable")
    return object_field(reply.body, "projection")


def operational_normalize(value: object) -> object:
    """Comparison only; original captures/hashes are never rewritten."""
    if type(value) is list:
        return [operational_normalize(item) for item in value]
    if type(value) is dict:
        return {key: "<operational>" if key in {"created_at", "last_activity_at", "event_cursor", "from_cursor", "to_cursor", "cursor", "next_cursor", "supplied_cursor"} and item is not None else operational_normalize(item) for key, item in value.items()}
    return value


class Pair:
    def __init__(self, local: Endpoint, http: Endpoint, captures: Captures):
        self.local, self.http, self.captures = local, http, captures
        self.session = ""
        self.submissions = 0
        self.trace: list[dict] = []
        self.initial_cursors: dict[str, tuple[str, str]] = {}
        self.army_by_player: dict[str, str] = {}

    def request(self, method: str, path: str, role: str, body: object = None, query: dict | None = None) -> tuple[Reply, Reply]:
        local = self.local.request(method, path, role, body, query)
        http = self.http.request(method, path, role, body, query)
        require(local.status == http.status and operational_normalize(local.body) == operational_normalize(http.body), "Local/HTTP authorized boundary comparison differs")
        self.trace.append({"method": method, "path": path, "role": role, "status": http.status, "requestSHA256": sha256(json_bytes(body)), "responseSHA256": sha256(http.raw)})
        return local, http

    def metadata(self, role: str = "playerA") -> dict:
        return self.request("GET", f"/sessions/{self.session}", role)[1].body

    def view(self, role: str) -> dict:
        return projection_body(self.request("GET", f"/sessions/{self.session}/projection", role)[1])

    def pending(self) -> tuple[dict, dict]:
        # Each bound player is read explicitly. Hidden actor IDs/options are not inferred.
        for role in ("playerA", "playerB"):
            view = self.view(role)
            request = view.get("pending_decision")
            if request is not None and request.get("decision_type") != "hidden_decision":
                require(type(request) is dict, "Pending request is not an object")
                # A public choice can be visible to both players. Submit only from
                # the actor's separately authenticated view, never the observer's.
                if role_for_actor(request) == role:
                    return request, view
        raise Blocked("Canonical public setup exposes no bound-player decision")

    def events(self, role: str, cursors: tuple[str, str]) -> tuple[Reply, Reply]:
        path = f"/sessions/{self.session}/events"
        local = self.local.request("GET", path, role, query={"cursor": cursors[0], "limit": "100"})
        http = self.http.request("GET", path, role, query={"cursor": cursors[1], "limit": "100"})
        require(local.status == http.status == 200 and operational_normalize(local.body) == operational_normalize(http.body), "Local/HTTP scoped event page differs")
        return local, http

    def submit(self, command: dict, role: str) -> tuple[Reply, Reply]:
        self.captures.schemas.validate("session-command-envelope.schema.json", command)
        self.submissions += 1
        require(self.submissions <= 256, "Canonical scenario exceeded 256 submissions")
        return self.request("POST", f"/sessions/{self.session}/commands", role, command)

    def intent(self, request: dict, *, option: str | None = None, payload: object = None, label: str = "choice") -> dict:
        if option is not None:
            require(option in [row["option_id"] for row in request["options"]], "Canonical recipe selected an option not offered by Core")
        revision = int_field(self.metadata(role_for_actor(request)), "session_revision")
        return envelope(self.session, f"e01-{label}-{request['request_id']}", revision, "finite_option" if option is not None else "parameterized_payload", request, option=option, payload=payload)


def public_models(view: dict) -> dict:
    return object_field(object_field(object_field(view, "battlefield_view"), "authoritative"), "models_by_id")


def proposal_pose(projected: dict) -> dict:
    position = object_field(projected, "position")
    return {"position": {"x": position["x_inches"], "y": position["y_inches"], "z": position["z_inches"]}, "facing": {"degrees": projected["facing_degrees"]}}


def deployment_payload(proposal: dict, view: dict, army_by_player: dict[str, str]) -> dict:
    """Fixed source recipe candidate; only Core decides legality."""
    player = string_field(proposal, "player_id")
    unit = string_field(proposal, "unit_instance_id")
    # Legacy public smoke's fixed deployment candidate, not a placement solver.
    slot_by_unit = {"army-alpha:scout-redeploy-unit": 0, "army-beta:scout-redeploy-unit": 0, "army-alpha:strategic-reserve-unit": 1, "army-alpha:deep-strike-unit": 2}
    require(unit in slot_by_unit, "No reviewed canonical placement candidate for unit")
    slot = slot_by_unit[unit]
    models = public_models(view)
    placements = []
    for index, model_id in enumerate(proposal["model_instance_ids"]):
        model = models[model_id]
        require(model["owner_player_id"] == player and model["unit_instance_id"] in proposal["component_unit_instance_ids"], "Placement request/model inventory mismatch")
        if model["pose"] is not None:
            pose = proposal_pose(model["pose"])
        else:
            x = 40.0 - slot * 9.0 - (index // 3) * 1.8 if player == "player-b" else 4.0 + slot * 14.0 + (index // 3) * 1.8
            y = (8.0 if player == "player-b" else 51.0) + (index % 3) * 1.8
            pose = {"position": {"x": x, "y": y, "z": 0.0}, "facing": {"degrees": 180.0 if player == "player-b" else 0.0}}
        placements.append({"army_id": army_by_player[player], "player_id": player, "unit_instance_id": model["unit_instance_id"], "model_instance_id": model_id, "pose": pose})
    result = {"proposal_request_id": proposal["request_id"], "proposal_kind": proposal["proposal_kind"], "game_id": proposal["game_id"], "ruleset_descriptor_hash": proposal["ruleset_descriptor_hash"], "setup_step": proposal["setup_step"], "player_id": player, "unit_instance_id": unit, "placement_kind": proposal["placement_kind"], "model_placements": placements, "context": copy.deepcopy(proposal["context"])}
    if proposal["decision_type"] != "submit_deployment_placement":
        result["action_kind"] = proposal["action_kind"]
        result["source_rule_id"] = proposal["source_rule_id"]
    return result


def scout_payload(proposal: dict, view: dict) -> dict:
    models = public_models(view)
    paths = []
    for model_id in proposal["model_instance_ids"]:
        model = models[model_id]
        require(model["owner_player_id"] == proposal["player_id"] and model["unit_instance_id"] in proposal["component_unit_instance_ids"] and model["pose"] is not None, "Scout request/model inventory mismatch")
        poses = [proposal_pose(model["pose"]) for _ in range(3)]
        poses[1]["position"]["x"] += 0.5
        poses[2]["position"]["x"] += 1.0
        paths.append({"model_id": model_id, "poses": poses})
    require(bool(paths), "Empty Scout inventory")
    result = {key: copy.deepcopy(proposal[key]) for key in ("proposal_kind", "game_id", "ruleset_descriptor_hash", "setup_step", "player_id", "unit_instance_id", "action_kind", "source_rule_id", "scout_distance_inches", "context")}
    result.update({"proposal_request_id": proposal["request_id"], "witness": {"model_paths": leading_first_translation_candidate(paths, dx=1.0)}})
    return result


def leading_first_translation_candidate(paths: list[dict], *, dx: float, dy: float = 0.0) -> list[dict]:
    """Construct this proof's fixed uniform-translation fixture candidate.

    Selected Core 5f509724 tests/sequential_translation_helpers.py:12-20 uses
    this explicit leading-first order in its three-pose Scout/movement recipes.
    This is candidate construction, not a legality solver or an automatic
    production witness reorder. Core alone accepts/rejects the submitted order.
    Neither the original inventory list nor any path/pose is modified.
    """
    return sorted(paths, key=lambda row: (-(row["poses"][0]["position"]["x"] * dx + row["poses"][0]["position"]["y"] * dy), row["model_id"]))


def movement_payload(proposal: dict, view: dict, dx: float = 1.0) -> dict:
    unit_id = string_field(proposal, "unit_instance_id")
    models = public_models(view)
    living = {key for key, model in models.items() if model["rules_unit_instance_id"] == unit_id and model["state"] == "placed" and view["model_display_by_id"][key]["wounds_remaining"] > 0}
    ordered = [model for army in view["battlefield_state"]["placed_armies"] for unit in army["unit_placements"] for model in unit["model_placements"] if model["model_instance_id"] in living]
    require(len(ordered) == len(living) and bool(living), "Current living physical rules-unit inventory missing/ambiguous")
    paths = []
    for model in ordered:
        initial = copy.deepcopy(model["pose"])
        middle = copy.deepcopy(initial)
        middle["position"]["x"] += dx / 2.0
        final = copy.deepcopy(initial)
        final["position"]["x"] += dx
        paths.append({"model_id": model["model_instance_id"], "poses": [initial, middle, final]})
    require(bool(paths), "Empty canonical movement inventory")
    return {"proposal_request_id": proposal["request_id"], "proposal_kind": proposal["proposal_kind"], "unit_instance_id": unit_id, "movement_phase_action": "normal_move", "movement_mode": "normal", "witness": {"model_paths": leading_first_translation_candidate(paths, dx=dx)}}


def verify_requested_model_poses(before: dict, after: dict, witness: dict) -> dict:
    """Compare observed authoritative poses with submitted endpoints, not legality."""
    def indexed_poses(state: dict) -> dict:
        result = {}
        for army in state["placed_armies"]:
            for unit in army["unit_placements"]:
                for model in unit["model_placements"]:
                    model_id = string_field(model, "model_instance_id")
                    require(model_id not in result, "Duplicate authoritative physical model ID")
                    result[model_id] = object_field(model, "pose")
        return result

    def components(pose: dict) -> tuple:
        position, facing = object_field(pose, "position"), object_field(pose, "facing")
        values = (position["x"], position["y"], position["z"], facing["degrees"])
        require(all(type(value) in (int, float) and math.isfinite(value) for value in values), "Authoritative/requested pose has invalid numeric components")
        return values

    def equal(left: tuple, right: tuple) -> bool:
        return all(math.isclose(a, b, rel_tol=0.0, abs_tol=1e-9) for a, b in zip(left, right, strict=True))

    before_by_id, after_by_id = indexed_poses(before), indexed_poses(after)
    paths = witness["model_paths"]
    require(type(paths) is list and bool(paths), "Pose evidence requires a nonempty requested model inventory")
    seen, evidence, moved_count = set(), [], 0
    for path in paths:
        model_id = string_field(path, "model_id")
        require(model_id not in seen and model_id in before_by_id and model_id in after_by_id, "Requested physical model is duplicated or missing from authoritative before/after state")
        seen.add(model_id)
        require(type(path["poses"]) is list and len(path["poses"]) >= 2, "Pose evidence requires ordered initial/final endpoints")
        initial, final = path["poses"][0], path["poses"][-1]
        before_values, after_values = components(before_by_id[model_id]), components(after_by_id[model_id])
        require(equal(components(initial), before_values), "Requested initial pose differs from authoritative before pose")
        require(equal(components(final), after_values), "Requested final pose differs from authoritative after pose (including facing/Z)")
        xyz_changed = not equal(before_values[:3], after_values[:3])
        moved_count += int(xyz_changed)
        evidence.append({"modelId": model_id, "beforePose": copy.deepcopy(before_by_id[model_id]), "requestedInitialPose": copy.deepcopy(initial), "requestedFinalPose": copy.deepcopy(final), "afterPose": copy.deepcopy(after_by_id[model_id]), "xyzChanged": xyz_changed})
    require(moved_count > 0, "No authoritative requested-model XYZ position changed")
    return {"requestedModelCount": len(paths), "movedModelCount": moved_count, "positionChange": moved_count > 0, "numericAbsoluteTolerance": 1e-9, "poseEvidence": evidence}


def scope_case(report: Report) -> None:
    reducer = ScopeReducer()
    old = reducer.switch("session-one", "playerA")
    require(reducer.accept(old, 5, {"visible": "A"}, "cursor-A"), "Initial reducer update failed")
    reducer.draft = {"advisory": True}
    new = reducer.switch("session-one", "playerB")
    require(reducer.body is reducer.cursor is reducer.draft is None, "Viewer switch retained scoped data")
    require(not reducer.accept(old, 6, {"visible": "A"}, "cursor-A"), "Stale viewer callback accepted")
    require(reducer.accept(new, 7, {"visible": "B"}, "cursor-B"), "Fresh viewer callback rejected")
    require(not reducer.accept(new, 6, {"visible": "old-B"}, "old-cursor"), "Journal retry rolled displayed revision backward")
    newer = reducer.switch("session-two", "playerB")
    require(newer != new and not reducer.accept(new, 8, {"visible": "old-session"}, "old-cursor"), "Stale session callback accepted")
    report.case("SCOPE-01", "PASS", "Switch invalidates drafts/cursors and rejects older generations/revisions", "Deterministic client reducer assertions passed; actual UE scheduling NOT RUN")


def assert_error(reply: Reply, status: int, code: str | None = None) -> None:
    require(reply.status == status and classify(reply.status, reply.body) in ("error", "uncommitted_invalid"), "Expected actual typed error")
    if code is not None:
        require(reply.body["error"]["code"] == code, "Actual error code differs from public contract")


def fidelity_observation(reply: Reply) -> dict:
    require(reply.status == 422 and classify(reply.status, reply.body) == "uncommitted_invalid", "Fidelity evidence requires an actual uncommitted 422 response")
    error = object_field(reply.body, "error")
    return {"httpStatus": reply.status, "code": string_field(error, "code"), "message": string_field(error, "message"), "responseSHA256": sha256(reply.raw)}


def auth_and_views(pair: Pair, report: Report) -> None:
    request, view = pair.pending()
    role = role_for_actor(request)
    option = request["options"][0]["option_id"]
    command = pair.intent(request, option=option, label="auth-denial")
    references = {}
    for denied in ("missing", "invalid", "coach", "delayed", "admin", "replay", "playerB" if role == "playerA" else "playerA"):
        _, reply = pair.submit(command, denied)
        if denied in ("playerA", "playerB"):
            require(reply.status in (403, 409) and classify(reply.status, reply.body) == "error", "Wrong bound player was not rejected with actual scoped error")
        else:
            assert_error(reply, 401 if denied in ("missing", "invalid") else 403)
        require(set(reply.body) == {"schema_version", "error"}, "Auth response leaked extra fields")
        forbidden = json_bytes(reply.body)
        require(request["request_id"].encode() not in forbidden and not any(row["option_id"].encode() in forbidden for row in request["options"]), "Auth response leaked hidden request/options")
        path = pair.captures.add("auth_" + denied, denied, "http", reply, "Current public offered finite envelope submitted with distinct denied credential scope", "error")
        references[denied] = path
    _, forged = pair.request("GET", f"/sessions/{pair.session}/projection", role, query={"viewer_player_id": "player-b" if role == "playerA" else "player-a"})
    assert_error(forged, 403)
    pair.captures.add("auth_forged_viewer", role, "http", forged, "Forged viewer_player_id under bound-player credential", "error")
    report.case("AUTH-01", "PASS", "All distinct denied credential contexts share scoped errors without hidden request/options", references)
    views = {}
    for lane in ("playerA", "playerB", "coach", "delayed", "admin"):
        _, reply = pair.request("GET", f"/sessions/{pair.session}/projection", lane)
        pair.captures.schemas.validate("session-projection.schema.json", reply.body)
        views[lane] = reply.body
        pair.captures.add("view_initial", lane, "http", reply, "Explicit role-scoped projection; admin fixture remains privileged", "payload")
    _, replay = pair.request("GET", f"/sessions/{pair.session}/projection", "replay")
    assert_error(replay, 403)
    pair.captures.add("view_replay_live_denied", "replay", "http", replay, "Replay viewer forbidden live projection", "error")
    # Exact policy is returned by the server, including one-revision delay.
    delayed_metadata = pair.metadata("delayed")
    delayed_visibility = object_field(delayed_metadata, "visibility")
    require(delayed_visibility.get("delay_revisions") == 1, "Delayed spectator policy did not declare one revision")
    current_revision = pair.metadata("admin")["session_revision"]
    require(delayed_metadata["session_revision"] == views["delayed"]["session_revision"] == max(0, current_revision - 1), "Spectator did not receive server-owned one-revision snapshot")
    for lane in ("playerA", "playerB"):
        pending = views[lane]["projection"]["pending_decision"]
        if lane != role and pending is not None:
            require(pending["decision_type"] == "hidden_decision" and pending["options"] == [], "Opponent view exposed hidden options")
    for lane in ("playerA", "playerB", "coach", "delayed"):
        cursors = pair.initial_cursors[lane]
        for page in range(8):
            local_page, reply = pair.events(lane, cursors)
            pair.captures.schemas.validate("event-delta.schema.json", reply.body)
            require(len(reply.body["events"]) <= 100 and not reply.body["resync_required"], "Scoped event page invalid or exceeded cap")
            pair.captures.add(f"events_{page}", lane, "http", reply, "Server-scoped event cursor, at most eight pages of 100", "payload")
            cursors = (local_page.body["next_cursor"], reply.body["next_cursor"])
            if not reply.body["has_more"]:
                break
        else:
            raise BoundaryError("Scoped events exceeded eight pages")
    foreign = pair.http.request("GET", f"/sessions/{pair.session}/events", "playerB", query={"cursor": pair.initial_cursors["playerA"][1], "limit": "100"})
    require(foreign.status == 200 and foreign.body["resync_required"] and foreign.body["resync_reason"] == "wrong_viewer" and foreign.body["events"] == [], "Foreign viewer cursor leaked events or failed scoped resync")
    pair.captures.add("events_wrong_viewer_cursor", "playerB", "http", foreign, "PlayerA cursor rejected by server under PlayerB credential", "payload")
    report.case("VIEW-01", "PASS", "Explicit role projections/events; delayed snapshot; replay live denial and scoped cursors", "Local/HTTP scoped views match; privileged captures segregated")
    report.details["excludedCases"] = [{"id": "VIEW-TERMINAL-REPLAY", "status": "NOT_RUN", "reason": "No reviewed canonical terminal completion procedure in this bounded subset; no private terminal mutation"}]


def finite_and_retry(pair: Pair, report: Report) -> None:
    request, _ = pair.pending()
    role = role_for_actor(request)
    options = [row["option_id"] for row in request["options"]]
    selected = "fixed:assassination:bring_it_down" if "fixed:assassination:bring_it_down" in options else options[0]
    command = pair.intent(request, option=selected, label="finite")
    stale = copy.deepcopy(command)
    stale["command_id"] += "-stale"
    stale["expected_session_revision"] += 99
    _, rejected = pair.submit(stale, role)
    assert_error(rejected, 409, "session_revision_conflict")
    pair.captures.add("stale_wrong_revision", role, "http", rejected, "Wrong expected revision preserves complete envelope", "error")
    waiting = envelope(pair.session, "e01-waiting-advance", command["expected_session_revision"], "advance_session")
    _, blocked = pair.submit(waiting, "admin")
    assert_error(blocked, 409, "advance_not_required")
    pair.captures.add("stale_waiting_advance", "admin", "http", blocked, "Admin advance while waiting for offered player choice", "error")
    before = pair.metadata(role)
    _, first = pair.submit(command, role)
    require(classify(first.status, first.body) == "accepted", "Finite offered choice was not accepted")
    pair.captures.add("finite_accepted", role, "http", first, "Canonical visible finite request; exact offered option under bound player", "accepted")
    after = pair.metadata(role)
    require(after["session_revision"] == before["session_revision"] + 1, "Finite choice did not apply once")
    # Deliberately discard one real committed response; retain same envelope and role.
    lost_response = first.raw
    _, retry = pair.submit(command, role)
    require(retry.raw == lost_response and pair.metadata(role)["session_revision"] == after["session_revision"], "Exact same-ID retry was not byte-equivalent/apply-once")
    conflict = copy.deepcopy(command)
    conflict["result_id"] += "-changed"
    _, changed = pair.submit(conflict, role)
    assert_error(changed, 409, "command_id_conflict")
    pair.captures.add("retry_changed_envelope", role, "http", changed, "Same ID with changed result identity conflicts", "error")
    consumed = copy.deepcopy(command)
    consumed["command_id"] += "-consumed"
    consumed["expected_session_revision"] = after["session_revision"]
    _, stale_request = pair.submit(consumed, role)
    require(stale_request.status in (403, 409), "Consumed request did not produce typed rejection")
    require(classify(stale_request.status, stale_request.body) == "error", "Consumed request missing typed error")
    pair.captures.add("stale_consumed_request", role, "http", stale_request, "Consumed request with new ID and refreshed expected revision", "error")
    report.case("FINITE-01", "PASS", "Offered finite action applies once and refreshed authorized local/HTTP state agrees", {"requestId": request["request_id"], "optionId": selected, "commandId": command["command_id"], "revisionBefore": before["session_revision"], "revisionAfter": after["session_revision"]})
    report.case("RETRY-01", "PASS", "Same complete envelope/credential bytes; changed envelope conflicts; no display rollback", {"injectedResponseLoss": True, "retryBytesSHA256": sha256(retry.raw), "sameRevision": after["session_revision"], "displayRollbackProof": "SCOPE-01"})
    report.case("STALE-01", "PASS", "Wrong revision, consumed request and waiting advance typed errors", {"wrongRevision": rejected.body, "consumedRequest": stale_request.body, "waitingAdvance": blocked.body})


def authorized_candidate_snapshot(request: dict, view: dict, command: dict, role: str) -> dict:
    """Full candidate data is permitted only in its actor's authorized lane."""
    require(SLUG.fullmatch(role) is not None, "Unsafe rejection diagnostic role")
    require(role == role_for_actor(request), "Full rejection diagnostic requires the request actor's authenticated role")
    require(string_field(view, "viewer_player_id") == string_field(request, "actor_id"), "Full rejection diagnostic viewer does not own the request")
    visible = object_field(view, "pending_decision")
    require(string_field(visible, "request_id") == string_field(request, "request_id") and string_field(visible, "actor_id") == string_field(request, "actor_id") and command.get("request_id") == request["request_id"], "Full rejection diagnostic command/request is outside the authorized current view")
    return {"schemaVersion": 1, "role": role, "commandEnvelope": copy.deepcopy(command), "requestBeforeSubmission": copy.deepcopy(request), "proposalBeforeSubmission": copy.deepcopy(view.get("pending_proposal")), "authorizedViewBeforeSubmission": copy.deepcopy(view)}


def record_authorized_attempt(pair: Pair, request: dict, view: dict, command: dict, role: str) -> str:
    """Freeze actor-scoped input before a request can finish with unknown outcome."""
    snapshot = authorized_candidate_snapshot(request, view, command, role)
    report = pair.captures.report
    path = report.output / "private-attempts" / ("command_" + str(pair.submissions + 1)) / (role + ".json")
    write_new(path, json_bytes({**snapshot, "observation": "Prepared candidate captured before submission; no completion outcome asserted"}), report.secrets)
    report.artifact(path)
    return str(path)


def record_setup_rejection(pair: Pair, request: dict, view: dict, command: dict, reply: Reply, role: str) -> str:
    """Retain the actual scoped candidate before leaving its unavailable lane."""
    snapshot = authorized_candidate_snapshot(request, view, command, role)
    slug = "setup_rejected_" + str(pair.submissions)
    wire = pair.captures.add(slug, role, "http", reply, "Actual public response to reviewed fixed setup candidate; cause requires candidate/response inspection")
    report = pair.captures.report
    diagnostic = report.output / "private-rejections" / slug / (role + ".json")
    payload = {**snapshot, "publicResponse": {"httpStatus": reply.status, "body": copy.deepcopy(reply.body), "rawSHA256": sha256(reply.raw), "wireArtifact": wire}, "disposition": "Reviewed candidate rejected; preserve observed input/output before assigning cause"}
    write_new(diagnostic, json_bytes(payload), report.secrets)
    report.artifact(diagnostic)
    return str(diagnostic)


def canonical_reserve_option(request: dict) -> str:
    """Selected Core setup-smoke fixture choices, only when actually offered."""
    require(request["decision_type"] == "select_reserve_declaration", "Reserve recipe received another decision type")
    offered = [string_field(row, "option_id") for row in request["options"]]
    # Core 5f509724 tests/integration/test_setup_prebattle_ui_smoke.py:80-109
    # declares these reserves before deploying the two Scout infantry units.
    for option in ("declare_strategic_reserves:army-alpha:strategic-reserve-unit", "declare_deep_strike:army-alpha:deep-strike-unit", "complete_reserve_declarations"):
        if option in offered:
            return option
    raise Blocked("No reviewed canonical reserve choice is currently offered")


def setup_to_move(pair: Pair) -> tuple[dict, dict]:
    for _ in range(256):
        request, view = pair.pending()
        kind = request["decision_type"]
        role = role_for_actor(request)
        if kind == "submit_movement_proposal":
            require(view["pending_proposal"]["proposal_kind"] == "normal_move", "Canonical movement recipe reached another proposal kind")
            return request, view
        if kind in ("submit_deployment_placement", "submit_redeploy_placement"):
            command = pair.intent(request, payload=deployment_payload(view["pending_proposal"], view, pair.army_by_player), label="deploy")
        elif kind == "submit_scout_move":
            command = pair.intent(request, payload=scout_payload(view["pending_proposal"], view), label="scout")
        else:
            options = [row["option_id"] for row in request["options"]]
            if kind == "select_secondary_missions":
                selected = "fixed:assassination:bring_it_down"
            elif kind == "select_movement_action":
                selected = "normal_move"
            elif kind == "select_reserve_declaration":
                selected = canonical_reserve_option(request)
            elif kind == "select_deployment_unit":
                candidates = ("deploy:army-beta:scout-redeploy-unit", "deploy:army-alpha:deep-strike-unit", "deploy:army-alpha:scout-redeploy-unit", "deploy:army-alpha:strategic-reserve-unit")
                selected = next((item for item in candidates if item in options), "")
            elif kind == "select_redeploy_unit":
                selected = "redeploy:" + ("army-alpha" if request["actor_id"] == "player-a" else "army-beta") + ":scout-redeploy-unit"
            elif kind == "select_prebattle_action":
                selected = "scout_move:" + ("army-alpha" if request["actor_id"] == "player-a" else "army-beta") + ":scout-redeploy-unit"
            elif kind == "use_stratagem":
                selected = "decline_stratagem_window"
            elif kind == "select_movement_unit":
                selected = ("army-alpha" if request["actor_id"] == "player-a" else "army-beta") + ":scout-redeploy-unit"
            else:
                raise Blocked("No reviewed public setup recipe for current decision type: " + kind)
            command = pair.intent(request, option=selected, label="setup")
        record_authorized_attempt(pair, request, view, command, role)
        _, reply = pair.submit(command, role)
        if classify(reply.status, reply.body) != "accepted":
            diagnostic = record_setup_rejection(pair, request, view, command, reply, role)
            raise Blocked("Reviewed public setup candidate was rejected; inspect actual candidate/response before assigning cause: " + diagnostic)
    raise BoundaryError("Canonical setup exceeded 256 offered submissions")


def movement_cases(pair: Pair, report: Report) -> None:
    request, view = setup_to_move(pair)
    role = role_for_actor(request)
    proposal = view["pending_proposal"]
    payload = movement_payload(proposal, view)
    before = pair.metadata(role)
    before_projection = copy.deepcopy(view)
    pair.captures.add("movement_before", role, "http", pair.request("GET", f"/sessions/{pair.session}/projection", role)[1], "Authorized current complete movement projection before any negative/positive submissions", "payload")
    # Public admin replay is confined to privileged lane and never copied into player fixtures.
    replay_before = pair.request("GET", f"/sessions/{pair.session}/replay", "admin")[1]
    require(replay_before.status == 200, "Explicit admin history export unavailable")
    history_count = len(replay_before.body["decision_records"])
    fidelity_responses = []
    fidelity_artifacts = []
    for label in ("missing", "duplicate", "wrong"):
        invalid = copy.deepcopy(payload)
        paths = invalid["witness"]["model_paths"]
        if label == "missing":
            paths.pop()
        elif label == "duplicate":
            paths.append(copy.deepcopy(paths[0]))
        else:
            paths[0]["model_id"] = "e01:unknown-physical-model"
        command = pair.intent(request, payload=invalid, label="inventory-" + label)
        record_authorized_attempt(pair, request, view, command, role)
        _, reply = pair.submit(command, role)
        assert_error(reply, 422, "proposal_invalid")
        fidelity_artifacts.append(pair.captures.add("movement_inventory_" + label, role, "http", reply, "Current complete normal-move witness changed only by explicit negative inventory operation", "uncommitted_invalid"))
        fidelity_responses.append(fidelity_observation(reply))
        current = pair.metadata(role)
        require(current["session_revision"] == before["session_revision"] and pair.view(role) == before_projection, "Uncommitted inventory failure changed scoped state/request")
        replay = pair.request("GET", f"/sessions/{pair.session}/replay", "admin")[1]
        require(len(replay.body["decision_records"]) == history_count, "Uncommitted inventory failure recorded history")
    require(len(fidelity_responses) == 3, "Fidelity observations missing a live inventory rejection")
    report.case("FIDELITY-01", "PASS", "Exact wire status/code/message; Core issue #588 fidelity gap explicit", {"responses": fidelity_responses, "displayNotice": "Detailed engine reasons were not supplied by this HTTP response.", "issue": "https://github.com/SobolGaming/Warhammer_40k_AI/issues/588"}, fidelity_artifacts)
    invalid_geometry = movement_payload(proposal, view, 1000.0)
    command = pair.intent(request, payload=invalid_geometry, label="invalid-distance")
    record_authorized_attempt(pair, request, view, command, role)
    _, reply = pair.submit(command, role)
    require(classify(reply.status, reply.body) == "recorded_invalid", "Well-formed geometric candidate did not exercise recorded-invalid branch")
    pair.captures.add("movement_recorded_invalid", role, "http", reply, "Well-formed ordered complete witness with 1000-inch candidate; only Core validates geometry", "recorded_invalid")
    require(pair.metadata(role)["session_revision"] == before["session_revision"] + 1, "Recorded invalid did not commit revision")
    replay = pair.request("GET", f"/sessions/{pair.session}/replay", "admin")[1]
    require(len(replay.body["decision_records"]) == history_count + 1, "Recorded invalid did not record history")
    request2, view2 = pair.pending()
    require(request2["request_id"] != request["request_id"] and request2["decision_type"] == request["decision_type"], "Recorded invalid did not expose fresh retry request")
    require(view2["battlefield_state"] == before_projection["battlefield_state"], "Invalid geometry changed authoritative positions")
    valid = movement_payload(view2["pending_proposal"], view2)
    valid_command = pair.intent(request2, payload=valid, label="move-one-inch")
    record_authorized_attempt(pair, request2, view2, valid_command, role_for_actor(request2))
    _, accepted = pair.submit(valid_command, role_for_actor(request2))
    pair.captures.add("movement_accepted", role, "http", accepted, "Canonical complete ordered witness, every current placed physical model translated one inch +X", "accepted")
    after = pair.view(role)
    pose_evidence = verify_requested_model_poses(before_projection["battlefield_state"], after["battlefield_state"], valid["witness"])
    pair.captures.add("movement_after", role, "http", pair.request("GET", f"/sessions/{pair.session}/projection", role)[1], "Post-action authorized refresh shows authoritative position change", "payload")
    report.case("MOVE-01", "PASS", "Meaningful one-inch normal move accepted; each actual model pose matches its requested endpoints", {"requestId": request2["request_id"], **pose_evidence})
    report.case("MOVE-02", "PASS", "Wrong/missing/duplicate inventories uncommitted; invalid geometry committed; fresh valid retry accepted", {"revisionBefore": before["session_revision"], "revisionAfter": pair.metadata(role)["session_revision"], "historyUnchangedForInventory": True, "historyAdvancedOnceForGeometry": True})


def error_cases(pair: Pair, report: Report) -> None:
    malformed = pair.http.request("POST", "/sessions", "admin", malformed=True)
    assert_error(malformed, 400)
    pair.captures.add("error_malformed_json", "admin", "http", malformed, "Malformed JSON bytes sent to existing /sessions route", "error")
    _, missing = pair.request("GET", "/e01-unavailable-route", "playerA")
    assert_error(missing, 404)
    pair.captures.add("error_unavailable_route", "playerA", "http", missing, "Unavailable path; no invented support-profile route", "error")
    # Existing documented route, not /sessions/.../support-profile.
    game_id = pair.metadata()["game_id"]
    _, support = pair.request("GET", f"/games/{game_id}/support-profile", "playerA")
    require(support.status == 200, "Existing authorized support-profile route unavailable")
    pair.captures.add("support_profile", "playerA", "http", support, "Existing public /games/{game_id}/support-profile", "payload")
    required_statuses = {400, 401, 403, 404, 409, 422}
    if not required_statuses <= {entry["http_status"] for entry in pair.captures.entries} | {malformed.status}:
        raise Blocked("Required live wire status coverage incomplete because predecessor procedure is unavailable")
    if not {"recorded_invalid", "uncommitted_invalid"} <= {entry["expected_outcome"] for entry in pair.captures.entries}:
        raise Blocked("Both real 422 response branches are required; movement predecessor unavailable")
    report.case("ERROR-01", "PASS", "Actual 400/401/403/404/409 + both422 shapes and strict classifier negatives", {"malformed": malformed.status, "unavailable": missing.status, "otherCases": ["AUTH-01", "STALE-01", "MOVE-02"], "strictNegatives": "unittest and native checks required separately"})


def attach_worker(args: argparse.Namespace) -> int:
    # Worker gets endpoint/session/scope only, never a shutdown path/process handle/admin credential.
    access = importlib.import_module("warhammer40k_core.adapters.access_control")
    token = getattr(access, "DEV_PLAYER_A_TOKEN" if args.attach_role == "playerA" else "DEV_PLAYER_B_TOKEN")
    supplied = {args.attach_role: token}
    endpoint = Endpoint(supplied, base_url=args.attach_endpoint)
    view = projection_body(endpoint.request("GET", f"/sessions/{args.attach_session}/projection", args.attach_role))
    request = view.get("pending_decision")
    require(type(request) is dict and role_for_actor(request) == args.attach_role, "Attach worker has no offered authorized finite action")
    revision = int_field(endpoint.request("GET", f"/sessions/{args.attach_session}", args.attach_role).body, "session_revision")
    options = [row["option_id"] for row in request["options"]]
    option = "fixed:assassination:bring_it_down" if "fixed:assassination:bring_it_down" in options else options[0]
    command = envelope(args.attach_session, "e01-attach-" + request["request_id"], revision, "finite_option", request, option=option)
    reply = endpoint.request("POST", f"/sessions/{args.attach_session}/commands", args.attach_role, command)
    require(classify(reply.status, reply.body) == "accepted", "Attach worker offered action not accepted")
    output = {"role": args.attach_role, "session": args.attach_session, "offeredRequestId": request["request_id"], "accepted": True, "ownership": "endpoint/session/scoped credential only; no create/close/shutdown capability"}
    write_new(args.report_file, json_bytes(output), (token,))
    return 0


def lifetime_cases(args: argparse.Namespace, report: Report, host: OwnedHost, http: Endpoint, tokens: dict, main_session: str, config: dict) -> None:
    attach_config = copy.deepcopy(config)
    attach_config["config"]["game_id"] += "-attach"
    created = http.request("POST", "/sessions", "admin", attach_config)
    require(created.status == 201, "Supervisor attach session create failed")
    session = string_field(created.body, "session_id")
    start = http.request("POST", f"/sessions/{session}/commands", "admin", envelope(session, "e01-attach-start", 0, "start_session"))
    require(classify(start.status, start.body) == "accepted", "Supervisor attach start failed")
    result_file = args.output_root / "attach-worker.json"
    command = [sys.executable, "-I", "-B", str(Path(__file__).resolve()), "capture", "--core-root", str(args.core_root), "--fixture-root", str(args.fixture_root), "--output-root", str(args.output_root), "--report-file", str(result_file), "--attach-worker", "--attach-endpoint", http.base_url, "--attach-session", session, "--attach-role", "playerA"]
    with (args.output_root / "attach-worker.log").open("xb") as log:
        child = subprocess.Popen(command, cwd=args.output_root, env=child_environment(), stdout=log, stderr=subprocess.STDOUT, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        try:
            code = child.wait(timeout=MAX_SECONDS)
        except subprocess.TimeoutExpired:
            child.terminate()
            child.wait(timeout=10)
            raise BoundaryError("Owned attach worker exceeded 30 minute bound")
    require(code == 0 and result_file.exists(), "Attach worker failed; inspect owned ignored log")
    report.artifact(result_file)
    require(host.process.poll() is None and http.request("GET", f"/sessions/{main_session}", "playerA").status == 200, "Attach disconnect stopped host or other owned session")
    # Exercise the client guard against this owned listener, without starting a
    # second Core server: Windows development-host co-bind is a known limit.
    other_before = http.request("GET", f"/sessions/{main_session}", "playerA")
    require(other_before.status == 200, "Owned comparison session unavailable before client busy-port check")
    busy_check = None
    try:
        require_available_loopback_port(host.port)
    except PortUnavailable as exc:
        busy_check = {"port": host.port, "blockedBeforeHostLaunch": True, "diagnostic": str(exc)}
    require(busy_check is not None, "Client prelaunch probe failed to reject the owned occupied port")
    other_after = http.request("GET", f"/sessions/{main_session}", "playerA")
    require(host.process.poll() is None and other_after.status == 200, "Client busy-port check affected existing owned host/session")
    require(all(other_before.body[key] == other_after.body[key] for key in ("session_id", "session_revision", "projection_state_hash")), "Client busy-port check changed the other owned session")
    busy_check["otherSessionUnchanged"] = True
    # Only explicit supervisor admin closes disposable attach session.
    metadata = http.request("GET", f"/sessions/{session}", "admin").body
    closed = http.request("POST", f"/sessions/{session}/commands", "admin", envelope(session, "e01-attach-close", metadata["session_revision"], "close_session"))
    require(classify(closed.status, closed.body) == "accepted", "Supervisor attach session close failed")
    host.stop()
    restart = OwnedHost(args, report, tokens, "managed-restart")
    try:
        endpoint = restart.start()
        lost = endpoint.request("GET", f"/sessions/{main_session}", "playerA")
        assert_error(lost, 404)
        report.case("LIFETIME-01", "PASS", "Client busy-port rejection before host launch, scoped attach disconnect, managed stop, explicit restart SessionLost", {"attach": strict_json(result_file.read_bytes()), "clientBusyPortCheck": busy_check, "restart": "SessionLost", "oldSessionRecreated": False, "ownership": "Original Popen process handles only; shutdown markers unique", "lateCoBindProtection": "NOT_PROVEN: prelaunch probe closes before Core binds; Windows development-host exclusivity limitation remains external"})
    finally:
        restart.stop()


def run_case_groups(report: Report, groups: tuple) -> None:
    for ids, function in groups:
        try:
            function()
        except (Blocked, BoundaryError, OSError, TimeoutError, http_client.HTTPException, KeyError, IndexError, TypeError, ValueError) as exc:
            recorded_failure = False
            for case_id in ids:
                if not any(row["id"] == case_id for row in report.cases):
                    report.case(case_id, "BLOCKED" if isinstance(exc, Blocked) else "FAIL", "Packet meaningful case matrix", str(exc))
                    recorded_failure = True
            if not recorded_failure:
                report.case("GROUP-" + "-".join(ids) + "-POST-RESULT-ERROR", "BLOCKED" if isinstance(exc, Blocked) else "FAIL", "Case group and its cleanup complete without an unreported exception", {"caseIds": list(ids), "exceptionType": type(exc).__name__, "message": str(exc), "priorCaseResultsRetained": True})


def capture(args: argparse.Namespace, report: Report) -> None:
    verify_runtime(args, report)
    schemas = Schemas(args.fixture_root)
    contract = strict_json((args.fixture_root / "contracts/manifest.json").read_bytes())
    validated = 0
    for relative, schema in contract["example_schema_by_path"].items():
        path = member_path(args.fixture_root / "contracts", relative)
        if path.exists():
            schemas.validate(schema, strict_json(path.read_bytes()))
            validated += 1
    require(validated > 0, "No canonical examples validated")
    report.case("SCHEMA-01", "PASS", "All copied example/schema associations validated through local registry", {"validatedExamples": validated, "networkResolution": False})
    scope_case(report)
    tokens = credentials()
    report.secrets = tuple(token for token in tokens.values() if token)
    captures = Captures(args, report, schemas)
    host = OwnedHost(args, report, tokens, "managed-primary")
    pair = None
    try:
        http = host.start()
        pair = Pair(Endpoint(tokens), http, captures)
        config = strict_json((args.fixture_root / "contracts/examples/sessions/session-create.json").read_bytes())
        config["config"]["game_id"] = "e01-" + sha256(str(args.output_root).encode())[:12]
        for muster in config["config"]["army_muster_requests"]:
            require(muster["player_id"] not in pair.army_by_player, "Canonical config has ambiguous player/army mapping")
            pair.army_by_player[muster["player_id"]] = muster["army_id"]
        _, created = pair.request("POST", "/sessions", "admin", config)
        require(created.status == 201 and created.body["engine_build_id"] == BUILD_ID and created.body["server_contract_version"] == CONTRACT_VERSION, "Created session returned incompatible exact build/contract")
        pair.session = string_field(created.body, "session_id")
        for role in ("playerA", "playerB", "coach", "delayed"):
            left, right = pair.request("GET", f"/sessions/{pair.session}", role)
            pair.initial_cursors[role] = (string_field(left.body, "event_cursor"), string_field(right.body, "event_cursor"))
        _, started = pair.submit(envelope(pair.session, "e01-start", 0, "start_session"), "admin")
        start_artifact = captures.add("session_start_response", "admin", "http", started, "Actual response to explicit admin start; preserve failure as well as acceptance before asserting outcome")
        start_outcome = classify(started.status, started.body)
        if start_outcome != "accepted":
            start_code = string_field(object_field(started.body, "error"), "code") if "error" in started.body else string_field(started.body, "outcome_code")
            raise BoundaryError(f"Canonical start not accepted: actual HTTP {started.status}, code {start_code}; privileged response retained at {start_artifact}")
        run_case_groups(report, ((("AUTH-01", "VIEW-01"), lambda: auth_and_views(pair, report)), (("FINITE-01", "RETRY-01", "STALE-01"), lambda: finite_and_retry(pair, report)), (("MOVE-01", "MOVE-02", "FIDELITY-01"), lambda: movement_cases(pair, report)), (("ERROR-01",), lambda: error_cases(pair, report)), (("LIFETIME-01",), lambda: lifetime_cases(args, report, host, http, tokens, pair.session, config))))
        report.details["transportMeasurements"] = {"local": pair.local.metrics, "http": pair.http.metrics, "bounds": {"connectSeconds": 3, "readSeconds": SOCKET_READ_CAP_SECONDS, "totalSeconds": REQUEST_DEADLINE_SECONDS, "requestBytes": REQUEST_LIMIT, "responseBytes": RESPONSE_LIMIT, "maxSubmissionsPerScenario": 256}}
        report.details["comparisonNormalization"] = "Only operational timestamps and authenticated opaque cursor tokens are ignored for equality; all original captures/hashes retained; IDs, revisions, projections and typed action payloads preserved"
        trace = args.output_root / "private-trace.json"
        write_new(trace, json_bytes(pair.trace), report.secrets)
        report.artifact(trace)
    finally:
        host.stop()
        captures.finish()
        for case_id in CASE_IDS:
            if not any(case["id"] == case_id for case in report.cases):
                report.case(case_id, "BLOCKED", "Packet meaningful case matrix", "Predecessor failed or canonical public scenario unavailable")


def audit(args: argparse.Namespace, report: Report) -> None:
    preflight(args, report)
    index_path = args.output_root / "proposed-wire/index.json"
    require(index_path.is_file(), "Proposed wire index absent")
    index = strict_json(index_path.read_bytes())
    require(index["format_version"] == 1 and bool(index["cases"]), "Empty/unsupported wire fixture index")
    seen = set()
    for entry in index["cases"]:
        require((entry["case_id"], entry["role"]) not in seen, "Duplicate case/role capture")
        seen.add((entry["case_id"], entry["role"]))
        parts = Path(entry["path"]).parts
        require(len(parts) == 2 and SLUG.fullmatch(parts[0]) and SLUG.fullmatch(Path(parts[1]).stem) and parts[1].endswith(".json"), "Unsafe fixture index path")
        path = member_path(index_path.parent, entry["path"])
        data = path.read_bytes()
        require(sha256(data) == entry["sha256"], "Wire artifact hash mismatch")
        secret_scan(data)
        require(classify(entry["http_status"], strict_json(data)) == entry["expected_outcome"], "Wire outcome classification drift")
        report.artifact(path)
    report.case("ARTIFACT-AUDIT", "PASS", "Nonempty immutable indexed role captures with exact bytes and typed outcomes", {"captureCount": len(seen), "independentReview": "Required separately; this automated audit is not independent acceptance"})


def arguments(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("preflight", "verify-runtime", "capture", "audit"))
    for name in ("core-root", "fixture-root", "output-root", "report-file"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--core-launcher")
    parser.add_argument("--attach-worker", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--attach-endpoint", help=argparse.SUPPRESS)
    parser.add_argument("--attach-session", help=argparse.SUPPRESS)
    parser.add_argument("--attach-role", choices=("playerA", "playerB"), help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    for name in ("core_root", "fixture_root", "output_root", "report_file"):
        setattr(args, name, absolute_path(getattr(args, name)))
    repo = Path(__file__).resolve().parents[2]
    require(args.core_root == repo.parent / "Warhammer_40k_AI", "Core root must name selected read-only sibling")
    require(args.fixture_root == repo / "tests/migration/fixtures" / CORE_COMMIT, "Fixture root must name selected versioned directory")
    require(beneath(args.output_root, repo / ".local/experiments/E01-target") and args.output_root != repo / ".local/experiments/E01-target", "Output root outside approved unique ignored E01 run")
    require(beneath(args.report_file, args.output_root) and not args.report_file.exists(), "Report must be new and within packet output root")
    args.core_launcher = absolute_path(args.core_launcher) if args.core_launcher else args.core_root / "scripts/run_phase18m_reference_server.py"
    require(args.core_launcher == args.core_root / "scripts/run_phase18m_reference_server.py", "Only selected existing host launcher is permitted")
    args.output_root.mkdir(parents=True, exist_ok=True)
    if args.attach_worker:
        require(args.phase == "capture" and args.attach_endpoint and args.attach_session and args.attach_role, "Attach worker arguments incomplete")
    return args


def main(argv: list[str] | None = None) -> int:
    args = arguments(argv)
    if args.attach_worker:
        return attach_worker(args)
    report = Report(args.phase, args.output_root)
    try:
        {"preflight": preflight, "verify-runtime": verify_runtime, "capture": capture, "audit": audit}[args.phase](args, report)
    except (Blocked, BoundaryError, OSError, TimeoutError, subprocess.SubprocessError, http_client.HTTPException, ImportError, KeyError, IndexError, TypeError, ValueError) as exc:
        report.case("PHASE", "BLOCKED" if isinstance(exc, (Blocked, ImportError)) else "FAIL", "All phase prerequisites and cases", str(exc))
    payload = report.payload()
    write_new(args.report_file, json_bytes(payload), report.secrets)
    print(json.dumps({"phase": args.phase, "status": payload["status"], "caseCounts": payload["caseCounts"], "reportFile": str(args.report_file)}))
    return 0 if payload["status"].endswith("_PASS") else 2


if __name__ == "__main__":
    raise SystemExit(main())
