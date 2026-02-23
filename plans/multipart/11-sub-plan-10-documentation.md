````markdown
# Sub-plan 10: Documentation Updates

## Context

After all generation sub-plans and the integration test are complete, update project documentation to reflect the new multipart/form-data support and its known limitations.

## TDD Exception

This sub-plan does not follow TDD — it contains only documentation changes with no testable code.

## Changes

### Modify: `docs/features.md`

Add `multipart/form-data` to the list of supported request body content types. Include:
- All supported property types (strings, primitives, enums, binary files, complex objects, arrays).
- Multi-content request body support (e.g., an operation accepting both JSON and multipart).
- Custom content type mapping to multipart via `tonik.yaml`.

### Modify: `docs/uri_encoding_limitations.md` (or create `docs/multipart_limitations.md`)

Document known multipart limitations:
- `style: deepObject` is not supported for complex object or array properties in multipart encoding. Generated code throws `UnsupportedError` at runtime.
- Per-part headers (`encoding.headers`) are not yet supported. A warning is logged during generation, and headers are omitted from the generated code.
- Custom multipart content types (e.g., `application/vnd.custom-multipart` mapped via `tonik.yaml`) lose their custom MIME type at runtime — Dio sets `Content-Type: multipart/form-data` with boundary regardless of the configured type.
- Non-form-data multipart subtypes (e.g., `multipart/mixed`) may not behave correctly for all features.
- Multipart response body decoding is not supported — generated code throws `ResponseDecodingException` at runtime.
- `additionalProperties` / map-type schemas are not supported globally (not multipart-specific).

## Verification

Review documentation for accuracy and completeness. No automated tests.

````
