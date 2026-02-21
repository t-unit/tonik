# Sub-plan 0: Parse — Populate Default Encoding

## Context

Currently `RequestContent.encoding` is `null` when the OAS spec doesn't specify an `encoding` object. The generator would need to infer contentType defaults from the property's model type. Instead, the parse layer should populate defaults so the generator just reads encoding.

## OAS Default Rules

Per OAS 3.0.4 §4.7.15.1.1 and OAS 3.1.1 §4.8.15.1.1, the default `contentType` for multipart properties is determined by the **property schema type** (identical in both versions):

| Property Schema | Default `contentType` |
|---|---|
| `string` with binary format/encoding (`BinaryModel`) | `application/octet-stream` |
| `string` (no binary) (`StringModel`) | `text/plain` |
| `number`, `integer`, `boolean` (`IntegerModel`, `DoubleModel`, `NumberModel`, `BooleanModel`) | `text/plain` |
| `DateTimeModel`, `DateModel`, `DecimalModel`, `UriModel` | `text/plain` |
| `EnumModel` | `text/plain` |
| `AnyModel` (untyped / `{}` schema) | `text/plain` |
| `object` (`ClassModel`, `AllOfModel`, `OneOfModel`, `AnyOfModel`) | `application/json` |
| `array` (`ListModel`) | according to the `items` schema type (see recursive resolution below) |
| `NeverModel` | `text/plain` (will error at generation time regardless) |

When `encoding` IS specified but `contentType` is null, same defaults apply.

### Recursive Resolution for Arrays and Aliases

The `items` schema type for arrays requires recursive resolution:

1. **`AliasModel`**: Unwrap via `.resolved` and recurse into the resolved model type.
2. **`ListModel` (nested array)**: Recurse into the nested `ListModel.content` items schema.
3. **`AnyModel`**: Resolves to `text/plain` (consistent with scalar `.toString()` serialization).
4. **All other types**: Apply the table above directly.

The resolution function should be a private helper (e.g., `_resolveDefaultContentType(Model model)`) that handles `AliasModel` unwrapping and `ListModel` recursion in a single recursive function. This same function is used for all property types (not just arrays), so `AliasModel` unwrapping is handled uniformly.

Default `style` is `form`, default `explode` is `true`.

**Critical — version-aware normalization**: The parser MUST fully abstract OAS version differences so the generator never needs to know the spec version. This is the core contract of `tonik_core` domain models.

- **OAS 3.0** (§4.7.15.1.2): `style`, `explode`, and `allowReserved` SHALL be **ignored** for multipart. The parser must **force** `style: form`, `explode: true`, `allowReserved: false` on every multipart encoding entry — regardless of what the spec declares. Any explicit `style`/`explode`/`allowReserved` values in the OAS 3.0 encoding object are discarded.
- **OAS 3.1** (§4.8.15.1.2): `style`, `explode`, and `allowReserved` DO apply to multipart. The parser reads them from the encoding object and fills in defaults (`style: form`, `explode: true`, `allowReserved: false`) for any nulls.

This way the generator just reads `encoding.style` and `encoding.explode` and acts on them blindly — no version awareness needed.

## Changes

### `packages/tonik_parse/lib/src/request_body_importer.dart`

**Version access**: Use `openApiObject.openapi` (already accessible via `RequestBodyImporter`'s constructor field) to detect OAS 3.0 vs 3.1.

**Guard**: Only apply this logic when `contentType == ContentType.multipart` — do NOT apply to `ContentType.form` (form-urlencoded has its own encoding path).

After creating `RequestContent` with `contentType == multipart`, populate default encoding for each property of the schema model **only if it's a `ClassModel`** (non-ClassModel multipart bodies like bare `BinaryModel` don't have per-property encoding):

1. Resolve the model — if it's an `AliasModel`, resolve to the underlying model.
2. If the resolved model is NOT a `ClassModel`, skip encoding population (leave `encoding` as-is or set to empty map).
3. For each property in the ClassModel:
   - Determine the default `contentType` based on the property's model type (see table above).
   - If no encoding entry exists for this property, create one with defaults.
   - If encoding entry exists but `contentType` is null, fill in the default.
   - Determine `style`, `explode`, and `allowReserved` based on OAS version:
     - **OAS 3.0**: Always set `style: form`, `explode: true`, `allowReserved: false` (spec says these SHALL be ignored for multipart — parser enforces this by overwriting any explicit values).
     - **OAS 3.1**: Use explicit values from encoding if present, otherwise default to `style: form`, `explode: true`, `allowReserved: false`.
4. Include ALL properties in the encoding map (including `readOnly` and `writeOnly`). The generator is responsible for filtering `readOnly` properties during serialization. Keeping the encoding map complete preserves metadata (e.g., per-part headers) for potential future use.
5. The encoding map on `RequestContent` should always be non-null for multipart ClassModel bodies.
6. Ignore encoding keys that don't match any property on the ClassModel (log a warning for mismatches).

**Note**: Existing parser tests that assert `encoding: null` for multipart bodies without explicit encoding will need to be updated — they should now expect populated default encoding maps.

### `packages/tonik_parse/test/request_body_importer_test.dart`

**TDD: Write these tests first, then implement.**

Add tests:
- Multipart body with string property -> gets `text/plain`
- Multipart body with integer/boolean property -> gets `text/plain`
- Multipart body with binary property -> gets `application/octet-stream`
- Multipart body with object property -> gets `application/json`
- Multipart body with AnyModel property -> gets `text/plain`
- Multipart body with array of objects -> gets `application/json` (from items)
- Multipart body with array of strings -> gets `text/plain` (from items)
- Multipart body with array of arrays of strings (nested) -> gets `text/plain` (recursive resolution)
- Multipart body with array of AnyModel -> gets `text/plain` (from items)
- Multipart body with AliasModel wrapping a string -> gets `text/plain` (alias unwrapping)
- Multipart body with explicit encoding (OAS 3.1) -> explicit `contentType` preserved, explicit `style`/`explode` preserved, nulls filled with defaults
- Multipart body with explicit `style`/`explode` (OAS 3.0) -> explicit values **discarded**, forced to `style: form`, `explode: true` (spec says SHALL be ignored)
- Multipart body without schema (BinaryModel fallback) -> encoding left as-is, no crash
- Multipart body with readOnly properties -> readOnly properties INCLUDED in encoding map (generator filters them during serialization)
- Multipart body with writeOnly properties -> writeOnly properties INCLUDED in encoding map
- Multipart body with `format: byte` string property (base64 in OAS 3.0) -> gets `text/plain` (this is a `StringModel`, NOT `BinaryModel` — only `format: binary` produces `BinaryModel`)
- `ContentType.form` body -> encoding defaults NOT applied (guard check)
- Encoding keys that don't match any ClassModel property -> warning logged, keys ignored

**CHECKPOINT**: Wait for user confirmation before implementing.

## Key Files
- `packages/tonik_parse/lib/src/request_body_importer.dart` (lines 111-130 — encoding extraction)
- `packages/tonik_parse/lib/src/model/encoding.dart`
- `packages/tonik_core/lib/src/model/multipart_property_encoding.dart`
- `packages/tonik_parse/lib/src/importer.dart` (line 104 — version detection)

## Verification
```
dart test packages/tonik_parse/test/request_body_importer_test.dart
dart analyze packages/tonik_parse
```
