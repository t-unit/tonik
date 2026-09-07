# FastAPI + Pydantic

```sh
./examples/run.sh python_fastapi --backend both
```

Python 3.13.7, FastAPI 0.116.1, Pydantic 2.11.7, Starlette 0.47.3, Uvicorn 0.35.0,
and python-multipart 0.0.20 are pinned with their resolved dependencies in
`server/requirements.txt`. FastAPI produces **OpenAPI 3.1.0** from Pydantic models
and route declarations. `/health` is excluded from the schema; `/openapi.json`
is FastAPI's own endpoint. No schema postprocessing is applied.

The standalone Dart client contains 26 explicit live tests. The basic example
prints a nested catalog result and a receipt parsed from a real file upload.

| Case | Producer behavior | Runtime/parser setup | Dio | HTTP | Limitation/evidence |
| --- | --- | --- | --- | --- | --- |
| JSON, enum, map, UUID/date/offset, null | Inferred from Pydantic | Response models and body validation | Pass | Pass | UTC offset is asserted before and after echo; tests cover null, not every missing/default distinction. |
| Path/query/header/cookie | Inferred parameters | FastAPI/Starlette parsers | Pass | Pass | Literal percent, comma, plus, spaces, and Unicode. |
| URL-encoded arrays/scalars | `Form` declarations | python-multipart; middleware captures bytes before parsing | Pass | Pass | Raw encoded plus/ampersand are asserted. |
| File/scalars, empty/path file | `File` and `Form` | `UploadFile` | Pass | Pass | Actual file name, content type and bytes. |
| File arrays and optional file | Inferred multipart body schemas | `list[UploadFile]`, nullable `UploadFile` | Pass | Pass | Repeated tags, two files, zero bytes, omitted optional attachment. |
| Binary and four charsets | Declared response media/schema | Actual encoded response bytes | Pass | Pass | UTF-8, ISO-8859-1, Windows-1252, Shift-JIS. |
| `oneOf` card/bank | Discriminated Pydantic union | Pydantic validates and serializes selected branch | Pass | Pass | Both branches decoded; card is echoed. |
| Overlapping `anyOf` | Ordinary Pydantic union | `extra='allow'` on alternatives | Pass | Pass | Preserves both email and phone; default `extra='ignore'` would drop the other branch's field. |
| Recursive category | Inferred recursive reference | Pydantic nested models | Pass | Pass | Concrete child with an empty children list. |
| Vendor JSON/problem+json/CSV | JSONResponse subclasses and declared CSV | Real media headers; CSV configured as text in Tonik | Pass | Pass | Typed product, typed 400 problem and literal CSV. |
| 201/204/404/422 | Declared statuses; native FastAPI validation schema | Real handlers, count constraint | Pass | Pass | Raw creation response is also checked for secret omission. |
| gzip | Standard GZip middleware | Threshold 1 byte | Enabled; not explicitly asserted | Enabled; not explicitly asserted | This is transport compression, separate from character encoding. |

Pydantic inheritance does not automatically provide the `allOf` example used in
the other stacks. Typed `application/json` multipart parts are covered by Spring;
ordinary FastAPI JSON body models cannot simply be combined with `File`/`Form`.
CSV and vendor JSON are explicit media declarations, and are not inferred from a
Python return annotation. Extended delimiter/deep-object/path styles and mixed
response-media alternatives remain follow-ups. No Tonik failure is skipped.

References: [FastAPI forms and files](https://fastapi.tiangolo.com/tutorial/request-forms-and-files/),
[Pydantic unions](https://docs.pydantic.dev/latest/concepts/unions/),
[Pydantic extra fields](https://docs.pydantic.dev/latest/api/config/#pydantic.config.ConfigDict.extra).
