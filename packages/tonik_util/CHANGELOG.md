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
