# Sub-plan 7: Generate — Per-Part Headers (Limited Scope)

## Context

The OAS encoding object allows specifying custom headers per multipart part via `encoding.headers`. Per the spec, `encoding.headers` contains a `Map[string, Header Object | Reference Object]` — these are **schema definitions** of headers (with types, required flags, etc.), NOT literal values to inject.

This means header values must come from somewhere at runtime. The OAS spec does not define how these values are supplied by the caller — they are meant to describe the *structure* of the part headers.

## Analysis

There are three viable approaches:

### Option A: Expose header parameters on the generated method (recommended)
For each property that has `encoding.headers`, add corresponding parameters to the generated API method so callers can provide header values:
```dart
Future<Response> uploadFile({
  required List<int> file,
  int? xRateLimitLimit,  // from encoding.headers
}) async { ... }
```
This is correct but significantly changes the method signature and requires wiring header values through to the FormData construction.

### Option B: Ignore per-part headers with a warning
Log a warning during generation when `encoding.headers` is present, and skip header generation. Document as a known limitation.

### Option C: Defer entirely
Leave `encoding.headers` unprocessed. The parsing layer already captures the data; generation can be added later.

## Decision

**Go with Option C (defer)** for the initial multipart release. Per-part headers are rare in practice. The parsing layer already captures `encoding.headers` correctly. The generation layer should:
1. Not crash when `encoding.headers` is present.
2. Log a warning during generation that per-part headers are not yet supported.
3. Generate the multipart code without the headers.

This can be revisited as a follow-up feature when there's real demand.

## Changes

### Modify: `to_multipart_expression_generator.dart`

When `encoding.headers` is non-null and non-empty for a property, log a warning and proceed without generating header parameters. Do not crash.

### Modify: `to_multipart_expression_generator_test.dart`

**TDD: Write these tests first, then implement.**

Tests:
- Property with per-part headers -> generates valid code without headers, no crash
- Warning is logged when headers are present (use a `Logger.root.onRecord` listener or inject a mock `Logger` to capture log records and verify the warning message)

**CHECKPOINT**: Wait for user confirmation before implementing.

## Verification
```
dart test packages/tonik_generate/test/src/util/to_multipart_expression_generator_test.dart
dart analyze packages/tonik_generate
```
