# Simple Encoding Integration Test Plan

This document is a structured plan for an LLM to generate integration tests for the simple_encoding OpenAPI spec. Each task is atomic and includes all information needed for implementation.

## CONTEXT

### Test Infrastructure
- **Test directory**: `/Users/tobi/Code/tonik/integration_test/simple_encoding/simple_encoding_test/test/`
- **Generated API package**: `simple_encoding_api` (import as `package:simple_encoding_api/simple_encoding_api.dart`)
- **Port**: 8085
- **Base URL**: `http://localhost:8085/v1`

### Test File Template
Every test file MUST follow this exact structure:

```dart
import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8085;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  SimpleEncodingApi buildApi({required String responseStatus}) {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  // Tests go here
}
```

### Roundtrip Test Pattern
For header roundtrip tests, verify:
1. The request header was encoded correctly: `success.response.requestOptions.headers['header-name']`
2. The response header was decoded correctly: `success.value.propertyName`

### Success Response Pattern
```dart
expect(result, isA<TonikSuccess<ResponseType>>());
final success = result as TonikSuccess<ResponseType>;
expect(success.response.statusCode, 200);
```

### Error Response Pattern (for encoding failures)
```dart
expect(result, isA<TonikError<ResponseType>>());
final error = result as TonikError<ResponseType>;
expect(error.type, TonikErrorType.encoding);
expect(error.error, isA<EncodingException>());
```

---

## COVERAGE STATUS

### ✅ ALREADY COVERED (DO NOT CREATE)
| Endpoint | Test File |
|----------|-----------|
| `testHeaderRoundtripPrimitives` | `header_roundtrip_primitives_test.dart` |
| `testHeaderRoundtripEnums` | `header_roundtrip_enums_test.dart` |
| `testHeaderRoundtripSimpleLists` | `header_roundtrip_simple_lists_test.dart` |
| `testHeaderRoundtripEnumLists` | `header_roundtrip_enum_lists_test.dart` |
| `testHeaderRoundtripObjects` | `header_roundtrip_objects_test.dart` |
| `testHeaderRoundtripOneOfDiscriminated` | `header_roundtrip_oneof_discriminated_test.dart` |
| `testHeaderRoundtripOneOfPrimitive` | `header_roundtrip_oneof_primitive_test.dart` |
| `testHeaderRoundtripOneOfComplex` | `header_roundtrip_oneof_complex_test.dart` |
| `testAnyOfInPath` | `simple_test.dart` |
| `testAnyOfCompositeInPath` | `simple_test.dart` |
| `testPrimitiveInPath` | `simple_test.dart` |
| `testComplexInPath` | `simple_test.dart` |
| `testAllOfInPath` | `simple_test.dart` |
| `testListInPath` | `simple_test.dart` |
| `testAliasesInPath` | `simple_test.dart` |

### ❌ NOT COVERED (TASKS BELOW)

---

## TASK 1: header_roundtrip_oneof_enum_test.dart

**File**: `header_roundtrip_oneof_enum_test.dart`
**Endpoint**: `testHeaderRoundtripOneOfEnum`
**API Method**: `api.testHeaderRoundtripOneOfEnum(enumUnion: ...)`
**Response Type**: `HeadersRoundtripOneofEnumGet200Response`
**Header Name**: `X-Enum-Union`
**Response Property**: `xEnumUnion`

**Schema** (`OneOfEnum`):
```yaml
oneOf:
  - $ref: '#/components/schemas/StatusEnum'   # string: active|inactive|pending|archived
  - $ref: '#/components/schemas/PriorityEnum' # integer: 1|2|3|4|5
```

**Test Cases**:
1. `StatusEnum.active` roundtrip - verify encoded as `active`, decoded as `OneOfEnumStatusEnum(StatusEnum.active)`
2. `StatusEnum.pending` roundtrip
3. `PriorityEnum.one` roundtrip - verify encoded as `1`, decoded as `OneOfEnumPriorityEnum(PriorityEnum.one)`
4. `PriorityEnum.five` roundtrip
5. `null` parameter - verify header not sent, response property is null

**IMPORTANT**: Integer enum values (1,2,3,4,5) when sent as headers may be decoded as the string variant due to ambiguity. Test actual behavior and document it.

---

## TASK 2: header_roundtrip_anyof_primitive_test.dart

**File**: `header_roundtrip_anyof_primitive_test.dart`
**Endpoint**: `testHeaderRoundtripAnyOfPrimitive`
**API Method**: `api.testHeaderRoundtripAnyOfPrimitive(flexibleValue: ...)`
**Response Type**: `HeadersRoundtripAnyofPrimitiveGet200Response`
**Header Name**: `X-Flexible-Value`
**Response Property**: `xFlexibleValue`

**Schema** (`AnyOfPrimitive`):
```yaml
anyOf:
  - type: string
  - type: integer
  - type: boolean
```

**Test Cases**:
1. String value `'hello'` roundtrip
2. String with spaces `'hello world'` - verify URL encoding
3. Integer positive `42` roundtrip
4. Integer zero `0` roundtrip
5. Integer negative `-123` roundtrip
6. Boolean `true` roundtrip
7. Boolean `false` roundtrip
8. `null` parameter - verify null response
9. Empty string - expect encoding error (EmptyValueException)

**NOTE**: AnyOf uses wrapper constructors like `AnyOfPrimitive(string: 'value')` or `AnyOfPrimitive(int: 42)` or `AnyOfPrimitive(bool: true)`.

---

## TASK 3: header_roundtrip_anyof_complex_test.dart

**File**: `header_roundtrip_anyof_complex_test.dart`
**Endpoint**: `testHeaderRoundtripAnyOfComplex`
**API Method**: `api.testHeaderRoundtripAnyOfComplex(flexibleObject: ...)`
**Response Type**: `HeadersRoundtripAnyofComplexGet200Response`
**Header Name**: `X-Flexible-Object`
**Response Property**: `xFlexibleObject`

**Schema** (`AnyOfComplex`):
```yaml
anyOf:
  - $ref: '#/components/schemas/Class1'  # { name: string (required) }
  - $ref: '#/components/schemas/Class2'  # { number: integer (required) }
```

**Test Cases**:
1. Class1 with simple name roundtrip - encoded as `name,value`
2. Class1 with spaces in name - verify URL encoding
3. Class2 with positive number roundtrip
4. Class2 with zero roundtrip
5. Class2 with negative number roundtrip
6. `null` parameter - verify null response
7. Class1 with empty name - expect encoding error

**NOTE**: Use `AnyOfComplex(class1: Class1(name: 'test'))` or `AnyOfComplex(class2: Class2(number: 42))`.

---

## TASK 4: header_roundtrip_anyof_mixed_test.dart

**File**: `header_roundtrip_anyof_mixed_test.dart`
**Endpoint**: `testHeaderRoundtripAnyOfMixed`
**API Method**: `api.testHeaderRoundtripAnyOfMixed(mixedValue: ...)`
**Response Type**: `HeadersRoundtripAnyofMixedGet200Response`
**Header Name**: `X-Mixed-Value`
**Response Property**: `xMixedValue`

**Schema** (`FlexibleValue`):
```yaml
anyOf:
  - type: string
  - type: integer
  - type: boolean
  - $ref: '#/components/schemas/SimpleObject'  # { name?: string, value?: integer }
```

**Test Cases**:
1. String value roundtrip
2. Integer value roundtrip
3. Boolean value roundtrip
4. SimpleObject with both fields `SimpleObject(name: 'test', value: 42)` - encoded as `name,test,value,42`
5. SimpleObject with only name
6. SimpleObject with only value
7. `null` parameter

**NOTE**: Use `FlexibleValue(string: ...)`, `FlexibleValue(int: ...)`, `FlexibleValue(bool: ...)`, `FlexibleValue(simpleObject: ...)`.

---

## TASK 5: header_roundtrip_allof_simple_test.dart

**File**: `header_roundtrip_allof_simple_test.dart`
**Endpoint**: `testHeaderRoundtripAllOfSimple`
**API Method**: `api.testHeaderRoundtripAllOfSimple(compositeEntity: ...)`
**Response Type**: `HeadersRoundtripAllofSimpleGet200Response`
**Header Name**: `X-Composite-Entity`
**Response Property**: `xCompositeEntity`

**Schema** (`CompositeEntity`):
```yaml
allOf:
  - $ref: '#/components/schemas/BaseEntity'      # { name: string (required), description?: string }
  - $ref: '#/components/schemas/TimestampMixin'  # { created_at: datetime (required), updated_at?: datetime }
  - type: object
    properties:
      specific_field: string (required)
```

**Test Cases**:
1. All required fields only roundtrip
2. All fields including optional roundtrip
3. Verify datetime encoding format (ISO 8601)
4. `null` parameter

**NOTE**: CompositeEntity constructor takes `baseEntity`, `timestampMixin`, and `compositeEntityModel` parameters.
```dart
CompositeEntity(
  baseEntity: BaseEntity(name: 'Test', description: 'Desc'),
  timestampMixin: TimestampMixin(createdAt: DateTime.utc(2024, 1, 15)),
  compositeEntityModel: CompositeEntityModel(specificField: 'value'),
)
```

---

## TASK 6: header_roundtrip_allof_primitives_test.dart

**File**: `header_roundtrip_allof_primitives_test.dart`
**Endpoint**: `testHeaderRoundtripAllOfPrimitives`
**API Method**: `api.testHeaderRoundtripAllOfPrimitives(mergedObject: ...)`
**Response Type**: `HeadersRoundtripAllofPrimitivesGet200Response`
**Header Name**: `X-Merged-Object`
**Response Property**: `xMergedObject`

**Schema** (`AllOfPrimitive`):
```yaml
allOf:
  - type: object
    properties:
      id: string
  - type: object
    properties:
      count: integer
```

**Test Cases**:
1. Both fields set roundtrip - encoded as `id,abc,count,42`
2. Only id set
3. Only count set
4. Both null/missing
5. `null` parameter

**NOTE**: Look at generated code to determine exact constructor. Likely `AllOfPrimitive(id: 'abc', count: 42)`.

---

## TASK 7: header_roundtrip_allof_enums_test.dart

**File**: `header_roundtrip_allof_enums_test.dart`
**Endpoint**: `testHeaderRoundtripAllOfEnums`
**API Method**: `api.testHeaderRoundtripAllOfEnums(enumComposite: ...)`
**Response Type**: `HeadersRoundtripAllofEnumsGet200Response`
**Header Name**: `X-Enum-Composite`
**Response Property**: `xEnumComposite`

**Schema** (`AllOfEnum`):
```yaml
allOf:
  - type: object
    properties:
      status: $ref StatusEnum
  - type: object
    properties:
      priority: $ref PriorityEnum
```

**Test Cases**:
1. Both enums set roundtrip
2. Only status set
3. Only priority set
4. Both null
5. `null` parameter

---

## TASK 8: header_roundtrip_allof_lists_test.dart

**File**: `header_roundtrip_allof_lists_test.dart`
**Endpoint**: `testHeaderRoundtripAllOfLists`
**API Method**: `api.testHeaderRoundtripAllOfLists(listComposite: ...)`
**Response Type**: `HeadersRoundtripAllofListsGet200Response`
**Header Name**: `X-List-Composite`
**Response Property**: `xListComposite`

**Schema** (`AllOfWithSimpleList`):
```yaml
allOf:
  - type: object
    properties:
      tags: array of string
  - type: object
    properties:
      ids: array of integer
```

**Test Cases**:
1. Both arrays set roundtrip
2. Only tags set
3. Only ids set
4. Empty arrays
5. `null` parameter

---

## TASK 9: header_roundtrip_nested_oneof_in_allof_test.dart

**File**: `header_roundtrip_nested_oneof_in_allof_test.dart`
**Endpoint**: `testHeaderRoundtripNestedOneOfInAllOf`
**API Method**: `api.testHeaderRoundtripNestedOneOfInAllOf(nestedValue: ...)`
**Response Type**: `HeadersRoundtripNestedOneofInAllofGet200Response`
**Header Name**: `X-Nested-Value`
**Response Property**: `xNestedValue`

**Schema** (`NestedOneOfInAllOf`):
```yaml
allOf:
  - $ref: '#/components/schemas/OneOfPrimitive'  # oneOf: string | integer
  - type: object
    properties:
      metadata: string
```

**Test Cases**:
1. String variant with metadata roundtrip
2. Integer variant with metadata roundtrip
3. Without metadata (null)
4. `null` parameter

**NOTE**: This is a complex nested type. Check generated code for exact constructor pattern.

---

## TASK 10: header_roundtrip_nested_allof_in_oneof_test.dart

**File**: `header_roundtrip_nested_allof_in_oneof_test.dart`
**Endpoint**: `testHeaderRoundtripNestedAllOfInOneOf`
**API Method**: `api.testHeaderRoundtripNestedAllOfInOneOf(nestedValue: ...)`
**Response Type**: `HeadersRoundtripNestedAllofInOneofGet200Response`
**Header Name**: `X-Nested-Value`
**Response Property**: `xNestedValue`

**Schema** (`NestedAllOfInOneOf`):
```yaml
oneOf:
  - $ref: '#/components/schemas/AllOfComplex'  # allOf: Class1 + Class2
  - type: string
```

**Test Cases**:
1. AllOfComplex variant (Class1 + Class2 merged) roundtrip
2. String variant roundtrip
3. `null` parameter

---

## TASK 11: header_roundtrip_nested_anyof_in_oneof_test.dart

**File**: `header_roundtrip_nested_anyof_in_oneof_test.dart`
**Endpoint**: `testHeaderRoundtripNestedAnyOfInOneOf`
**API Method**: `api.testHeaderRoundtripNestedAnyOfInOneOf(nestedValue: ...)`
**Response Type**: `HeadersRoundtripNestedAnyofInOneofGet200Response`
**Header Name**: `X-Nested-Value`
**Response Property**: `xNestedValue`

**Schema** (`NestedAnyOfInOneOf`):
```yaml
oneOf:
  - $ref: '#/components/schemas/AnyOfMixed'  # anyOf: integer | Class2 | PriorityEnum
  - type: boolean
```

**Test Cases**:
1. AnyOfMixed with integer variant
2. AnyOfMixed with Class2 variant
3. AnyOfMixed with PriorityEnum variant
4. Boolean true variant
5. Boolean false variant
6. `null` parameter

---

## TASK 12: header_roundtrip_two_level_nesting_test.dart

**File**: `header_roundtrip_two_level_nesting_test.dart`
**Endpoint**: `testHeaderRoundtripTwoLevelNesting`
**API Method**: `api.testHeaderRoundtripTwoLevelNesting(twoLevelOneOf: ..., twoLevelAllOf: ...)`
**Response Type**: `HeadersRoundtripDeepTwoLevelGet200Response`
**Headers**: `X-Two-Level-OneOf`, `X-Two-Level-AllOf`
**Response Properties**: `xTwoLevelOneOf`, `xTwoLevelAllOf`

**Schema** (`TwoLevelOneOf`):
```yaml
oneOf:
  - oneOf:
      - type: string
      - type: integer
  - type: boolean
```

**Schema** (`TwoLevelAllOf`):
```yaml
allOf:
  - allOf:
      - type: object { id: string }
      - type: object { name: string }
  - type: object { active: boolean }
```

**Test Cases**:
1. TwoLevelOneOf: inner string variant
2. TwoLevelOneOf: inner integer variant
3. TwoLevelOneOf: outer boolean variant
4. TwoLevelAllOf: all fields set
5. TwoLevelAllOf: partial fields
6. Both headers together
7. `null` parameters

---

## TASK 13: header_roundtrip_three_level_nesting_test.dart

**File**: `header_roundtrip_three_level_nesting_test.dart`
**Endpoint**: `testHeaderRoundtripThreeLevelNesting`
**API Method**: `api.testHeaderRoundtripThreeLevelNesting(threeLevelOneOf: ..., threeLevelMixed: ...)`
**Response Type**: `HeadersRoundtripDeepThreeLevelGet200Response`
**Headers**: `X-Three-Level-OneOf`, `X-Three-Level-Mixed`
**Response Properties**: `xThreeLevelOneOf`, `xThreeLevelMixed`

**Schema** (`ThreeLevelOneOf`):
```yaml
oneOf:
  - oneOf:
      - oneOf:
          - type: string
          - type: integer
      - type: boolean
  - type: number
```

**Schema** (`ThreeLevelMixedOneOfAllOfAnyOf`):
```yaml
oneOf:
  - allOf:
      - anyOf:
          - type: string
          - type: integer
      - type: object { flag: boolean }
  - $ref: Class1
```

**Test Cases**:
1. ThreeLevelOneOf: deepest string
2. ThreeLevelOneOf: deepest integer
3. ThreeLevelOneOf: middle boolean
4. ThreeLevelOneOf: outer number
5. ThreeLevelMixed: allOf+anyOf variant with string
6. ThreeLevelMixed: allOf+anyOf variant with integer
7. ThreeLevelMixed: Class1 variant
8. `null` parameters

---

## TASK 14: header_roundtrip_dynamic_composite_test.dart

**File**: `header_roundtrip_dynamic_composite_test.dart`
**Endpoint**: `testHeaderRoundtripDynamicComposite`
**API Method**: `api.testHeaderRoundtripDynamicComposite(dynamicValue: ...)`
**Response Type**: `HeadersRoundtripComplexDynamicCompositeGet200Response`
**Header Name**: `X-Dynamic-Value`
**Response Property**: `xDynamicValue`

**Schema** (`DynamicCompositeValue`):
```yaml
anyOf:
  - $ref: '#/components/schemas/EntityType'       # oneOf with discriminator
  - $ref: '#/components/schemas/FlexibleValue'    # anyOf: string|int|bool|SimpleObject
  - $ref: '#/components/schemas/CompositeEntity'  # allOf composition
```

**Test Cases**:
1. EntityType: PersonEntity variant
2. EntityType: CompanyEntity variant
3. EntityType: SystemEntity variant (expect encoding error - nested object)
4. FlexibleValue: string variant
5. FlexibleValue: integer variant
6. FlexibleValue: boolean variant
7. FlexibleValue: SimpleObject variant
8. CompositeEntity variant
9. `null` parameter

---

## TASK 15: header_roundtrip_multi_level_test.dart

**File**: `header_roundtrip_multi_level_test.dart`
**Endpoint**: `testHeaderRoundtripMultiLevel`
**API Method**: `api.testHeaderRoundtripMultiLevel(multiLevel: ...)`
**Response Type**: `HeadersRoundtripComplexMultiLevelGet200Response`
**Header Name**: `X-Multi-Level`
**Response Property**: `xMultiLevel`

**Schema** (`MultiLevelNesting`):
```yaml
allOf:
  - type: object
    properties:
      level1:
        oneOf:
          - type: string
          - anyOf:
              - $ref: Class1
              - $ref: Class2
  - type: object
    properties:
      level2: integer
```

**Test Cases**:
1. level1 as string, level2 set
2. level1 as Class1 (via anyOf), level2 set
3. level1 as Class2 (via anyOf), level2 set
4. Only level1 set
5. Only level2 set
6. `null` parameter

---

## TASK 16: header_roundtrip_lists_with_compositions_test.dart

**File**: `header_roundtrip_lists_with_compositions_test.dart`
**Endpoint**: `testHeaderRoundtripListsWithCompositions`
**API Method**: `api.testHeaderRoundtripListsWithCompositions(objectList: ..., anyOfList: ...)`
**Response Type**: `HeadersRoundtripListsWithCompositionsGet200Response`
**Headers**: `X-Object-List`, `X-AnyOf-List`
**Response Properties**: `xObjectList`, `xAnyOfList`

**Schema** (`ObjectList`):
```yaml
type: array
items:
  $ref: '#/components/schemas/SimpleObject'
```

**Schema** (`AnyOfWithComplexList`):
```yaml
anyOf:
  - type: array
    items: $ref Class1
  - type: array
    items: $ref Class2
  - type: string
```

**Test Cases**:
1. ObjectList: single SimpleObject
2. ObjectList: multiple SimpleObjects
3. ObjectList: empty array (may fail encoding)
4. AnyOfList: Class1 array variant
5. AnyOfList: Class2 array variant
6. AnyOfList: string variant
7. Both headers together
8. `null` parameters

---

## TASK 17: header_roundtrip_aliases_test.dart

**File**: `header_roundtrip_aliases_test.dart`
**Endpoint**: `testHeaderRoundtripAliases`
**API Method**: `api.testHeaderRoundtripAliases(userId: ..., userName: ..., timestamp: ...)`
**Response Type**: `HeadersRoundtripAliasesGet200Response`
**Headers**: `X-User-Id`, `X-User-Name`, `X-Timestamp`
**Response Properties**: `xUserId`, `xUserName`, `xTimestamp`

**Schema**:
- `UserId`: alias for `integer`
- `UserName`: alias for `string`
- `Timestamp`: alias for `string` with `format: date-time`

**Test Cases**:
1. All three aliases set
2. Only userId
3. Only userName
4. Only timestamp
5. Verify datetime format encoding
6. `null` parameters

---

## EXECUTION INSTRUCTIONS

For each task:

1. **Create the test file** at the specified path
2. **Use the template** from the CONTEXT section
3. **Import** `big_decimal` only if needed (for decimal types)
4. **Check generated code** in `simple_encoding_api` package for exact class names and constructors
5. **Run the test** to verify it compiles and passes:
   ```bash
   cd /Users/tobi/Code/tonik/integration_test/simple_encoding/simple_encoding_test
   dart test test/<filename>_test.dart
   ```
6. **Document any encoding limitations** discovered (e.g., nested objects fail in simple encoding)

### Priority Order
Execute tasks in order (1-17). Earlier tasks test simpler schemas that later tasks build upon.

### Common Gotchas
- AnyOf types use named constructor parameters: `AnyOf(string: ...)` not `AnyOfString(...)`
- OneOf types use wrapper classes: `OneOfComplexClass1(Class1(...))` 
- AllOf types may merge properties or use composition classes
- Empty strings fail encoding with `EmptyValueException`
- Nested objects (like SystemEntity.config) fail simple encoding with `EncodingException`
- Integer values sent as headers may decode as strings due to type ambiguity

### Verification Checklist for Each Test
- [ ] Test compiles without errors
- [ ] Test passes when run
- [ ] Request header encoding is verified
- [ ] Response header decoding is verified
- [ ] Null/missing value handling is tested
- [ ] Edge cases (empty strings, special characters) are covered
