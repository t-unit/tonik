# Configuration

Tonik supports an optional configuration file that allows you to customize code generation without modifying your OpenAPI specification. This is especially useful when working with third-party or auto-generated specs.

## Configuration File

Create a `tonik.yaml` file in your project root. Tonik will automatically look for this file in the current directory when you run the CLI:

```yaml
# tonik.yaml

# Basic settings (can also be set via CLI flags)
spec: ./openapi.yaml          # Path to OpenAPI document (--spec, -s)
outputDir: ./generated        # Output directory (--output-dir, -o)
packageName: my_api_client    # Package name (--package-name, -p)
logLevel: warn                # Log level: verbose, info, warn, silent (--log-level)

nameOverrides:
  schemas:
    # Remove unnecessary suffixes
    UserDTO: User
    GetUsersResponseBody: UserList
  
  properties:
    # Format: "SchemaName.propertyName": "newName"
    # Shorten verbose property names
    "User.unique_identifier": id
    "Order.order_line_items": items
  
  operations:
    # Simplify auto-generated operation IDs
    ApiV1UsersControllerGetUsers: listUsers
    ApiV1UsersControllerCreateUser: createUser
  
  parameters:
    # Format: "OperationId.parameterName": "newName"
    "listUsers.maximum_results": limit
  
  enums:
    # Format: "EnumName.VALUE": "newValue"
    # Fix awkward enum value names
    "Status.STATUS_ACTIVE": active
    "Priority.PRIORITY_HIGH": high

  tags:
    # Customizes the generated API class file names
    # Format: "TagName": "NewApiClassName"
    "User Management": UserApi
    "api/v1/pets": PetApi

# typeOverrides:
  # Reserved for future use

contentTypes:
  # Map custom content types to JSON serialization
  "application/problem+json": json
  "application/vnd.api+json": json
  "application/hal+json": json

filter:
  # Only generate code for specific parts of the spec
  includeTags:
    - Users
    - Orders
  excludeTags:
    - Internal
    - Deprecated
  excludeOperations:
    - legacyEndpoint
  excludeSchemas:
    - DeprecatedModel

deprecated:
  # How to handle deprecated operations, schemas, parameters, and properties
  # Options: annotate (default), exclude, ignore
  operations: annotate
  schemas: annotate
  parameters: annotate
  properties: annotate

enums:
  # Generate an unknown case for forward compatibility
  generateUnknownCase: true
  unknownCaseName: unknown
```

## CLI Options

All basic settings can be specified via CLI flags or in the config file. CLI flags take precedence over config file values. If a required option (like `--spec` or `--package-name`) is not provided via CLI or config file, Tonik will exit with an error.

```bash
# Using CLI flags only
tonik --spec ./openapi.yaml --output-dir ./generated --package-name my_api

# Using config file (tonik.yaml in current directory)
tonik

# Mix: config file with CLI override
tonik --output-dir ./other-location
```

| CLI Flag | Config Key | Description |
|----------|------------|-------------|
| `--spec`, `-s` | `spec` | Path to OpenAPI document (required) |
| `--output-dir`, `-o` | `outputDir` | Directory for generated code (defaults to `.`) |
| `--package-name`, `-p` | `packageName` | Name of the generated package (required) |
| `--log-level` | `logLevel` | Logging verbosity: `verbose`, `info`, `warn`, `silent` (defaults to `warn`) |

## Name Overrides

Name overrides let you customize how OpenAPI identifiers are converted to Dart identifiers. Tonik already converts identifiers to proper Dart casing (camelCase for members, PascalCase for types), so overrides are only needed when you want a completely different name.

Common use cases:

- Removing unnecessary suffixes like `DTO`, `Response`, `Model`
- Shortening verbose auto-generated names
- Resolving naming conflicts
- Using domain-specific terminology

### Schema Names

Rename top-level schemas defined in `#/components/schemas`:

```yaml
nameOverrides:
  schemas:
    # Remove unnecessary suffixes
    UserResponseDTO: User
    PaginatedUserListResponse: UserList
    # Resolve conflicts or clarify purpose
    Error: ApiError
```

**Before:**
```dart
class UserResponseDto { ... }  // Tonik already converts to PascalCase
class Error { ... }            // Conflicts with dart:core
```

**After:**
```dart
class User { ... }
class ApiError { ... }
```

### Property Names

Rename properties within a specific schema:

```yaml
nameOverrides:
  properties:
    # Shorten verbose names
    "User.user_unique_identifier": id
    "Order.order_line_items": items
    # Clarify ambiguous names
    "User.type": userType
```

The format is `"SchemaName.originalPropertyName": newPropertyName`.

> **Note:** Tonik automatically converts `snake_case` to `camelCase`, so `created_at` already becomes `createdAt`.

### Operation Names

Rename generated method names for API operations:

```yaml
nameOverrides:
  operations:
    # Simplify verbose auto-generated operationIds
    ApiV1UsersControllerGetAllUsers: listUsers
    UsersService_CreateNewUser: createUser
    # Fix unclear names
    get1: getUser
```

> **Note:** Tonik automatically converts `snake_case` to `camelCase`, so `get_users` already becomes `getUsers`.

### Parameter Names

Rename parameters for a specific operation:

```yaml
nameOverrides:
  parameters:
    # Shorten verbose names
    "listUsers.maximum_number_of_results": limit
    "getUser.user_identifier": userId
```

The format is `"OperationId.originalParameterName": newParameterName`.

> **Note:** Tonik automatically converts `snake_case` to `camelCase`, so `page_size` already becomes `pageSize`.

### Enum Value Names

Rename individual enum values:

```yaml
nameOverrides:
  enums:
    # Fix redundant prefixes
    "Status.STATUS_ACTIVE": active
    "Status.STATUS_INACTIVE": inactive
    # Handle special characters or numeric values
    "Priority.1": low
    "Priority.2": medium
    "Priority.3": high
```

The format is `"EnumName.ORIGINAL_VALUE": newValue`.

> **Note:** Tonik automatically converts `SCREAMING_CASE` to `camelCase`, so `PENDING_PAYMENT` already becomes `pendingPayment`.

### Tag Names (API Class Names)

Customize the generated API class names based on OpenAPI tags:

```yaml
nameOverrides:
  tags:
    # Handle path-like tags
    "api/v1/users": UserApi
    "/pets": PetApi
    # Simplify verbose tag names
    "User Management and Administration": UserApi
```

This controls the file and class names for the generated API clients.

> **Note:** Tonik automatically handles common formats like `pet-store` → `PetStoreApi`.

## Content Type Mapping

Map custom content types to built-in serialization:

```yaml
contentTypes:
  "application/problem+json": json
  "application/vnd.api+json": json
  "application/vnd.custom-form": form
  "text/csv": text
  "application/pdf": binary
```

Supported targets: `json`, `form`, `text`, `binary`.

## Filtering

Filter which parts of the OpenAPI spec to generate code for. This is useful for large specs where you only need a subset of the API.

```yaml
filter:
  includeTags:
    - Users
    - Orders
  excludeTags:
    - Internal
  excludeOperations:
    - legacyGetUsers
  excludeSchemas:
    - InternalConfig
```

- `includeTags`: Only generate operations with these tags (allowlist)
- `excludeTags`: Skip operations with these tags (denylist)
- `excludeOperations`: Skip specific operations by operationId
- `excludeSchemas`: Skip specific schemas by name

When both `includeTags` and `excludeTags` are specified, `includeTags` is applied first, then `excludeTags` filters the result.

## Deprecation Handling

Control how Tonik handles deprecated elements marked with `deprecated: true` in the OpenAPI spec.

```yaml
deprecated:
  operations: annotate   # annotate | exclude | ignore
  schemas: annotate      # annotate | exclude | ignore
  parameters: annotate   # annotate | exclude | ignore
  properties: annotate   # annotate | exclude | ignore
```

Options:
- `annotate` - Generate code with `@Deprecated` annotation (default)
- `exclude` - Skip generation entirely
- `ignore` - Generate code without any deprecation annotation

**Example:**
```yaml
deprecated:
  operations: exclude    # Don't generate deprecated API methods
  schemas: annotate      # Generate deprecated models with @Deprecated
  parameters: exclude    # Remove deprecated parameters from methods
  properties: annotate   # Keep deprecated properties with @Deprecated
```

### Important Limitations

**Cascade filtering is not automatic.** When excluding deprecated schemas, operations, or parameters:

1. **Excluding schemas** won't automatically exclude operations that reference them. You may get generation errors if a non-deprecated operation uses a deprecated (excluded) schema in its request or response.

2. **Excluding parameters** removes them from operation signatures but doesn't validate if the operation becomes invalid without them.

3. **Excluding properties** removes them from model classes but doesn't verify if the model becomes invalid (e.g., all required properties removed).

**Best practices:**
- Use `annotate` (default) for documentation purposes without breaking generation
- Use `exclude` carefully and ensure excluded elements aren't referenced elsewhere
- Test generated code after changing deprecation settings
- Consider using `filter.excludeOperations` or `filter.excludeSchemas` for explicit control

## Unknown Enum Case

For forward compatibility, Tonik can generate an additional `unknown` case for string enums. This prevents runtime errors when the API returns a new enum value that wasn't in the spec at generation time.

```yaml
enums:
  generateUnknownCase: true
  unknownCaseName: unknown  # default: "unknown"
```

**Without unknown case:**
```dart
enum Status {
  active,
  inactive,
}
```

**With unknown case:**
```dart
enum Status {
  active,
  inactive,
  unknown,
}
```

When deserializing, any unrecognized value will map to `unknown` instead of throwing an error.

## Vendor Extensions (Alternative)

In addition to the configuration file, Tonik also supports vendor extensions directly in your OpenAPI specification. These take precedence over configuration file settings when both are present.

```yaml
# In your OpenAPI spec
components:
  schemas:
    User:
      x-dart-name: AppUser  # Rename to avoid conflict with your domain model
      type: object
      properties:
        user_unique_identifier:
          x-dart-name: id  # Shorten verbose name
          type: string
    
    Status:
      type: string
      enum:
        - PENDING
        - IN_PROGRESS
      x-dart-enum: [pending, inProgress]
```

### Supported Vendor Extensions

| Extension | Applies To | Description |
|-----------|------------|-------------|
| `x-dart-name` | schemas, properties, operations, parameters | Override the generated Dart identifier |
| `x-dart-enum` | enums | Customize enum value names (array of strings mapping to enum values) |

## Precedence

When multiple customization sources exist, they are applied in this order (highest priority first):

1. Vendor extensions in the OpenAPI spec (`x-dart-*`)
2. Configuration file (`tonik.yaml`)
3. Default naming conventions

## Examples

### Working with a JSON:API Backend

```yaml
# tonik.yaml
contentTypes:
  "application/vnd.api+json": json

nameOverrides:
  schemas:
    UserResource: User
    UserResourceAttributes: UserAttributes
```

### Cleaning Up Auto-Generated Specs

```yaml
# tonik.yaml
nameOverrides:
  schemas:
    # Remove common suffixes
    UserDto: User
    OrderResponseModel: Order
    # Resolve naming conflicts
    Error: ApiError
    
  operations:
    # Simplify verbose auto-generated operationIds
    ApiV1UsersControllerGetAllUsers: listUsers
    ApiV1UsersControllerPostCreateUser: createUser
    
  enums:
    # Fix redundant prefixes from code generators
    "UserStatus.USER_STATUS_ACTIVE": active
    "UserStatus.USER_STATUS_INACTIVE": inactive
```

### Filtering a Large API

```yaml
# tonik.yaml
filter:
  includeTags:
    - Users
    - Authentication
  excludeOperations:
    - adminDeleteAllUsers

deprecated:
  operations: exclude
  schemas: exclude
```
