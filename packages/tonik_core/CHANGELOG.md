## 0.8.0

 - **REFACTOR**(generate): simplify workerCount semantics and tighten worker pool.
 - **REFACTOR**(tonik_core): hide effectiveDefault from the public barrel.
 - **REFACTOR**: make dropped-default warning location-neutral and report spec types.
 - **REFACTOR**: consolidate default-resolution across class properties and operation params.
 - **REFACTOR**: slim default carrier, surface expected type in warning.
 - **REFACTOR**: move effective-default resolution onto Property; share decoder-default helper.
 - **REFACTOR**(tonik_core): tighten AliasModel default contract.
 - **FIX**(tonik_core): resolve alias default lazily through the chain.
 - **FIX**: require all fields on core Example and detect cyclic example $refs.
 - **FEAT**(generate): parallelize model file generation across isolates.
 - **FEAT**: apply primitive defaults to operation parameters.
 - **FEAT**(tonik): carry OpenAPI `default` through parse + core.
 - **FEAT**: parse OpenAPI example/examples through to core models.
 - **DOCS**(generate): trim comments across worker pool changes.
 - **DOCS**: trim noise dartdoc from default carriers.

## 0.7.1

 - Bump "tonik_core" to `0.7.1`.

## 0.7.0

 - **REFACTOR**: add Model.resolved getter, remove alias-resolution duplication.
 - **FIX**: resolve lint violations from previous bug fix commits.
 - **FIX**: add equality and hashCode to Tag class.
 - **FIX**: include context field in hashCode for all Alias classes.
 - **FEAT**: optionally generate code with fast_immutable_collections.
 - **FEAT**: support for addtional properties.

## 0.6.0

 - **FIX**: shadowing of variables prevent proper names.
 - **FIX**: proper nested nullable handling for models.
 - **FIX**: improved stablesort for deeply nested models.
 - **FIX**: stable sort performance improvements.
 - **FIX**: handle cycles for stable model key generation.
 - **FIX**: better base64 data handleing.
 - **FEAT**: improved array support in multipart.
 - **FEAT**: better style handling for mutlipart.
 - **FEAT**: basic form data handling.

## 0.5.0

 - **FEAT**: handle schema level read and write only.
 - **FEAT**: improve read/write only handling.
 - **FEAT**: support read and write only properties.
 - **FEAT**: basic support for cookies.

## 0.4.1

 - **FEAT**: normaliz allOf with single model to aliases.
 - **FEAT**: better handle contentEncoding.

## 0.4.0

 - **FEAT**: server templating.
 - **FEAT**: ref sibling handling for 3.1.
 - **FEAT**: prase boolean schemas.
 - **FEAT**: support mutualTLS for 3.1.
 - **FEAT**: support description overrides for 3.1.
 - **FEAT**: additional metadata fields for 3.1.

## 0.3.0

 - **FEAT**: better support for nullable schemas.

## 0.2.1

## 0.2.0

> Note: This release has breaking changes.

 - **FEAT**: binary data type.
 - **FEAT**: binary and text bodies in responses.
 - **FEAT**: cli handling for config.
 - **FEAT**: fallback cases for enums.
 - **FEAT**: deprecation handling from config.
 - **FEAT**: apply filter from configuration.
 - **FEAT**: config and name overrides.
 - **BREAKING** **FEAT**: require dart 3.10.0 or later.

## 0.1.0

 - **FIX**: stabilize names by sorting models.
 - **FEAT**: parse deprecated fields for models.
 - **FEAT**: improved list handing for matrix encoding.

## 0.0.9

 - **FEAT**: security information parsing and documentation support.
 - **FEAT**: contact, license, terms and external docs support.

## 0.0.8

 - **FEAT**: improved simple en- and decoding for all of models.
 - **FEAT**: parse time zones agnostic of locations.
 - **FEAT**: Uri property encoding and decoding.

## 0.0.6

## 0.0.5

## 0.0.4

 - **FEAT**: generate all of classes.

## 0.0.2

 - **FEAT**: improved json decoding.
 - **FEAT**: basic api client generation.
 - **FEAT**: complex responses for response wrappers.
 - **FEAT**: resolved content and isRequired for request body.
 - **FEAT**: improved response name genreation.
 - **FEAT**: allow multiple bodies in responses.
 - **FEAT**: improved request and response naming.
 - **FEAT**: support for response aliases.
 - **FEAT**: parse request bodies.
 - **FEAT**: add request body in core.

## 0.0.1

- Initial version.
