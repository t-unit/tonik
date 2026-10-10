# Roadmap

- Proper OpenAPI 3.2 support
  - Sequential media beyond [typed NDJSON, JSONL, and SSE responses](streaming_responses.md): non-streaming array decoding without `itemSchema` using normal `schema` handling, other formats such as `application/json-seq`, and streamed requests and multipart streams
  - Parameter and header encoding/decoding via `content` for supported media types
  - `in: "querystring"` parameter location (entire query string as single parameter)
  - `query` HTTP method on Path Item Object (IETF draft `QUERY` method)
  - `additionalOperations` map for non-standard HTTP methods (e.g., `COPY`, `MOVE`)
  - Media Type Object reference targets outside `components.mediaTypes`
  - `prefixEncoding` / `itemEncoding` for positional multipart encoding
  - `defaultMapping` on Discriminator for unknown discriminator values
  - `deviceAuthorization` OAuth2 flow (RFC 8628)
  - Tag enhancements (`summary`, `parent`, `kind` for hierarchies)
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

**References:**
- External/remote `$ref` references (to other files or URLs)
- `$id`, `$anchor` for schema identification (not needed without external refs)
- `$dynamicRef`, `$dynamicAnchor` (advanced JSON Schema feature)

**Advanced JSON Schema:**
- `unevaluatedProperties`, `unevaluatedItems`

**Examples:**
- Example Object `externalValue` URL fetching - external example resolution requires network access at build time; only inline `value` examples are supported

**Other:**
- Direct security/authentication code generation - authentication is configured on the selected HTTP client (see [Authentication Guide](authentication.md))
- Code generation for [webhooks](https://spec.openapis.org/oas/v3.1.0.html#oasWebhooks) - server→client callbacks, not relevant for client libs
- Callback Objects - server→client callbacks, same as webhooks
- Link Objects - HATEOAS navigation metadata, rarely used in practice
