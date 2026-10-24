"""Portable launcher logic tests; no Core, engine, service or GUI is executed."""

import argparse
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/Start-Client.py"
SPEC = importlib.util.spec_from_file_location("manual_client_launcher", SCRIPT)
launcher = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(launcher)


class ManualClientTests(unittest.TestCase):
    def test_origin_validation_refuses_remote_and_embedded_values(self):
        self.assertEqual(launcher.local_endpoint("http://127.0.0.1:8765/"), "http://127.0.0.1:8765")
        self.assertEqual(launcher.local_endpoint("http://127.0.0.1:08765/"), "http://127.0.0.1:8765")
        for endpoint in ("http://example.com:8765", "https://127.0.0.1:8765", "http://[::1]:8765", "http://127.0.0.2:8765", "http://user:synthetic@127.0.0.1:8765", "http://127.0.0.1:8765/path", "http://127.0.0.1:8765/?x=y", "http://127.0.0.1"):
            with self.subTest(endpoint=endpoint), self.assertRaises(argparse.ArgumentTypeError):
                launcher.local_endpoint(endpoint)

    def test_existing_environment_is_preserved_without_importing_defaults(self):
        original = {"WH_CORE_ADMIN_TOKEN": "synthetic_admin", "WH_CORE_PLAYER_TOKEN": "synthetic_player", "KEEP": "yes"}
        result = launcher.development_environment("http://127.0.0.1:8765", original)
        self.assertEqual(result["WH_CORE_ADMIN_TOKEN"], original["WH_CORE_ADMIN_TOKEN"])
        self.assertEqual(result["WH_CORE_BASE_URL"], "http://127.0.0.1:8765")
        self.assertNotIn("WH_CORE_BASE_URL", original)

    def test_missing_environment_uses_only_named_stubbed_constants_silently(self):
        registry = types.ModuleType("warhammer40k_core.adapters.access_control")
        registry.DEV_ADMIN_TOKEN = "synthetic_default_admin"
        registry.DEV_PLAYER_A_TOKEN = "synthetic_default_player"
        captured = io.StringIO()
        with patch.dict(sys.modules, {registry.__name__: registry}), contextlib.redirect_stdout(captured), contextlib.redirect_stderr(captured):
            result = launcher.development_environment("http://127.0.0.1:8765", {})
        self.assertEqual(result["WH_CORE_ADMIN_TOKEN"], registry.DEV_ADMIN_TOKEN)
        self.assertEqual(result["WH_CORE_PLAYER_TOKEN"], registry.DEV_PLAYER_A_TOKEN)
        self.assertEqual(captured.getvalue(), "")

    def test_invalid_token_is_rejected_without_disclosing_it(self):
        with self.assertRaises(launcher.StartupError) as failure:
            launcher.development_environment("http://127.0.0.1:8765", {"WH_CORE_ADMIN_TOKEN": "synthetic invalid value", "WH_CORE_PLAYER_TOKEN": "synthetic_player"})
        self.assertNotIn("synthetic invalid value", str(failure.exception))

    def test_main_checks_runtime_before_environment_and_launches_client_only(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "WarhammerClient.uproject").touch()
            engine = repo / "ue"
            editor = engine / "Engine/Binaries/Win64/UnrealEditor.exe"
            editor.parent.mkdir(parents=True)
            editor.touch()
            events = []
            environment = {"WH_CORE_ADMIN_TOKEN": "synthetic_admin", "WH_CORE_PLAYER_TOKEN": "synthetic_player"}
            def checked():
                events.append("runtime")
            def prepared(endpoint):
                self.assertEqual(events, ["runtime"])
                events.append("environment")
                return environment
            with patch.object(launcher, "REPO_ROOT", repo), patch.object(launcher.sys, "platform", "win32"), patch.object(launcher, "verify_installed_core", side_effect=checked), patch.object(launcher, "development_environment", side_effect=prepared), patch.object(launcher.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run, contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(launcher.main(["--engine-root", str(engine), "--endpoint", "http://127.0.0.1:8765/"]), 0)
            self.assertEqual(run.call_count, 1)
            self.assertEqual(run.call_args.args[0], [str(editor), str(repo / "WarhammerClient.uproject"), "-game", "-windowed", "-CoreUrl=http://127.0.0.1:8765"])
            self.assertIs(run.call_args.kwargs["env"], environment)
            self.assertNotIn("shell", run.call_args.kwargs)
            self.assertNotIn("synthetic_admin", output.getvalue())

    def test_runtime_failure_prevents_environment_and_client_launch(self):
        with patch.object(launcher, "editor_path", return_value=Path("synthetic-editor")), patch.object(launcher.Path, "is_file", return_value=True), patch.object(launcher, "verify_installed_core", side_effect=launcher.StartupError("runtime mismatch")), patch.object(launcher, "development_environment") as environment, patch.object(launcher.subprocess, "run") as run, contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as failure:
                launcher.main(["--engine-root", ".", "--endpoint", "http://127.0.0.1:8765"])
        self.assertEqual(failure.exception.code, 2)
        environment.assert_not_called()
        run.assert_not_called()

    def test_linux_binary_selection_is_source_logic_only(self):
        with patch.object(launcher.sys, "platform", "linux"), patch.object(launcher.Path, "is_file", return_value=True), patch.object(launcher.os, "access", return_value=True):
            self.assertEqual(launcher.editor_path(Path("ue")), Path("ue/Engine/Binaries/Linux/UnrealEditor"))

    def test_help_does_not_check_runtime_or_launch(self):
        with patch.object(launcher, "verify_installed_core") as check, patch.object(launcher.subprocess, "run") as run, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(SystemExit) as failure:
                launcher.main(["--help"])
        self.assertEqual(failure.exception.code, 0)
        check.assert_not_called()
        run.assert_not_called()

    def test_optional_core_reference_uses_two_bounded_readonly_checks(self):
        completed = [subprocess.CompletedProcess([], 0, stdout=launcher.CORE_COMMIT + "\n"), subprocess.CompletedProcess([], 0, stdout="")]
        with patch.object(launcher.Path, "is_file", return_value=True), patch.object(launcher.subprocess, "run", side_effect=completed) as run:
            launcher.verify_core_reference(Path("synthetic-core"))
        self.assertEqual(run.call_count, 2)
        for call in run.call_args_list:
            self.assertEqual(call.kwargs["timeout"], 15)
            self.assertNotIn("shell", call.kwargs)

    def test_optional_core_reference_sanitizes_timeout(self):
        with patch.object(launcher.Path, "is_file", return_value=True), patch.object(launcher.subprocess, "run", side_effect=subprocess.TimeoutExpired(["synthetic-private-detail"], 15)):
            with self.assertRaises(launcher.StartupError) as failure:
                launcher.verify_core_reference(Path("synthetic-core"))
        self.assertNotIn("synthetic-private-detail", str(failure.exception))


if __name__ == "__main__":
    unittest.main()
