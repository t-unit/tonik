# Roadmap

- Proper OpenAPI 3.2 support
  - Optional Response Object `description` and support for `summary`
  - Sequential media beyond [typed NDJSON, JSONL, JSON-seq, and SSE responses](streaming_responses.md): non-streaming array decoding without `itemSchema` using normal `schema` handling, and streamed requests and multipart streams
  - Parameter and header encoding/decoding via `content` for supported media types
  - `in: "querystring"` parameter location (entire query string as single parameter)
  - `query` HTTP method on Path Item Object (IETF draft `QUERY` method)
  - `additionalOperations` map for non-standard HTTP methods (e.g., `COPY`, `MOVE`)
  - `style: "cookie"` serialization with semicolon separators and no automatic percent-encoding
  - `allowReserved` for applicable parameter styles beyond query parameters, preserving path restrictions
  - Same-document Media Type Object reference targets outside `components.mediaTypes`
  - Nested Encoding Objects using named `encoding`
  - `defaultMapping` on Discriminator for missing or unknown discriminator values
  - Security metadata: `deviceAuthorization` OAuth2 flow (RFC 8628), `deviceAuthorizationUrl`, `oauth2MetadataUrl`, and scheme deprecation (documentation only)
  - Same-document URI references in Security Requirement Objects
  - `$self` document identity for same-document reference resolution
  - Tag enhancements (`summary`, `parent`, `kind` for hierarchies)
  - Server Object `name` metadata
  - Inline Example Object `serializedValue` rendering alongside existing `value` and `dataValue` support
- Advanced OpenAPI 3.1 features (core 3.1 support is shipped — see [Features](features.md#supported-oas-31-features)):
  - Support for `if/then/else` schemas (via custom encoding/decoding checks)
  - Support for `const` schemas
  - `prefixItems` for tuple validation
  - `dependentRequired` / `dependentSchemas`
  - `patternProperties` for regex-matched property schemas
  - `propertyNames` for property name validation
- Supporting the `not` keyword
- `server` overrides in operations and paths

## Non-goals

**Validation**:
- `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`
- `minLength`, `maxLength`, `pattern`
- `minItems`, `maxItems`, `uniqueItems`
- `minProperties`, `maxProperties`
- `contains`, `minContains`, `maxContains`

**Encoding & Content:**
- XML de- and encoding
- `prefixEncoding` / `itemEncoding` on Media Type and Encoding Objects, including positional multipart encoding

**References:**
- External/remote `$ref` references (to other files or URLs)
- `$id`, `$anchor` for schema identification (not needed without external refs)
- `$dynamicRef`, `$dynamicAnchor` (advanced JSON Schema feature)

**Advanced JSON Schema:**
- `unevaluatedProperties`, `unevaluatedItems`

**Examples:**
- Example Object `externalValue` URL fetching - external example resolution requires network access at build time; inline `value` and `dataValue` examples are supported

**Other:**
- Direct security/authentication code generation - authentication is configured on the selected HTTP client (see [Authentication Guide](authentication.md))
- Code generation for [webhooks](https://spec.openapis.org/oas/v3.1.0.html#oasWebhooks) - server→client callbacks, not relevant for client libs
- Callback Objects - server→client callbacks, same as webhooks
- Link Objects - HATEOAS navigation metadata, rarely used in practice
