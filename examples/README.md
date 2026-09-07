# Real server examples

Generate Dart clients from five real servers and call them with both Dio and
HTTP. Every server uses fixed fake data and runs without a database or credentials.

| Language | Server and OpenAPI producer | OpenAPI |
| --- | --- | --- |
| Python | [FastAPI + Pydantic](python_fastapi) | 3.1 |
| TypeScript | [NestJS + Swagger on Express](typescript_nestjs) | 3.0 |
| JavaScript | [Fastify + Swagger](javascript_fastify) | 3.0 |
| Java | [Spring Boot + springdoc](java_spring_boot) | 3.0 |
| Ruby | [Rails + rswag](ruby_rails) | 3.0 |

## Run

Install Bash, Docker with Docker Compose, curl, and Dart 3.13+. The runner resolves Dart
dependencies; server dependencies are pinned and installed inside containers.

```sh
./examples/run.sh python_fastapi
./examples/run.sh java_spring_boot --backend http
./examples/run.sh all
```

Both backends run by default. The script uses the repository's FVM SDK when
available, or `dart` from PATH. Set `TONIK_DART` to choose another SDK executable.

The runner starts the selected server on a random localhost port, fetches fresh
OpenAPI, and passes it unchanged to the local Tonik generator. It then analyzes
the generated package and client, runs the demo and tests, and stops the server.
Readiness is limited to 180 seconds; use `--timeout SECONDS` to change it.

On GitHub, open **Actions → Real Server Examples → Run workflow** and choose a
server and backend. Logs and fetched schemas are saved as workflow artifacts.

## Explore

Each directory contains the native app in `server/`, a Dart demo in
`client/bin/example.dart`, and concrete live assertions in `client/test/`.
The examples cover JSON models and formats, query/form encoding, multipart files,
binary bodies, four text charsets, composition, and HTTP statuses. Each server's
README explains its framework-specific behavior.

Generated clients and fetched schemas are ignored. The current schema and server
logs remain in `.artifacts/<example>/`. Add `--update-spec` to refresh the saved
`openapi.json` snapshot after a successful run; snapshots are reference files,
and client generation always uses the live schema.

These examples are on-demand only. They are outside the workspace/default test
commands; CI runs require a manual `workflow_dispatch`. Simultaneous local runs
of the same example are blocked to protect its generated client.
