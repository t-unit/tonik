## 0.0.8

 - **REFACTOR**: use simple encoding extension for request headers.
 - **REFACTOR**: remove usage of simple encoder for path parameters.
 - **FIX**: add missing simple properteis for one of classes.
 - **FIX**: path parameter encoding when only separated by a slash.
 - **FIX**: improved property json handling for one of models.
 - **FEAT**: toSimple for any of classes.
 - **FEAT**: simple properties for any of models.
 - **FEAT**: generate any of models.
 - **FEAT**: oneOf fromSimple / toSimple.
 - **FEAT**: to simple for classes.
 - **FEAT**: toSimple for enums.
 - **FEAT**: improved simple en- and decoding for all of models.
 - **FEAT**: fromSimple, toSimple for all of.
 - **FEAT**: property normailization for all of models.
 - **FEAT**: Uri property encoding and decoding.
 - **FEAT**: time zone aware encoding of date time objects.
 - **FEAT**: drop api prefix from generated server class.

## 0.0.6

 - **FIX**: proper handle dates.
 - **FIX**: priority for exlict defined names of schemas.
 - **FIX**: prio for explicitly defined names.
 - **FIX**: proper hash code for classes with >20 properties.

## 0.0.5

## 0.0.4

 - **FEAT**: generate all of classes.

## 0.0.3

 - **FIX**: honor paths in base urls.
 - **FIX**: improved handling for multi-line document descriptions.

## 0.0.2

 - **REFACTOR**: reorg folders.
 - **REFACTOR**: cleanup.
 - **REFACTOR**: cleanup code duplication.
 - **REFACTOR**: throw JsonDecodingException instead of ArgumentError.
 - **REFACTOR**: don’t create empty query params method.
 - **REFACTOR**: split tests, reduce code duplicaiton.
 - **REFACTOR**: extract hash code method generation.
 - **REFACTOR**: extract common equal method generation.
 - **FIX**: broken test assumption.
 - **FIX**: correct class names for multi content types response parsing.
 - **FIX**: handling of aliases in response parsing.
 - **FIX**: gneric type of response added.
 - **FIX**: proper handling in fromJson for nullable or non-required fields.
 - **FIX**: allow properties with names conflicting dart class methods.
 - **FIX**: options don’t need body if there is only a single body.
 - **FIX**: pass body to options method.
 - **FIX**: catch any thrown objects.
 - **FIX**: not-scoped typdef for alias request bodies.
 - **FIX**: broken test.
 - **FIX**: missing inline reponses.
 - **FIX**: reduce warnings in generated code.
 - **FEAT**: set accept headers.
 - **FEAT**: generate server class.
 - **FEAT**: fromSimple for classes.
 - **FEAT**: generate fromSimple factory for enums.
 - **FEAT**: improve response wrapper naming.
 - **FEAT**: equals and hash for response wrappers.
 - **FEAT**: doc strings for api clients.
 - **FEAT**: complex responses for response wrappers.
 - **FEAT**: response wrapper file writing.
 - **FEAT**: basic response wrapper generation.
 - **FEAT**: improved api client generation.
 - **FEAT**: handle classes with json or map properties names.
 - **FEAT**: provide request data.
 - **FEAT**: supply context when decoring headers.
 - **FEAT**: basic api client generation.
 - **FEAT**: improved name creation for multi-request bodies.
 - **FEAT**: content-type for requests.
 - **FEAT**: supply context when simple decoding models.
 - **FEAT**: add request body in core.
 - **FEAT**: body parameter for operations.
 - **FEAT**: allow context for decoding exceptions.
 - **FEAT**: do not generate dead code.
 - **FEAT**: improved response parsing.
 - **FEAT**: use server for api clients.
 - **FEAT**: sealed classes for multi-body responses.
 - **FEAT**: response parsing first part.
 - **FEAT**: add json decoding of more types to util.
 - **FEAT**: improved json decoding.
 - **FEAT**: improve verbosity for naming.
 - **FEAT**: response parsing in call method.
 - **FEAT**: response generator for single body responses.
 - **FEAT**: improved response name genreation.
 - **FEAT**: allow multiple bodies in responses.
 - **FEAT**: generate request body sealed classes.
 - **FEAT**: equals and hash code for one of classes.
 - **FEAT**: proper return types for call method of operations.
 - **FEAT**: improved request and response naming.
 - **FEAT**: support for response aliases.
 - **FEAT**: handle parameters for api clients.

## 0.0.1

- Initial version.
