# Plain JavaScript Fastify + Swagger

```sh
./examples/run.sh javascript_fastify --backend both
```

Node 22.19.0, Fastify 5.5.0, @fastify/swagger 9.5.1, @fastify/multipart 9.2.1,
@fastify/formbody 8.0.2 and the remaining plugins are pinned in `package.json` and
`package-lock.json`. This is plain JavaScript. Dynamic Swagger mode produces
**OpenAPI 3.0.3** from the registered schemas. The documented `refResolver` option
uses schema `$id` names rather than anonymous `def-*` component names.

The standalone Dart client has 20 explicit live tests.

| Case | Producer behavior | Runtime/parser setup | Dio | HTTP | Limitation/evidence |
| --- | --- | --- | --- | --- | --- |
| JSON/formats/maps/null | Registered JSON schemas | Fastify AJV and response serializer | Pass | Pass | Nested customer, enum, typed stock map and offset string. |
| Path/query/headers | Route parameter schemas | Fastify default parser and AJV coercion | Pass | Pass | Repeated query arrays, escaping, integer/boolean and two headers. |
| URL-encoded form | `consumes` and body schema | formbody; preParsing Transform tee preserves raw bytes | Pass | Pass | Tee tracks receivedEncodedLength; it never consumes the stream ahead of the parser. |
| Multipart file/scalars | Multipart plugin's `isFile` integration | keyValues mode and onFile capture | Pass | Pass | Keeps the actual file stream for AJV validation and returns parsed metadata/bytes. |
| Empty/path file | Same binary schema | Multipart parser | Pass | Pass | No fake file sentinel or hardcoded receipt. |
| Binary/four charsets | Response media and binary schema | Buffer parser, Buffer validation, iconv-lite | Pass | Pass | Nontext bytes and actual encoded responses. |
| `oneOf` | Schema alternatives/discriminator | AJV discriminator enabled | Pass | Pass | Both payment variants; card echo. |
| Overlapping `anyOf` | Schema alternatives | Alternatives allow extra properties | Pass | Pass | Prevents the serializer dropping the other branch's field. |
| `allOf` | Product/Audit schema references | Flat object response | Pass | Pass | Both typed components checked. |
| 201/204/404 | Route response schemas | Fastify status/serialization | Pass | Pass | Raw response also checked for secret omission. |
| gzip | @fastify/compress | Threshold 1 byte | Enabled; not explicitly asserted | Enabled; not explicitly asserted | Ordinary compression middleware. |

This example uses a `session` header; cookie plugin/security-scheme behavior is a
follow-up. File arrays, JSON parts, advanced query styles and native AJV error
response schemas are not included yet. The binary parser produces a Buffer,
whereas the wire schema is a binary string, so that route explicitly validates
the Buffer instead of applying a JSON string validator to the in-memory value.
Swagger options do not automatically configure query or multipart parsing.

References: [Fastify Swagger](https://github.com/fastify/fastify-swagger),
[multipart Swagger/AJV integration](https://github.com/fastify/fastify-multipart#json-schema-with-swagger),
[preParsing hooks](https://fastify.dev/docs/latest/Reference/Hooks/#preparsing).
