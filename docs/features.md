# Tonik Features Overview

Tonik is a Dart code generator for OpenAPI 3 specifications. This document provides a comprehensive overview of supported features.

## At a Glance

| Capability | What Tonik Does |
|------------|-----------------|
| **Multiple response types** | Generates distinct classes per status code (200, 400, 404) and content type—use pattern matching to handle each |
| **Type composition** | `oneOf` → sealed class (switch on variants), `anyOf` → nullable fields, `allOf` → fields per member |
| **No name conflicts** | Schema names like `Error`, `Response`, `List` work without collisions |
| **Integer enums** | Full support, with optional unknown-value handling |
| **All encoding styles** | `simple`, `label`, `matrix`, `form`, `deepObject`, `spaceDelimited`, `pipeDelimited` |
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

All API calls return a discriminated union (`TonikResult`) for type-safe error handling:

```dart
final response = await api.getPetById(petId: 1);
switch (response) {
  case TonikSuccess(:final value):
    print('Pet: ${value.name}');
  case TonikError(:final error, :final type):
    print('Failed: $type - $error');
}
```

Error types: `encoding`, `decoding`, `network`, `other`.

---

## OpenAPI Version Support

| Version | Status | Notes |
|---------|--------|-------|
| OpenAPI 3.0.x | ✅ Fully Supported | |
| OpenAPI 3.1.x | Partially Supported | See [Roadmap](roadmap.md) |
| OpenAPI 3.2.x | Planned | See [Roadmap](roadmap.md) |
| OpenAPI 2.0 (Swagger) | ❌ Not Supported | Use a converter like swagger2openapi |

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
| `in: cookie` | ❌ (roadmap) |

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
| `multipart/form-data` | ❌ | roadmap |

See [Data Types](data_types.md#form-url-encoded-bodies) for examples.

---

## Responses

| Feature | Status |
|---------|--------|
| Explicit status codes | ✅ |
| Range codes (`2XX`, `4XX`) | ✅ |
| Multiple status codes | ✅ |
| `default` response | ✅ |
| Response headers | ✅ |
| Multiple content types | ✅ |

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
