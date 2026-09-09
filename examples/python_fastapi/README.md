# FastAPI + Pydantic

From the repository root ([setup](../README.md#run)):

```sh
./examples/run.sh python_fastapi
```

[app.py](server/app.py) uses FastAPI 0.141.1 and Pydantic 2.13.5 to produce
OpenAPI 3.1 from Python models and route declarations. Runtime dependencies are
pinned in [requirements.txt](server/requirements.txt).

Alongside the common catalog, forms, files and charset examples, this server
covers optional/batch uploads, recursive categories, native validation errors,
vendor JSON, problem+json and CSV.

- Pydantic's discriminated union produces `oneOf`; an ordinary union produces
  `anyOf`. Contact alternatives use `extra='allow'` so an object containing both
  email and phone keeps both fields.
- Form bytes are captured before parsing so the receipt can show the original
  encoding. Files use FastAPI's normal `UploadFile` handling.
- Upload annotations retain `format: binary` alongside FastAPI's
  `contentMediaType` so Tonik generates file parameters for single, optional and
  batch uploads.
- Typed JSON multipart parts are demonstrated in the Spring example. FastAPI
  cannot simply combine an ordinary JSON request body with `File`/`Form`.

See the [Dart demo](client/bin/example.dart), [live tests](client/test/live_test.dart),
and [FastAPI forms documentation](https://fastapi.tiangolo.com/tutorial/request-forms-and-files/).
