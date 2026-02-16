---
name: openapi-spec
description: >
  OpenAPI and JSON Schema specification reference. Auto-load when working on
  parsing logic in tonik_parse, schema handling, spec compliance, version
  differences, or implementing new OpenAPI features.
user-invocable: false
---

# OpenAPI Specification Reference

## Version Matrix

| OpenAPI | Latest Patch | JSON Schema Basis      | Nullability Mechanism        | tonik Support |
|---------|-------------|------------------------|------------------------------|---------------|
| 3.0.x   | 3.0.4       | JSON Schema Draft 04 (subset) | `nullable: true`             | Full          |
| 3.1.x   | 3.1.1       | JSON Schema Draft 2020-12     | `type: ["string", "null"]`   | Full          |
| 3.2.x   | 3.2.0       | JSON Schema Draft 2020-12     | `type: ["string", "null"]`   | Not supported |

## Canonical Spec URLs

### OpenAPI 3.0

- **HTML spec:** https://spec.openapis.org/oas/v3.0.4.html
- **GitHub markdown:** https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.4.md
- **JSON Schema for 3.0 documents:** https://spec.openapis.org/oas/3.0/schema/2024-10-18.html

### OpenAPI 3.1

- **HTML spec:** https://spec.openapis.org/oas/v3.1.1.html
- **JSON Schema for 3.1 documents:** https://spec.openapis.org/oas/3.1/schema/2025-09-15.html
- **OAS 3.1 JSON Schema dialect:** https://spec.openapis.org/oas/3.1/dialect/2024-11-10.html

### OpenAPI 3.2

- **HTML spec:** https://spec.openapis.org/oas/v3.2.0.html
- **JSON Schema for 3.2 documents:** https://spec.openapis.org/oas/3.2/schema/2025-09-17.html

### JSON Schema Draft 2020-12

- **Core:** https://json-schema.org/draft/2020-12/json-schema-core
- **Validation:** https://json-schema.org/draft/2020-12/json-schema-validation

## How to Fetch Spec Sections On Demand

Use WebFetch with a targeted prompt to extract exactly the section you need:

```
WebFetch(
  url: "https://spec.openapis.org/oas/v3.0.4.html",
  prompt: "Extract the full text of section 4.7.24 Schema Object, including all field tables and examples"
)
```

```
WebFetch(
  url: "https://spec.openapis.org/oas/v3.1.1.html",
  prompt: "Extract section 4.8.24 Schema Object including the JSON Schema dialect details"
)
```

### Section Index — OAS 3.0.4

| Section | Object                    |
|---------|---------------------------|
| 4.7.1   | OpenAPI Object            |
| 4.7.2   | Info Object               |
| 4.7.3   | Contact Object            |
| 4.7.4   | License Object            |
| 4.7.5   | Server Object             |
| 4.7.6   | Server Variable Object    |
| 4.7.7   | Components Object         |
| 4.7.8   | Paths Object              |
| 4.7.9   | Path Item Object          |
| 4.7.10  | Operation Object          |
| 4.7.11  | External Documentation    |
| 4.7.12  | Parameter Object          |
| 4.7.13  | Request Body Object       |
| 4.7.14  | Media Type Object         |
| 4.7.15  | Encoding Object           |
| 4.7.16  | Responses Object          |
| 4.7.17  | Response Object           |
| 4.7.18  | Callback Object           |
| 4.7.19  | Example Object            |
| 4.7.20  | Link Object               |
| 4.7.21  | Header Object             |
| 4.7.22  | Tag Object                |
| 4.7.23  | Reference Object          |
| 4.7.24  | Schema Object             |
| 4.7.25  | Discriminator Object      |
| 4.7.26  | XML Object                |
| 4.7.27  | Security Scheme Object    |
| 4.7.28  | OAuth Flows Object        |
| 4.7.29  | OAuth Flow Object         |
| 4.7.30  | Security Requirement      |

### Section Index — OAS 3.1.1

| Section | Object                    |
|---------|---------------------------|
| 4.8.1   | OpenAPI Object            |
| 4.8.2   | Info Object               |
| 4.8.3   | Contact Object            |
| 4.8.4   | License Object            |
| 4.8.5   | Server Object             |
| 4.8.6   | Server Variable Object    |
| 4.8.7   | Components Object         |
| 4.8.8   | Paths Object              |
| 4.8.9   | Path Item Object          |
| 4.8.10  | Operation Object          |
| 4.8.11  | External Documentation    |
| 4.8.12  | Parameter Object          |
| 4.8.13  | Request Body Object       |
| 4.8.14  | Media Type Object         |
| 4.8.15  | Encoding Object           |
| 4.8.16  | Responses Object          |
| 4.8.17  | Response Object           |
| 4.8.18  | Callback Object           |
| 4.8.19  | Example Object            |
| 4.8.20  | Link Object               |
| 4.8.21  | Header Object             |
| 4.8.22  | Tag Object                |
| 4.8.23  | Reference Object          |
| 4.8.24  | Schema Object             |
| 4.8.25  | Discriminator Object      |
| 4.8.26  | XML Object                |
| 4.8.27  | Security Scheme Object    |
| 4.8.28  | OAuth Flows Object        |
| 4.8.29  | OAuth Flow Object         |
| 4.8.30  | Security Requirement      |

## Key Differences Between Versions

### 3.0 → 3.1 (parser-relevant)

| Change | 3.0 | 3.1 | tonik Code |
|--------|-----|-----|------------|
| **Nullability** | `nullable: true` on schema | `type: ["string", "null"]` array | Both handled in `model_importer.dart` (~L375, L404-593); `schema.dart` has `_SchemaTypeConverter` (~L166) |
| **JSON Schema alignment** | Custom subset of Draft 04 | Full Draft 2020-12 | Type array parsing in `schema.dart` (~L98) |
| **`type` field** | Single string only | String or array of strings | `_SchemaTypeConverter` in `schema.dart` (~L166-183) |
| **`exclusiveMinimum`/`Maximum`** | Boolean modifier on `minimum`/`maximum` | Standalone numeric value | Not parsed — ignored per `schema.dart` (~L150) |
| **`$id` / `$anchor` / `$dynamicRef`** | Not present | Part of JSON Schema 2020-12 | Not parsed |
| **`webhooks`** | Not present | Top-level field | Not parsed |
| **`jsonSchemaDialect`** | Not present | Declares schema dialect | Not parsed |

### 3.1 → 3.2 (not yet supported by tonik)

| Change | Notes |
|--------|-------|
| `pathItems` in Components | Reusable path items |
| `summary` on more objects | Extended summary support |
| Broader `$ref` sibling keywords | More keywords allowed alongside `$ref` |

## Currently Unsupported Features

These spec features are explicitly ignored or throw errors in tonik. Do not assume they are available.

| Feature | Behavior | Code Location |
|---------|----------|---------------|
| `not` keyword | Warning logged, ignored | `model_importer.dart` ~L724-729 |
| External `$ref` | `UnimplementedError` thrown | `model_importer.dart` ~L97-101, ~L155, ~L248 |
| Direct self-references | `ArgumentError` thrown | `model_importer.dart` ~L257-261 |
| Parameter `content` field | `ArgumentError` thrown | `request_parameter_importer.dart` ~L233-238 |
| Header `content` field | Warning, defaults to StringModel | `response_header_importer.dart` ~L116-121 |
| Security scheme `$ref` | `UnimplementedError` thrown | `security_scheme_importer.dart` ~L47-50 |
| `callbacks` | Ignored | `components.dart` ~L37, `operation.dart` ~L43 |
| `links` | Ignored | `components.dart` ~L37, `response.dart` ~L23 |
| `examples` (object) | Ignored | `components.dart` ~L37, `media_type.dart` ~L18 |
| `example` field | Ignored | `header.dart` ~L33, `parameter.dart` ~L46 |
| `additionalProperties` | Ignored | `schema.dart` ~L150 |
| Validation keywords | Ignored | `schema.dart` ~L150 (`pattern`, `minLength`, `maxItems`, `minProperties`, etc.) |
| `xml` | Ignored | `schema.dart` ~L150 |
| `externalDocs` | Ignored | `operation.dart` ~L43, `tag.dart` ~L17 |
| `default` | Ignored | `schema.dart` ~L150 |
| `discriminator.mapping` | Parsed but may have limited codegen support | `schema.dart` |

### Version Detection

tonik detects the OpenAPI version string in `importer.dart` (~L103-114). It recognizes `3.0.*` and `3.1.*` prefixes. Unknown versions trigger a warning but parsing continues permissively.
