## 0.9.0

> Note: This release has breaking changes.

 - **REFACTOR**: clarify empty-value divergence and drop dead parameter.
 - **REFACTOR**: harden form ParameterEntry encoding after review.
 - **REFACTOR**: give literal its own branch in the string-list encoder.
 - **FIX**: accept integer-valued JSON numbers in double and int lists.
 - **FIX**: omit empty array query parameters instead of throwing.
 - **FIX**: expand empty-string matrix params as name without value.
 - **FIX**: serialize empty-string primitive query params instead of throwing.
 - **FIX**: thread useQueryComponent through composite list form arms.
 - **FIX**: accept RFC 3339 lowercase 't' date-time separator.
 - **FIX**: accept whole-number double JSON values for integer fields.
 - **FIX**: encode empty form object property values.
 - **FIX**: omit empty arrays from form bodies.
 - **FIX**: preserve nullability of array items so null elements decode.
 - **FIX**: base64-encode byte parameters before percent-encoding.
 - **FIX**: omit empty list value for any-typed form query parameters.
 - **FIX**: mirror the object path for per-property form-body names, lists, and maps.
 - **FIX**: throw InvalidFormatException on offset-path parse errors and report original input.
 - **FIX**: keep binary delimited encoders non-throwing on empty decoded value and clarify docs.
 - **FEAT**: extend literal destination argument to collection encoders.
 - **FEAT**: add literal destination argument to scalar encoders.
 - **FEAT**: add reserved-preserving encoder and allowReserved flag to scalar encoders.
 - **FEAT**: add tagged-map simple/label/matrix/deepObject encoders.
 - **FEAT**: thread allowReserved through List and Map form encoders.
 - **FEAT**: thread allowReserved through delimited, deepObject and AnyModel value encoders.
 - **FEAT**: honor allowReserved for urlencoded form request-body properties.
 - **FEAT**: encode form-style parameters as ParameterEntry lists.
 - **FEAT**: add PropertyValue tagged type and form encoder.
 - **DOCS**: honor allowReserved for form-body array properties in docs and tests.
 - **DOCS**: scope the style-encoder parity note to the string styles.
 - **DOCS**: trim style-encoder comments to terse WHY.
 - **DOCS**: correct literal override doc on numeric scalar encoders.
 - **DOCS**: trim verbose comments to non-obvious WHY only.
 - **DOCS**: tighten header-literal comments to terse why-not-what.
 - **DOCS**: trim encodeAnyToFormEntries comment to accurate rationale.
 - **BREAKING** **FIX**: emit additionalProperties and honor allOf allowReserved in urlencoded form bodies.
 - **BREAKING** **FIX**: percent-encode object property keys in form explode:false encoding.
 - **BREAKING** **FIX**: explode form-urlencoded body array properties by default.
 - **BREAKING** **FIX**: stop percent-decoding simple response header values.
 - **BREAKING** **FEAT**: serialize composite request headers literally.
 - **BREAKING** **FEAT**: honor allowReserved for object, enum and composition query parameters.

## 0.8.0

 - **FIX**(generate): refine media-type docs, dedupe warning, and tests.
 - **FIX**(generate): tolerate media-type parameters in response Content-Type matching.

## 0.7.1

 - **FIX**: AnyModel encoding in tonik_util runtime and three generator callsites.
 - **FEAT**: add MapModel and Base64Model parameter encoding support.

## 0.7.0

 - **FIX**: add useQueryComponent parameter to Date.toForm.
 - **FIX**: address correctness and safety issues from comprehensive audit.
 - **FIX**: resolve lint violations from previous bug fix commits.
 - **FIX**: narrow catch clause in Date.parse to FormatException and RangeError.
 - **FIX**: correct doc comment for decodeJsonNullableList.
 - **FIX**: wrap Uri.decodeComponent in try-catch in decodeSimpleString.
 - **FEAT**: add request cancellation support via CancelToken.
 - **FEAT**: support for addtional properties.

## 0.6.0

 - **FIX**: stable sort performance improvements.
 - **FIX**: better base64 data handleing.
 - **FEAT**: use async file loading in multipart requests.
 - **FEAT**: introduce TonikFile.
 - **FEAT**: basic form data handling.

## 0.5.0

 - **FEAT**: read and write only for oneOf.

## 0.4.1

## 0.4.0

 - **FIX**: handle boolean schemas in lists correclty.
 - **FEAT**: better support for boolean models.

## 0.3.0

 - **FIX**: remove lints as dependency.

## 0.2.1

## 0.2.0

> Note: This release has breaking changes.

 - **FEAT**: binary data type.
 - **FEAT**: binary and text bodies in responses.
 - **BREAKING** **FEAT**: require dart 3.10.0 or later.

## 0.1.0

 - **REFACTOR**: matrix parameter.
 - **FIX**: various fixes for path parameter encodign.
 - **FIX**: toLabel list encoding.
 - **FIX**: form encoding.
 - **FIX**: list handling for allOf toJson.
 - **FIX**: lists in parameters with double encoding.
 - **FIX**: matrix map encoding.
 - **FEAT**: improved deep object query parameter encoding.
 - **FEAT**: imporved matrix encoding for paths.
 - **FEAT**: toMatrix for anyOf.
 - **FEAT**: parameter properteis for oneOf.
 - **FEAT**: matrxi encoding extension.
 - **FEAT**: unified parameter encoding.
 - **FEAT**: anyOf and allOf toLabel.
 - **FEAT**: add toLabel for classes.

## 0.0.9

 - **FEAT**: form encoding and decoding support for classes and composition types.
 - **FIX**: double encoded values for simple and form encoding.

## 0.0.8

 - **REFACTOR**: use simple encoding extension for request headers.
 - **FIX**: improved url decoding.
 - **FIX**: improved property json handling for one of models.
 - **FEAT**: improved simple en- and decoding for all of models.
 - **FEAT**: parse time zones agnostic of locations.

## 0.0.7

 - **FEAT**: Uri property encoding and decoding.
 - **FEAT**: time zone aware date time parsing.
 - **FEAT**: time zone aware encoding of date time objects.

## 0.0.6

 - **FIX**: proper handle dates.

## 0.0.5

## 0.0.4

 - no changes

## 0.0.3

 - **FIX**: base url not set if there are no other options set.

## 0.0.2

 - **REFACTOR**: throw JsonDecodingException instead of ArgumentError.
 - **FIX**: handle url encoding for simple decoding.
 - **FIX**: catch any thrown objects.
 - **FEAT**: improved json decoding.
 - **FEAT**: add date class to util package.
 - **FEAT**: allow context for decoding exceptions.
 - **FEAT**: generate server class.
 - **FEAT**: add json decoding of more types to util.
 - **FEAT**: fromSimple for classes.
 - **FEAT**: generate fromSimple factory for enums.
 - **FEAT**: add simple and json decoder.

## 0.0.1

- Initial version.
