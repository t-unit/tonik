# Rails API + rswag

```sh
./examples/run.sh ruby_rails --backend both
```

Ruby 3.4.5, Rails 8.0.2.1, rswag-api/rswag-specs 2.16.0, RSpec Rails 7.1.1 and Puma
7.0.2 are pinned in `Gemfile`/`Gemfile.lock`. The lock includes Linux ARM64 and
x86-64 platforms. The API-only app loads Action Controller without a database.

rswag is a spec-driven producer: schemas and operations are normal request-spec
metadata. Docker builds run `RSWAG_DRY_RUN=0 rake rswag:specs:swaggerize`, which
executes the request specs and exports **OpenAPI 3.0.3**. Zero discovered specs
fail through RSpec's configuration. A separate live Puma process then serves
that generated document at `/openapi.json` and receives the Dart requests.

The standalone Dart client contains 20 explicit tests; the build also executes
15 explicit Rails request specs. Both Dart backends passed against the live server.

| Case | Producer behavior | Runtime/parser setup | Dio | HTTP | Limitation/evidence |
| --- | --- | --- | --- | --- | --- |
| JSON/formats/maps/null | rswag schema metadata | Rails JSON parsing/rendering | Pass | Pass | Explicit request specs and Dart assertions. |
| Path/query/header/cookie | rswag parameters | Rack brackets, Rails cookie jar | Pass | Pass | `tags[]` is the real parameter name, so Rack parses repeated arrays. |
| URL-encoded form | rswag formData metadata becomes OAS3 requestBody | Rack form parser | Pass | Pass | Raw form body is returned separately. |
| Multipart file/scalars | rswag formData metadata | Rack UploadedFile | Pass | Pass | Real file bytes, names, media and zero-byte path files. |
| Binary/four charsets | Response schema/media metadata | send_data with Ruby String encoding | Pass | Pass | Request specs compare raw bytes for non-JSON responses. |
| `oneOf` | Explicit discriminated alternatives | Controller validates demonstrated payment shapes | Pass | Pass | Both variants; card echo. |
| Overlapping `anyOf` | Explicit alternatives | Controller permits either or both fields | Pass | Pass | Both fields must survive on the wire. |
| `allOf` | Product/Audit schema references | Flat JSON hash | Pass | Pass | Both generated constituent models are checked. |
| 201/204/404 | rswag response declarations | Rails status/rendering | Pass | Pass | Raw creation response checks secret omission. |
| gzip | Rack::Deflater | Standard compression middleware | Enabled; not explicitly asserted | Enabled; not explicitly asserted | Middleware setup only; negotiation is not asserted. |

rswag 2.16 promotes the first body/formData schema into the OpenAPI request body,
while its request builder submits individual formData fields. The request specs
therefore declare the full FormFields/UploadFields body schema first, followed by
the formData fields used in executed requests. Both declarations describe the
same real form; no generated document is modified.

rswag's request builder does not populate the cookie jar from an `in: cookie`
parameter; the request spec sets the actual Rails cookie jar explicitly. For
formData, Rack::Test appends `[]` to Ruby array names, so the request spec supplies
one literal bracketed wire field; Dart verifies multiple array elements using
the emitted array schema. This avoids claiming that unbracketed repeated keys
have Rack array semantics.

Binary/text request specs use explicit byte assertions because rswag's ordinary
response-schema matcher expects JSON. Typed JSON multipart parts, file arrays,
native validation payloads and extended parameter styles remain follow-ups.

References: [rswag](https://github.com/rswag/rswag),
[Rails API applications](https://guides.rubyonrails.org/api_app.html),
[Rack](https://github.com/rack/rack).
