# Cookie Parameter Support Plan

Support for `in: cookie` parameters in OpenAPI specs, enabling the generator to encode cookie values and send them via the `Cookie` HTTP header.

## OpenAPI Spec Background

Per OpenAPI 3.x, cookie parameters:
- Use `in: cookie` location
- Default to `form` style encoding (the only valid style for cookies)
- Use `explode: false` by default
- Are sent in the `Cookie` HTTP header as `name1=value1; name2=value2`

## Implementation Steps

### Step 1: Add core model for cookie parameters

**Package:** `packages/tonik_core`

**Files to create:**
- `lib/src/model/cookie_parameter.dart`

**Contents:**
- `CookieParameterEncoding` enum with single value `form`
- `CookieParameter` sealed class
- `CookieParameterObject` class (following `QueryParameterObject` pattern)
- `CookieParameterAlias` class (following `QueryParameterAlias` pattern)

**Files to modify:**
- `lib/tonik_core.dart` — add export for `cookie_parameter.dart`
- `lib/src/model/operation.dart` — add `Set<CookieParameter> cookieParameters` field

### Step 2: Update request parameter importer

**Package:** `packages/tonik_parse`

**Files to modify:**
- `lib/src/request_parameter_importer.dart`:
  - Add `late Set<core.CookieParameter> cookieParameters` field
  - Initialize in `import()` method
  - Update `importOperationParameters` return tuple to include cookie parameters
  - Replace warning/skip logic for `ParameterLocation.cookie` with actual import logic
  - Add `_cookieEncoding()` helper that throws `ArgumentError` for non-form styles

### Step 3: Update operation importer

**Package:** `packages/tonik_parse`

**Files to modify:**
- `lib/src/operation_importer.dart`:
  - Update destructuring of `importOperationParameters` result to include `cookieParams`
  - Pass `cookieParameters: cookieParams` to `Operation` constructor

### Step 4: Fix all existing tests and code

**Packages:** `packages/tonik_core`, `packages/tonik_parse`, `packages/tonik_generate`

All existing `Operation` instantiations need `cookieParameters: {}` added. This includes:
- `content_type_normalizer.dart`
- Various test files in `tonik_core/test/`
- Various test files in `tonik_generate/test/`

### Step 5: Update code generators

**Package:** `packages/tonik_generate`

**Files to modify:**
- `lib/src/util/operation_parameter_generator.dart` — add cookie parameters to method signatures
- `lib/src/operation/options_generator.dart`:
  - Generate method parameters for cookies
  - Encode each value using existing `toForm` methods
  - Concatenate as `name1=value1; name2=value2`
  - Assign to `headers['Cookie']`
  - Throw `EncodingException` for complex types (lists, objects, composition)

### Step 6: Add integration test

**Location:** `integration_test/cookies/`

**Files to create:**
- `openapi.yaml` — OpenAPI spec with cookie parameters
- `cookies_test/` — test directory with Imposter mock and Dart tests

### Step 7: Update documentation

**Files to modify:**
- `docs/features.md` — change `❌ (roadmap)` to `✅` for `in: cookie`
- `docs/roadmap.md` — remove "Cookies" from roadmap list

## Design Decisions

1. **Style enforcement:** Throw `ArgumentError` for non-form styles (like headers with non-simple styles)
2. **Multiple cookies:** Concatenate as `name1=value1; name2=value2` per HTTP spec
3. **Complex types:** Support simple primitives only; throw `EncodingException` for lists, objects, composition types
4. **Response cookies:** Out of scope — `Set-Cookie` is just a regular response header

## Encoding Details

Cookie parameters use form-style encoding. The existing `toForm` methods in `tonik_util` handle this. No new encoding utilities needed.

For the `Cookie` header:
- Each cookie: `name=encodedValue`
- Multiple cookies: `name1=value1; name2=value2`
- Values are form-encoded (URL-encoded)
