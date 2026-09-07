# Real server examples

Run Tonik-generated Dart clients against real servers using both Dio and HTTP.
Requires Docker Compose, Python 3.9+, and Dart 3.13+.

```sh
git clone https://github.com/t-unit/tonik.git
cd tonik
dart pub get
./examples/run.sh python_fastapi
```

The [Dart demo](https://github.com/t-unit/tonik/blob/main/examples/python_fastapi/client/bin/example.dart)
fetches a typed product and uploads a file with multipart form data.

Choose a server:

- [Python: FastAPI](https://github.com/t-unit/tonik/tree/main/examples/python_fastapi)
- [TypeScript: NestJS](https://github.com/t-unit/tonik/tree/main/examples/typescript_nestjs)
- [JavaScript: Fastify](https://github.com/t-unit/tonik/tree/main/examples/javascript_fastify)
- [Java: Spring Boot](https://github.com/t-unit/tonik/tree/main/examples/java_spring_boot)
- [Ruby: Rails](https://github.com/t-unit/tonik/tree/main/examples/ruby_rails)

See [run options](https://github.com/t-unit/tonik/tree/main/examples) for selecting
a backend or running all five servers.
