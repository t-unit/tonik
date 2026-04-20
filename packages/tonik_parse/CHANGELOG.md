## 0.7.0

 - **REFACTOR**: add Model.resolved getter, remove alias-resolution duplication.
 - **FIX**: missing context for whitespace properties.
 - **FIX**: sanitize naming collisions for keywords, Object members, and body params.
 - **FIX**: register named ListModels early to prevent orphan duplicates.
 - **FIX**: allow lower and uppder case response code ragnes (5xx vs 5XX).
 - **FIX**: prevent placeholder shadowing and strengthen cycle tests.
 - **FIX**: resolve stack overflow on circular schema references.
 - **FIX**: clarify content-type config override test names.
 - **FIX**: address PR review feedback.
 - **FIX**: address correctness and safety issues from comprehensive audit.
 - **FIX**: warn when OAuth2 flow is missing required URL fields.
 - **FEAT**: support for addtional properties.

## 0.6.0

 - **FIX**: deduplicate AliasModel instances for bare $ref aliases in allOf.
 - **FIX**: stable sort performance improvements.
 - **FIX**: improved binary and array without items handling.
 - **FIX**: better base64 data handleing.
 - **FIX**: correclty handle any models in multipart.
 - **FIX**: improved content type checks for mulitpart.
 - **FIX**: handle byte formatted strings in multipart correclty.
 - **FIX**: warn for invalid types in multipart.
 - **FEAT**: improved array support in multipart.
 - **FEAT**: better style handling for mutlipart.
 - **FEAT**: basic form data handling.
 - **FEAT**: improved encoding parsing for mutlipart.

## 0.5.0

 - **FIX**: proper default vlaue for explode in cookies.
 - **FIX**: broken def handling for inline schemas.
 - **FEAT**: handle schema level read and write only.
 - **FEAT**: support read and write only properties.
 - **FEAT**: basic support for cookies.
 - **FEAT**: nested discriminator support (allOf).

## 0.4.1

 - **FEAT**: better handle contentEncoding.

## 0.4.0

 - **REFACTOR**: parse all fields for schema references.
 - **FIX**: inline models with ref siblings where not generated in all cases.
 - **FIX**: proper handling of lists with type arrays.
 - **FEAT**: server templating.
 - **FEAT**: improved encoding detection with OAS 3.1.
 - **FEAT**: support defs for OAS 3.1.
 - **FEAT**: ref sibling handling for 3.1.
 - **FEAT**: prase boolean schemas.
 - **FEAT**: support mutualTLS for 3.1.
 - **FEAT**: inform user about version of spec.
 - **FEAT**: support description overrides for 3.1.
 - **FEAT**: additional metadata fields for 3.1.
 - **FEAT**: support 3.1 feature of path items in components.

## 0.3.0

 - **FEAT**: better support for nullable schemas.

## 0.2.1

## 0.2.0

> Note: This release has breaking changes.

 - **FEAT**: binary data type.
 - **FEAT**: binary and text bodies in responses.
 - **FEAT**: various improvemts for configuration handling.
 - **FEAT**: custom content types via configuration.
 - **FEAT**: parse vendor extensions for names from openapi specs.
 - **FEAT**: config and name overrides.
 - **BREAKING** **FEAT**: require dart 3.10.0 or later.

## 0.1.0

 - **FIX**: proper default parsing for form encoded parameters.
 - **FIX**: form encoding.
 - **FEAT**: parse deprecated fields for models.

## 0.0.9

 - **FEAT**: improved name generation.
 - **FEAT**: security information parsing.

## 0.0.8

 - **FEAT**: Uri property encoding and decoding.
 - **FEAT**: time zone aware date time parsing.
 - **FEAT**: more verbose decimal parsing.

## 0.0.6

## 0.0.5

## 0.0.4

 - no changes

## 0.0.2

 - **FIX**: correct class names for multi content types response parsing.
 - **FIX**: avoid duplicated request bodies and responses.
 - **FIX**: extra alias request bodies.
 - **FIX**: inline request body missing in global definition.
 - **FIX**: import request bodies into core objects.
 - **FIX**: missing inline reponses.
 - **FEAT**: improved json decoding.
 - **FEAT**: improve context naming.
 - **FEAT**: allow multiple bodies in responses.
 - **FEAT**: support for response aliases.
 - **FEAT**: parse request bodies.
 - **FEAT**: add request body in core.

## 0.0.1

- Initial version.
