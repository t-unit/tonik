# Plain JavaScript Fastify + Swagger

From the repository root ([setup](../README.md#run)):

```sh
./examples/run.sh javascript_fastify
```

[server.js](server/server.js) uses Fastify 5.12.3 and Swagger 9.8.1 in dynamic mode
to produce OpenAPI 3.0 from the route schemas. Dependencies are pinned in
[package.json](server/package.json) and its lockfile.

- Registered schema `$id` values become readable OpenAPI component names. AJV
  validates requests; Fastify's serializer applies response schemas.
- Multipart `onFile` captures metadata and bytes while retaining the actual file
  stream required by the plugin's `isFile` validator.
- A Transform stream records form bytes as the normal parser reads them. It
  tracks `receivedEncodedLength` for Fastify's Content-Length checks.
- Contact alternatives allow extra properties so `anyOf` overlap survives response
  serialization. Binary bodies use a Buffer check, since JSON string validation
  does not apply to the parser's in-memory Buffer.

This example uses a `session` header, not a cookie plugin. See the
[Dart demo](client/bin/example.dart), [live tests](client/test/live_test.dart), and
[multipart integration docs](https://github.com/fastify/fastify-multipart#json-schema-with-swagger).
