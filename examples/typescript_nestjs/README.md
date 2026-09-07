# NestJS + Swagger on Express

```sh
./examples/run.sh typescript_nestjs --backend both
```

Node 22.19.0, TypeScript 5.9.2, NestJS 11.1.6, @nestjs/swagger 11.2.0 and Express
5.1.0 are pinned in `server/package.json` and `package-lock.json`. The app uses
explicit DTO decorators and **OpenAPI 3.0.0** from `SwaggerModule.createDocument`.
It serves that document directly at `/openapi.json`; `/health` is a separate
Express readiness route. The Swagger CLI compiler plugin is not required.

The standalone Dart client has 20 explicit live tests.

| Case | Producer behavior | Runtime/parser setup | Dio | HTTP | Limitation/evidence |
| --- | --- | --- | --- | --- | --- |
| Nested JSON/formats/maps/null | `ApiProperty` DTO metadata | Express JSON and Nest ValidationPipe | Pass | Pass | Offset string remains +02:00 through echo. |
| Path/repeated query/headers/cookie | `ApiQuery`, `ApiHeader`, route decorators | Express query parser, ParseInt/BoolPipe, cookie-parser | Pass | Pass | Cookie is explicitly documented as a Cookie header. |
| URL-encoded form | `ApiConsumes` and typed `ApiBody` | Express urlencoded parser with verify hook for raw bytes | Pass | Pass | Scalar conversion and repeated values checked against literal inputs. |
| Multipart file/scalars | Upload DTO, binary file schema | Nest FileInterceptor/Multer | Pass | Pass | Memory/path/empty files, metadata and bytes. |
| Binary/four text encodings | `ApiConsumes`/`ApiProduces` and response schema | Express raw parser; iconv-lite response encoding | Pass | Pass | Actual non-UTF-8 bytes, including Shift-JIS. |
| `oneOf` | Explicit discriminated property schema | Controller validates card/bank shape | Pass | Pass | Both variants, card roundtrip. |
| `anyOf` | Explicit alternatives | Controller permits email, phone, or both | Pass | Pass | Overlap remains an overlapping object on the wire. |
| `allOf` | Response schema references Product and Audit | Flat JSON assembled by handler | Pass | Pass | Both constituents have typed Dart assertions. |
| 201/204/404 | Response decorators | Real status handling | Pass | Pass | Distinct input name and raw response prove secret omission. |
| gzip | Express compression middleware | Threshold 1 byte | Enabled; not explicitly asserted | Enabled; not explicitly asserted | Enabled on live responses. |

`ApiOperation.parameters` alone did not retain a cookie parameter alongside the
scanner's reflected route parameters in this version. The example therefore uses
an explicit `Cookie` header declaration and verifies cookie-parser's parsed
session value. It does not claim an inferred OpenAPI cookie parameter.

Native ValidationPipe errors are not declared in this example's response schemas;
FastAPI separately demonstrates a producer-emitted native validation response.
Typed JSON multipart parts, file arrays, extended parameter styles and additional
media variants remain follow-ups here. Swagger composition metadata does not
itself validate a request; the handlers enforce the demonstrated union shapes.

References: [NestJS composition](https://docs.nestjs.com/openapi/types-and-parameters#oneof-anyof-allof),
[NestJS uploads](https://docs.nestjs.com/techniques/file-upload),
[Swagger operations](https://docs.nestjs.com/openapi/operations).
