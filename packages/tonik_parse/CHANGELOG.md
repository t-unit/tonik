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
