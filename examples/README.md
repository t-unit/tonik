# Real server examples

Five local servers generate OpenAPI and exchange real HTTP requests with
Tonik-generated Dart clients. Their fake catalog data is fixed; no database,
credentials, or external API is involved. The servers exercise framework parsing
and serialization in addition to Tonik's existing fixture-based integration tests.

| Language | Server and producer | OpenAPI |
| --- | --- | --- |
| Python | [FastAPI + Pydantic](python_fastapi/README.md) | 3.1 |
| TypeScript | [NestJS + Swagger, Express adapter](typescript_nestjs/README.md) | 3.0 |
| JavaScript | [Fastify + Swagger, dynamic mode](javascript_fastify/README.md) | 3.0 |
| Java | [Spring Boot MVC + springdoc](java_spring_boot/README.md) | 3.0 |
| Ruby | [Rails API + rswag request specs](ruby_rails/README.md) | 3.0 |

## Run locally

Prerequisites: Docker with Docker Compose, Python 3.9+ for the standard-library
runner, and this repository's Dart SDK and resolved root dependencies. Server
runtimes and schema validation dependencies run inside containers. Set
`TONIK_DART` to an SDK executable if the usual `dart` command is a wrapper; the
runner automatically uses `.fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart` when
available.

```sh
# At the repository root, once:
dart pub get

# An explicit example is required. Both backends are the default.
./examples/run.sh python_fastapi
./examples/run.sh java_spring_boot --backend http
./examples/run.sh all --backend both

# Accept a changed producer snapshot only after reviewing the schema diff:
./examples/run.sh ruby_rails --backend both --update-spec
```

Each run builds only the selected server, binds a random port on `127.0.0.1`,
waits for readiness, and fetches `/openapi.json` from the live process. The pinned
validator checks the actual OAS dialect and required contract features. The
runner compares the fresh document with `openapi.json`, ignoring object key order
but preserving array order and content. It then compiles the local Tonik CLI,
generates the selected backend, resolves the generated package and standalone
Dart client against the local `tonik_util`, analyzes both, runs the demonstration,
and executes explicit live tests. With `--backend both`, generation and tests run
sequentially for Dio and HTTP.

Servers shut down after success, failure, or interruption. Compose project names
are unique per invocation. A per-example directory lock prevents another run
from overwriting generated clients or artifacts. Readiness has a 180-second
limit, adjustable with `--timeout`. Initial Docker dependency downloads and
builds take longer than subsequent runs.

## Verification

Verified locally on 2026-09-07 with `./examples/run.sh all --backend both`:
all ten server/backend combinations passed, totaling **208 live Dart test
executions** (104 concrete cases on each backend). Every fresh schema passed
validation and snapshot comparison; generated/client analysis and demonstrations
passed. The Rails image build also passed 15 executed request specs.

## What to inspect

Each example contains server source and locked dependencies, a reviewed producer
snapshot, `tonik.yaml`, and a standalone `client/` with a readable demonstration
and concrete assertions. Generated packages live in ignored `generated/`
directories. Generated OpenAPI and Dart are never patched to make tests pass.

The common tests cover nested JSON, enums, typed maps, UUID/date/offset values,
nulls, escaped path/query/header parameters, URL-encoded forms, multipart files
from memory and disk, zero-byte files, binary uploads/downloads, UTF-8/Latin-1/
Windows-1252/Shift-JIS response bytes, discriminated payments, creation, deletion,
and declared errors. Per-stack additions and parser limitations are recorded in
each README.

For failures, inspect `.artifacts/<example>/server.log`, the fetched
`openapi.json`, and `schema.diff` when schema drift is detected. Command output
is retained in `.artifacts/runs/<invocation>/run.log`. No fallback uses the saved
snapshot after a failed live fetch. Ordinary runs do not update tracked snapshots.

To work on Dart assertions against an already running local server, generate and
resolve the client first, then explicitly set `TONIK_EXAMPLE_BASE_URL` when
running `dart run bin/example.dart` or `dart test` from its `client/` directory.
The clients reject a missing URL and nonlocal URLs.

## No CI integration

These examples are outside the root Dart workspace and `integration_test/`.
They are absent from Melos scripts, integration discovery, and workflows. Both
the runner and Dart entry points refuse `CI=true` and `CI=1`. Do not add them to
CI, scheduled jobs, or default test commands. They are opt-in developer tools.
Existing full unit/integration verification requirements still apply before
publishing repository changes; these examples do not replace those suites.
