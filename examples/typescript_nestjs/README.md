# NestJS + Swagger on Express

From the repository root ([setup](../README.md#run)):

```sh
./examples/run.sh typescript_nestjs
```

[main.ts](server/main.ts) uses NestJS 11.1.6 and Swagger 11.2.0 to produce
OpenAPI 3.0 from DTO and controller decorators. Dependencies are pinned in
[package.json](server/package.json) and its lockfile; no Swagger compiler plugin
is needed.

- Express parses JSON and URL-encoded forms; Multer handles multipart files.
  The form parser's `verify` hook captures the original encoded bytes.
- Cookie input is documented as a `Cookie` header and parsed by cookie-parser.
  Swagger's reflected parameters did not retain an `in: cookie` declaration here.
- Swagger declares `oneOf`, `anyOf` and `allOf`. The handlers also check the
  payment/contact shapes: schema annotations alone do not validate these unions.
  Native ValidationPipe error bodies are not declared in this example.

See the [Dart demo](client/bin/example.dart), [live tests](client/test/live_test.dart),
and [NestJS Swagger documentation](https://docs.nestjs.com/openapi/types-and-parameters).
