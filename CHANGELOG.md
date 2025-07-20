# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-07-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`tonik_util` - `v0.0.7`](#tonik_util---v007)

---

#### `tonik_util` - `v0.0.7`

 - **FEAT**: Uri property encoding and decoding.
 - **FEAT**: time zone aware date time parsing.
 - **FEAT**: time zone aware encoding of date time objects.


## 2025-06-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`tonik` - `v0.0.6`](#tonik---v006)
 - [`tonik_core` - `v0.0.6`](#tonik_core---v006)
 - [`tonik_generate` - `v0.0.6`](#tonik_generate---v006)
 - [`tonik_parse` - `v0.0.6`](#tonik_parse---v006)
 - [`tonik_util` - `v0.0.6`](#tonik_util---v006)

---

#### `tonik` - `v0.0.6`

#### `tonik_core` - `v0.0.6`

#### `tonik_generate` - `v0.0.6`

 - **FIX**: proper handle dates.
 - **FIX**: priority for exlict defined names of schemas.
 - **FIX**: prio for explicitly defined names.
 - **FIX**: proper hash code for classes with >20 properties.

#### `tonik_parse` - `v0.0.6`

#### `tonik_util` - `v0.0.6`

 - **FIX**: proper handle dates.


## 2025-06-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`tonik` - `v0.0.5`](#tonik---v005)
 - [`tonik_core` - `v0.0.5`](#tonik_core---v005)
 - [`tonik_generate` - `v0.0.5`](#tonik_generate---v005)
 - [`tonik_parse` - `v0.0.5`](#tonik_parse---v005)
 - [`tonik_util` - `v0.0.5`](#tonik_util---v005)

---

#### `tonik` - `v0.0.5`

#### `tonik_core` - `v0.0.5`

#### `tonik_generate` - `v0.0.5`

#### `tonik_parse` - `v0.0.5`

#### `tonik_util` - `v0.0.5`


## 2025-06-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`tonik` - `v0.0.4`](#tonik---v004)
 - [`tonik_core` - `v0.0.4`](#tonik_core---v004)
 - [`tonik_generate` - `v0.0.4`](#tonik_generate---v004)
 - [`tonik_parse` - `v0.0.4`](#tonik_parse---v004)
 - [`tonik_util` - `v0.0.4`](#tonik_util---v004)

---

#### `tonik` - `v0.0.4`

 - **FIX**: define executables for tonik.
 - **FEAT**: generate all of classes.
 - **FEAT**: improve output on invalid arguments.

#### `tonik_core` - `v0.0.4`

 - **FEAT**: generate all of classes.

#### `tonik_generate` - `v0.0.4`

 - **FEAT**: generate all of classes.

#### `tonik_parse` - `v0.0.4`

 - no changes

#### `tonik_util` - `v0.0.4`

 - no changes


## 2025-05-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`tonik_generate` - `v0.0.3`](#tonik_generate---v003)
 - [`tonik_util` - `v0.0.3`](#tonik_util---v003)
 - [`tonik` - `v0.0.3`](#tonik---v003)

---

#### `tonik_generate` - `v0.0.3`

 - **FIX**: honor paths in base urls.
 - **FIX**: improved handling for multi-line document descriptions.

#### `tonik_util` - `v0.0.3`

 - **FIX**: base url not set if there are no other options set.

#### `tonik` - `v0.0.3`


## 2025-05-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`tonik` - `v0.0.2`](#tonik---v002)
 - [`tonik_core` - `v0.0.2`](#tonik_core---v002)
 - [`tonik_generate` - `v0.0.2`](#tonik_generate---v002)
 - [`tonik_parse` - `v0.0.2`](#tonik_parse---v002)
 - [`tonik_util` - `v0.0.2`](#tonik_util---v002)

---

#### `tonik` - `v0.0.2`

 - **FEAT**: doc strings for api clients.
 - **FEAT**: response parsing first part.
 - **FEAT**: response generator for single body responses.
 - **FEAT**: improved request and response naming.
 - **FEAT**: parse request bodies.

#### `tonik_core` - `v0.0.2`

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

#### `tonik_generate` - `v0.0.2`

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

#### `tonik_parse` - `v0.0.2`

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

#### `tonik_util` - `v0.0.2`

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

