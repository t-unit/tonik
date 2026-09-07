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
