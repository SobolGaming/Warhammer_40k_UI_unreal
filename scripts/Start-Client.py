"""Launch an Editor or packaged client against an already running local Core."""

# Interactive user entry point. Do not invoke during an owner screen HOLD.

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import urlsplit, urlunsplit

REPO_ROOT = Path(__file__).resolve().parents[1]
CORE_PROFILES = {
    "44.5.0": ("4f9bef0df2fb974d1285232a1009b8781926361d", "warhammer40k-core-v2:runtime-tree-sha256-v1:0443ce4bc405aad1737ec9a396948775010df933bd75144f6ab9ff54152118ba", 3130),
    "44.3.33": ("5f509724da25a2f6ded0c2739a8e7c84bdf59c91", "warhammer40k-core-v2:runtime-tree-sha256-v1:65fc8414407ae5d6a8ea779c8e737a22733459094db679a160c60f6e2129f96a", 3116),
}
CORE_COMMIT, CORE_BUILD, CORE_RESOURCE_COUNT = CORE_PROFILES["44.5.0"]


class StartupError(RuntimeError):
    pass


def local_endpoint(value: str) -> str:
    try:
        uri = urlsplit(value)
        port = uri.port
    except ValueError as error:
        raise argparse.ArgumentTypeError("Use http://127.0.0.1:<port>/.") from error
    if (uri.scheme != "http" or uri.hostname != "127.0.0.1"
            or port is None or not 1024 <= port <= 65535
            or uri.username is not None or uri.password is not None
            or uri.path not in {"", "/"} or uri.query or uri.fragment):
        raise argparse.ArgumentTypeError("This client requires http://127.0.0.1:<port> with port 1024–65535 and no credentials, path, query or fragment.")
    return urlunsplit(("http", f"127.0.0.1:{port}", "", "", ""))


def verify_core_reference(root: Path, version: str = "44.5.0") -> None:
    if not (root / "scripts/run_phase18m_reference_server.py").is_file():
        raise StartupError("CoreRoot must contain the selected development-server checkout.")
    options = ["git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "core.untrackedCache=false", "-c", "core.hooksPath=" + ("NUL" if sys.platform == "win32" else "/dev/null"), "-C", str(root)]
    try:
        head = subprocess.run(options + ["rev-parse", "HEAD"], capture_output=True, text=True, check=True, timeout=15).stdout.strip()
        changes = subprocess.run(options + ["status", "--porcelain=v1", "--untracked-files=normal"], capture_output=True, text=True, check=True, timeout=15).stdout
    except (OSError, subprocess.SubprocessError) as error:
        raise StartupError("Could not verify the read-only Core checkout; each Git check has a 15-second limit.") from error
    if head != CORE_PROFILES[version][0] or changes:
        raise StartupError("Core checkout must be clean at the selected revision; this launcher never resets it.")


def verify_installed_core(version: str = "44.5.0") -> None:
    if sys.version_info[:2] != (3, 14) or not sys.flags.isolated or not sys.dont_write_bytecode:
        raise StartupError("Use the native Core Python 3.14 environment with -I -B.")
    try:
        import warhammer40k_core
        from warhammer40k_core.build_identity import verified_engine_build_identity

        if not Path(warhammer40k_core.__file__).resolve().is_relative_to(Path(sys.prefix).resolve()):
            raise StartupError("Core must resolve inside this interpreter's installed environment.")
        identity = verified_engine_build_identity()
    except (ImportError, OSError, ValueError, RuntimeError) as error:
        raise StartupError("Installed Core verification failed; check the pinned package and native dependencies.") from error
    _, build, resource_count = CORE_PROFILES[version]
    if identity.build_id != build or identity.resource_count != resource_count:
        raise StartupError(f"Installed Core build/resource identity differs from selected contract {version}.")


def development_environment(endpoint: str, source: dict[str, str] | None = None) -> dict[str, str]:
    environment = dict(os.environ if source is None else source)
    names = ("WH_CORE_ADMIN_TOKEN", "WH_CORE_PLAYER_TOKEN", "WH_CORE_PLAYER_B_TOKEN")
    if any(not environment.get(name, "").strip() for name in names):
        try:
            from warhammer40k_core.adapters.access_control import DEV_ADMIN_TOKEN, DEV_PLAYER_A_TOKEN, DEV_PLAYER_B_TOKEN
        except (ImportError, OSError, ValueError, RuntimeError) as error:
            raise StartupError("The selected Core development credential registry is unavailable.") from error

        defaults = dict(zip(names, (DEV_ADMIN_TOKEN, DEV_PLAYER_A_TOKEN, DEV_PLAYER_B_TOKEN), strict=True))
        for name in names:
            if not environment.get(name, "").strip():
                environment[name] = defaults[name]
    for name in names:
        if len(environment[name]) > 256 or re.fullmatch(r"[A-Za-z0-9._~+/\-]+=*", environment[name], flags=re.ASCII) is None:
            raise StartupError(f"{name} must be a valid bearer token; its value is not displayed.")
    environment["WH_CORE_BASE_URL"] = endpoint
    return environment


def editor_path(engine: Path) -> Path:
    if sys.platform == "win32":
        relative = "Engine/Binaries/Win64/UnrealEditor.exe"
    elif sys.platform.startswith("linux"):
        relative = "Engine/Binaries/Linux/UnrealEditor"
    else:
        raise StartupError("This manual development launcher supports Windows and Linux only; Linux remains untested.")
    editor = engine / relative
    if not editor.is_file() or (sys.platform.startswith("linux") and not os.access(editor, os.X_OK)):
        raise StartupError("Native UnrealEditor is missing or not executable; install the matching engine and build WarhammerClientEditor first.")
    return editor


def packaged_path(executable: Path) -> Path:
    if sys.platform == "win32":
        valid = executable.suffix.lower() == ".exe" and executable.is_file()
    elif sys.platform.startswith("linux"):
        valid = executable.is_file() and os.access(executable, os.X_OK)
    else:
        raise StartupError("This manual launcher supports Windows and Linux only; Linux remains untested.")
    if not valid:
        raise StartupError("The packaged client executable is missing, has the wrong native file type or is not executable.")
    return executable


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--engine-root", type=Path, help="Native UE 5.8 root; defaults to UE_ROOT when no packaged executable is selected.")
    selection.add_argument("--client-executable", type=Path, help="Explicit packaged native client executable; ignores UE_ROOT and runs from its containing folder.")
    parser.add_argument("--endpoint", required=True, type=local_endpoint, help="Already running http://127.0.0.1:<port> origin; no credentials in URLs.")
    parser.add_argument("--core-root", type=Path, help="Optional pinned clean checkout to verify as the manual server's script reference.")
    parser.add_argument("--core-version", choices=tuple(CORE_PROFILES), default="44.5.0", help="Exact development runtime profile. Use 44.3.33 only with the retained older preview executable.")
    args = parser.parse_args(argv)
    try:
        if args.client_executable is not None:
            executable = packaged_path(args.client_executable.expanduser().resolve())
            arguments = [str(executable)]
            working_directory = executable.parent
        else:
            engine = args.engine_root or os.environ.get("UE_ROOT")
            if engine is None:
                raise StartupError("Set UE_ROOT, pass --engine-root or select --client-executable.")
            executable = editor_path(Path(engine).expanduser().resolve())
            project = REPO_ROOT / "WarhammerClient.uproject"
            if not project.is_file():
                raise StartupError("WarhammerClient.uproject is missing beside the scripts directory.")
            arguments = [str(executable), str(project), "-game"]
            working_directory = REPO_ROOT
        if args.core_root:
            verify_core_reference(args.core_root.expanduser().resolve(), args.core_version)
        verify_installed_core(args.core_version)  # Verify before importing development credential constants.
        environment = development_environment(args.endpoint)
        print(f"Opening Unreal client at {args.endpoint}. Core remains running when the client closes.")
        result = subprocess.run(arguments + ["-windowed", "-CoreUrl=" + args.endpoint], cwd=working_directory, env=environment, check=False)
        if result.returncode:
            print(f"Unreal client exited with code {result.returncode}.", file=sys.stderr)
        return result.returncode if result.returncode >= 0 else 1
    except StartupError as error:
        parser.exit(2, f"Client startup failed: {error}\n")
    except OSError:
        parser.exit(2, "Client startup failed: check required file paths, permissions and selected native client availability.\n")


if __name__ == "__main__":
    raise SystemExit(main())
