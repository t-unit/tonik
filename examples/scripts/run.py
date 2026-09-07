"""Local-only live integration orchestration. No generated schema/client patches."""
import argparse
import difflib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

EXAMPLES = Path(__file__).resolve().parents[1]
ROOT = EXAMPLES.parent
LOG_PATH = None
NAMES = ("python_fastapi", "typescript_nestjs", "javascript_fastify", "java_spring_boot", "ruby_rails")


def run(args, cwd=ROOT, env=None, capture=False):
    command = "+ " + " ".join(str(arg) for arg in args)
    print(command, flush=True)
    output = []
    with subprocess.Popen([str(arg) for arg in args], cwd=cwd, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT) as process:
        if LOG_PATH:
            with LOG_PATH.open("a") as log:
                log.write(command + "\n")
        try:
            for line in process.stdout:
                output.append(line)
                if not capture:
                    print(line, end="", flush=True)
                if LOG_PATH:
                    with LOG_PATH.open("a") as log:
                        log.write(line)
            returncode = process.wait()
        except BaseException:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            raise
    if returncode:
        raise subprocess.CalledProcessError(returncode, args, output="".join(output))
    return "".join(output)


def canonical(document):
    return json.dumps(document, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def snapshot(name, path, update):
    fresh = json.loads(path.read_text())
    saved = EXAMPLES / name / "openapi.json"
    if update:
        # Preserve the original producer bytes; only comparison canonicalizes keys.
        saved.write_bytes(path.read_bytes())
        return
    if not saved.exists():
        raise RuntimeError(f"Missing {saved}; review the fetched schema and use --update-spec")
    old = canonical(json.loads(saved.read_text()))
    new = canonical(fresh)
    if old != new:
        diff = "".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile=str(saved), tofile=str(path)))
        (path.parent / "schema.diff").write_text(diff)
        raise RuntimeError("OpenAPI snapshot drift; review .artifacts/" + name + "/schema.diff and use --update-spec explicitly\n" + diff[:12000])


def resolve_local_util(directory, dart):
    relative_util = os.path.relpath(ROOT / "packages/tonik_util", directory)
    (directory / "pubspec_overrides.yaml").write_text("dependency_overrides:\n  tonik_util:\n    path: " + json.dumps(relative_util) + "\n")
    run([dart, "pub", "get"], cwd=directory)
    config_path = directory / ".dart_tool/package_config.json"
    config = json.loads(config_path.read_text())
    util = next(package for package in config["packages"] if package["name"] == "tonik_util")
    resolved = urllib.parse.urljoin(config_path.as_uri(), util["rootUri"])
    if Path(urllib.request.url2pathname(urllib.parse.urlparse(resolved).path)).resolve() != ROOT / "packages/tonik_util":
        raise RuntimeError("tonik_util must resolve to the assigned repository")


def execute(name, args, dart, cli, invocation):
    lock = EXAMPLES / ".locks" / name
    lock.parent.mkdir(exist_ok=True)
    try:
        lock.mkdir()
    except FileExistsError:
        raise RuntimeError(f"{name} is locked by another run. If that process was killed, remove {lock} after checking it is no longer running.")
    artifact = EXAMPLES / ".artifacts" / name
    project = f"tonik-example-{name.replace('_', '-')}-{invocation}"
    compose = ["docker", "compose", "-f", EXAMPLES / "compose.yaml", "-p", project, "--profile", name]
    started = False
    try:
        (lock / "owner").write_text(f"pid={os.getpid()}\n")
        artifact.mkdir(parents=True, exist_ok=True)
        started = True
        run([*compose, "up", "--build", "--detach", name])
        port = run([*compose, "port", name, "8000"], capture=True).strip().rsplit(":", 1)[1]
        url = "http://127.0.0.1:" + port
        deadline = time.monotonic() + args.timeout
        while True:
            try:
                with urllib.request.urlopen(url + "/health", timeout=2) as response:
                    if response.status == 200:
                        break
            except (OSError, urllib.error.URLError):
                pass
            if time.monotonic() > deadline:
                raise RuntimeError(f"{name} did not become ready within {args.timeout}s")
            time.sleep(0.5)
        with urllib.request.urlopen(url + "/openapi.json", timeout=30) as response:
            spec = artifact / "openapi.json"
            spec.write_bytes(response.read())
        run([*compose, "run", "--build", "--rm", "--no-deps", "validator", f"/artifacts/{name}/openapi.json"])
        snapshot(name, spec, args.update_spec)
        environment = dict(os.environ, TONIK_EXAMPLE_BASE_URL=url)
        for backend in ("dio", "http") if args.backend == "both" else (args.backend,):
            folder = EXAMPLES / name
            generated = folder / "generated" / f"{name}_api"
            if generated.exists():
                shutil.rmtree(generated)
            run([cli, "--config", folder / "tonik.yaml", "--spec", spec, "--output-dir", folder / "generated", "--backend", backend])
            resolve_local_util(generated, dart)
            resolve_local_util(folder / "client", dart)
            run([dart, "analyze", "--fatal-infos"], cwd=generated)
            run([dart, "analyze", "--fatal-infos"], cwd=folder / "client")
            run([dart, "run", "bin/example.dart"], cwd=folder / "client", env=environment)
            run([dart, "test", "--reporter", "expanded"], cwd=folder / "client", env=environment)
            print(f"PASS {name} / {backend}", flush=True)
    finally:
        failed = sys.exc_info()[0] is not None
        cleanup_error = None
        try:
            if started:
                try:
                    with (artifact / "server.log").open("w") as log:
                        subprocess.run([str(arg) for arg in [*compose, "logs", "--no-color"]], stdout=log, stderr=subprocess.STDOUT)
                finally:
                    result = subprocess.run([str(arg) for arg in [*compose, "down", "--volumes", "--remove-orphans"]])
                    if result.returncode:
                        cleanup_error = f"Container cleanup failed for Compose project {project}; run docker compose -p {project} -f examples/compose.yaml --profile {name} down --volumes --remove-orphans manually"
        except OSError as error:
            cleanup_error = str(error)
        finally:
            shutil.rmtree(lock)
        if cleanup_error:
            if failed:
                print(cleanup_error, file=sys.stderr)
            else:
                raise RuntimeError(cleanup_error)


def main():
    global LOG_PATH
    parser = argparse.ArgumentParser(description="Run explicitly selected real-server examples locally; never on CI.")
    parser.add_argument("example", choices=(*NAMES, "all"))
    parser.add_argument("--backend", choices=("both", "dio", "http"), default="both")
    parser.add_argument("--update-spec", action="store_true", help="Accept freshly generated OpenAPI snapshots after validation")
    parser.add_argument("--timeout", type=int, default=180, help="Readiness timeout in seconds")
    args = parser.parse_args()
    if os.environ.get("CI", "").lower() in ("true", "1"):
        parser.error("Live examples are on-demand only and refuse CI=true or CI=1")
    if args.timeout < 1:
        parser.error("--timeout must be positive")
    sdk = ROOT / ".fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart"
    dart = os.environ.get("TONIK_DART") or (str(sdk) if sdk.exists() else shutil.which("dart"))
    if not dart or not shutil.which("docker"):
        parser.error("Docker Compose and the repository Dart SDK are required (set TONIK_DART for a custom SDK executable)")
    run(["docker", "compose", "version"])
    run(["docker", "info"], capture=True)
    if not (ROOT / ".dart_tool/package_config.json").exists():
        parser.error("Resolve root Dart dependencies with dart pub get first")
    invocation = uuid.uuid4().hex[:12]
    run_dir = EXAMPLES / ".artifacts" / "runs" / invocation
    run_dir.mkdir(parents=True)
    LOG_PATH = run_dir / "run.log"
    cli = run_dir / "tonik"
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    try:
        run([dart, "compile", "exe", "packages/tonik/bin/tonik.dart", "-o", cli])
        for name in NAMES if args.example == "all" else (args.example,):
            execute(name, args, dart, cli, invocation)
    finally:
        cli.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError, OSError, KeyboardInterrupt) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(1)
