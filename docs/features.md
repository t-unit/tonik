# Tonik Features Overview

Tonik is a Dart code generator for OpenAPI 3 specifications. This document provides a comprehensive overview of supported features.

## At a Glance

| Capability | What Tonik Does |
|------------|-----------------|
| **Multiple response types** | Generates a sealed class with a variant per status code and content type — the compiler enforces exhaustive handling, unlike generators that pick one success/error type and discard the rest |
| **Type composition** | `oneOf` → sealed class (switch on variants), `anyOf` → nullable fields, `allOf` → fields per member |
| **No name conflicts** | Schema names like `Error`, `Response`, `List` work without collisions |
| **Integer enums** | Full support, with optional unknown-value handling |
| **All encoding styles** | `simple`, `label`, `matrix`, `form`, `deepObject`, `spaceDelimited`, `pipeDelimited` |
| **readOnly / writeOnly** | Properties excluded from the correct serialization direction automatically |
| **Server variables** | URL templating with enum constraints and runtime substitution |
| **Pure Dart** | No Java, no Docker, no external tooling |

## Table of Contents

- [Tonik Features Overview](#tonik-features-overview)
  - [At a Glance](#at-a-glance)
  - [Table of Contents](#table-of-contents)
  - [How Generated Code Works](#how-generated-code-works)
    - [Architecture Overview](#architecture-overview)
    - [Custom Encoding \& Scoped Emission](#custom-encoding--scoped-emission)
    - [Naming Resolution](#naming-resolution)
    - [Response Handling](#response-handling)
  - [OpenAPI Version Support](#openapi-version-support)
  - [Schema Types](#schema-types)
  - [Schema Features](#schema-features)
    - [Composition](#composition)
    - [Supported Features](#supported-features)
    - [Not Supported](#not-supported)
  - [Parameters](#parameters)
    - [Locations](#locations)
    - [Encoding Styles](#encoding-styles)
  - [Request Bodies](#request-bodies)
    - [Content Types](#content-types)
  - [Responses](#responses)
  - [Operations](#operations)
  - [Servers](#servers)
    - [Server Variables](#server-variables)
  - [Tonik-Specific Features](#tonik-specific-features)
    - [Vendor Extensions](#vendor-extensions)
    - [Configuration](#configuration)
    - [Runtime Utilities](#runtime-utilities)

---

## How Generated Code Works

### Architecture Overview

Generated code uses [Dio](https://pub.dev/packages/dio) as the HTTP client. Each API operation is encapsulated in its own class for request building and response parsing.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   API Client    │────▶│   Operations    │────▶│      Dio        │
│  (per tag)      │     │ (per endpoint)  │     │  (HTTP layer)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                  ┌───────────────────────┐
                  │    Model Classes      │
                  │  (with built-in       │
                  │   encode/decode)      │
                  └───────────────────────┘
```

### Custom Encoding & Scoped Emission

Tonik generates its own encoding and decoding logic. This is key to two capabilities that packages like `freezed` cannot offer:

1. **Scoped code generation** - Using `DartEmitter.scoped()` from `code_builder`, Tonik properly qualifies type references. This means you can use `Error`, `List`, `Map` or `Response` as schema names without conflicts.

2. **Multi-context serialization** - Each model can serialize itself for JSON bodies, query parameters, path parameters, and headers—with full support for OpenAPI styles (`form`, `simple`, `label`, `matrix`, `deepObject`).

### Naming Resolution

Beyond scoped emission, Tonik also handles:

- **Unique identifiers** - Duplicate names get numeric suffixes
- **Dart-safe conversion** - Invalid characters stripped, proper casing applied
- **Naming based on position in document** - Inline schemas, parameters, etc. get naming to match their location in the api specification.

Override any generated name via `x-dart-name` or `tonik.yaml`. See [Configuration](configuration.md).

### Response Handling

Most OpenAPI code generators model responses as a single success type and a single error type — typically picking the 200 schema and the first error schema, discarding everything else. If your endpoint defines different bodies for 200, 201, 400, 404, and 500, those generators return something like `Result<Pet, ApiError>` and the caller has no typed access to the other response bodies.

Tonik takes a different approach: it generates a **sealed response class with a variant for every status code and content type** defined in the spec. The compiler enforces exhaustive handling, so you can't accidentally ignore a response case.

```dart
final response = await api.updatePet(body: pet);

switch (response) {
  // Network-level result
  case TonikSuccess(:final value):
    // Application-level response — every status code is a distinct type
    switch (value) {
      case UpdatePetResponse200(:final body):
        print('Updated: ${body.name}');
      case UpdatePetResponse400(:final body):
        print('Validation error: ${body.message}');
      case UpdatePetResponse404(:final body):
        print('Not found: ${body.detail}');
    }
  case TonikError(:final error, :final type):
    print('Failed: $type - $error');
}
```

This means:
- Every response body is deserialized into the correct type for its status code
- No casting, no runtime type checks, no untyped error strings
- Add or remove a response in your spec, regenerate, and the compiler flags every call site that needs updating
- Different content types on the same status code (e.g. JSON vs plain text) each get their own typed variant

Error types on `TonikError`: `encoding`, `decoding`, `network`, `other`.

---

## OpenAPI Version Support

| Version | Status | Notes |
|---------|--------|-------|
| OpenAPI 3.0.x | ✅ Fully Supported | |
| OpenAPI 3.1.x | ✅ Supported | Advanced JSON Schema keywords on [Roadmap](roadmap.md) |
| OpenAPI 3.2.x | Planned | See [Roadmap](roadmap.md) |
| OpenAPI 2.0 (Swagger) | ❌ Not Supported | Use a converter like swagger2openapi |

### Supported OAS 3.1 Features

- `$ref` with siblings — annotation siblings (`description`, `deprecated`) and structural siblings (`properties`, `allOf`/`oneOf`/`anyOf`). See [Data Types](data_types.md#ref-with-siblings-oas-31).
- `$defs` local definitions — inline schema definitions aligned with JSON Schema 2020-12. See [Data Types](data_types.md#defs-local-definitions-oas-31).
- Boolean schemas — `schema: true` → `Object?`, `schema: false` → `Never`. See [Data Types](data_types.md#boolean-schemas-oas-31).
- Nullable type arrays — `type: [string, "null"]` as the 3.1 replacement for `nullable: true`.
- `contentEncoding` / `contentMediaType` — content-encoded strings with configurable media type mapping.
- Version-aware multipart encoding — style-based encoding for 3.1, content-based for 3.0.

---

## Schema Types

Tonik maps OpenAPI types to idiomatic Dart types. See [Data Types](data_types.md) for the complete mapping table and details.

**Highlights:**
- `date-time` → `OffsetDateTime` (preserves timezone offset)
- `date` → `Date` (RFC3339)
- `decimal`/`currency`/`money` → `BigDecimal`
- `uri`/`url` → `Uri`
- `binary` → `List<int>`
- Enums → Generated Dart enums (string and integer)

---

## Schema Features

### Composition

| Feature | Status | Generated Pattern |
|---------|--------|-------------------|
| `allOf` | ✅ | Class with a field for each member schema |
| `oneOf` | ✅ | Sealed class with one subclass per variant |
| `anyOf` | ✅ | Class with nullable fields for each alternative |
| `discriminator` | ✅ | Used for JSON dispatch |
| Nested compositions | ✅ | Full support |

See [Composite Data Types](composite_data_types.md) for usage examples.

### Supported Features

| Feature | Status |
|---------|--------|
| `nullable` / `type: [T, null]` | ✅ |
| `required` array | ✅ |
| `description` | ✅ (preserved in docs) |
| `deprecated` | ✅ (configurable) |
| String & integer enums | ✅ |
| `x-dart-enum` | ✅ |
| Unknown enum case | ✅ (configurable) |
| Boolean schemas (`true`/`false`) | ✅ (OAS 3.1, see [Data Types](data_types.md#boolean-schemas-oas-31)) |
| `$ref` with siblings | ✅ (OAS 3.1, see [Data Types](data_types.md#ref-with-siblings-oas-31)) |
| `$defs` local definitions | ✅ (OAS 3.1) |
| `additionalProperties` | ✅ (see [Additional Properties](additional_properties.md)) |
| `readOnly` | ✅ (excluded from request serialization and parameter encoding) |
| `writeOnly` | ✅ (excluded from response deserialization) |

### Not Supported

Validation constraints (`minimum`, `maximum`, `pattern`, `minLength`, etc.) are parsed but not enforced at runtime. See [Roadmap](roadmap.md) for planned features.

---

## Parameters

### Locations

| Location | Status |
|----------|--------|
| `in: path` | ✅ |
| `in: query` | ✅ |
| `in: header` | ✅ |
| `in: cookie` | ✅ |

### Encoding Styles

**Path parameters:**

| Style | Example |
|-------|---------|
| `simple` (default) | `/users/john,doe` |
| `label` | `/users/.john.doe` |
| `matrix` | `/users/;id=john;id=doe` |

**Query parameters:**

| Style | Example |
|-------|---------|
| `form` (default) | `?color=blue&color=black` |
| `spaceDelimited` | `?color=blue%20black` |
| `pipeDelimited` | `?color=blue%7Cblack` |
| `deepObject` | `?filter%5Bcolor%5D=red` |

**Note:** Due to Dart's URI class, special characters are always percent-encoded. See [URI Encoding Limitations](uri_encoding_limitations.md).

---

## Request Bodies

### Content Types

| Content Type | Status | Notes |
|--------------|--------|-------|
| `application/json` | ✅ | Full model serialization |
| `application/x-www-form-urlencoded` | ✅ | Flat schemas only (format limitation) |
| `application/octet-stream` | ✅ | Binary data |
| `text/plain` | ✅ | String body |
| Custom types | ✅ | Via [config mapping](configuration.md#content-type-mapping) |
| `multipart/form-data` | ✅ | See [Multipart](multipart.md) |

See [Data Types](data_types.md#form-url-encoded-bodies) for examples.

---

## Responses

Each operation generates a sealed response class. Every status code and content type combination in the spec becomes a distinct subclass with its own typed body. This gives you compile-time exhaustiveness — the Dart analyzer will warn you if you don't handle a response case.

| Feature | Status |
|---------|--------|
| Distinct type per status code | ✅ |
| Distinct type per content type | ✅ |
| Exhaustive pattern matching | ✅ |
| Range codes (`2XX`, `4XX`) | ✅ |
| `default` response | ✅ |
| Response headers | ✅ |

---

## Operations

| Feature | Status |
|---------|--------|
| All HTTP methods | ✅ (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE) |
| `operationId` | ✅ (used for method naming) |
| `tags` | ✅ (used for API class grouping) |
| `deprecated` | ✅ |
| Operation-level `security` | ✅ (documented in comments) |

**Security:** Tonik documents security requirements but does not generate authentication code. Use `ServerConfig` interceptors. See [Authentication Guide](authentication.md).

---

## Servers

Tonik generates typed server classes from OpenAPI `servers` definitions, with full support for URL templating via server variables.

| Feature | Status |
|---------|--------|
| Multiple servers | ✅ |
| Server descriptions | ✅ (preserved in docs) |
| Server variables | ✅ |
| Variable defaults | ✅ |
| Variable enum constraints | ✅ (generates Dart enums) |
| Unconstrained variables | ✅ (String parameters) |

### Server Variables

Variables with `enum` constraints generate typed Dart enums. Unconstrained variables become `String` parameters with defaults.

```dart
// Switch regions at runtime
final api = PetApi(
  server: RegionalServer(region: RegionalServerRegion.euCentral),
);

// Or use a custom URL
final api = PetApi(
  server: CustomServer(baseUrl: 'http://localhost:3000'),
);
```

---

## Tonik-Specific Features

### Vendor Extensions

| Extension | Applies To |
|-----------|------------|
| `x-dart-name` | schemas, properties, operations, parameters, tags |
| `x-dart-enum` | enum value names |

### Configuration

Tonik supports an optional `tonik.yaml` for customizing code generation:

- **Name overrides** - Rename schemas, properties, operations, parameters, enums, tags
- **Filtering** - Include/exclude by tags, operations, or schemas
- **Deprecation handling** - `annotate`, `exclude`, or `ignore`
- **Content type mapping** - Map custom types to `json`, `form`, `text`, `bytes`
- **Enum unknown case** - Forward-compatible enum handling

See [Configuration](configuration.md) for full details and examples.

### Runtime Utilities

The `tonik_util` package provides runtime types:

- `Date` - RFC3339 date (YYYY-MM-DD)
- `OffsetDateTime` - Timezone-aware DateTime
- `TonikResult`, `TonikSuccess`, `TonikError` - Response handling
- `ServerConfig` - Dio configuration (interceptors, timeouts, adapters)
- Various tooling for encoding and decoding
