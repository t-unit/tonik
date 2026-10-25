# Multipart Form Data

Tonik supports `multipart/form-data` request bodies for file uploads and mixed-field forms. The request body schema must describe an object whose properties supply named multipart parts.

---

## Basic Usage

Define your request body with `multipart/form-data`:

```yaml
requestBody:
  content:
    multipart/form-data:
      schema:
        type: object
        required: [name, age]
        properties:
          name:
            type: string
          age:
            type: integer
```

Use the generated form class like any other model:

```dart
await api.postForm(body: Form(name: 'Jane', age: 30));
```

Primitive fields (`string`, `integer`, `number`, `boolean`), enums, `DateTime`, and nested objects all work as their generated Dart types. Optional fields (not in `required`) are omitted when `null`.

---

## Dynamic Part Names

Add `additionalProperties` to your `multipart/form-data` schema to accept fields
whose names are supplied at runtime:

```yaml
schema:
  type: object
  additionalProperties:
    type: string
```

Pass a map as `body`, using the field names as keys:

```dart
await api.postLabels(body: {'language': 'en', 'theme': 'dark'});
```

If the schema also declares named properties, use the generated model and put
dynamic fields in its `additionalProperties` argument:

```dart
await api.postForm(body: Form(
  name: 'Jane',
  age: 30,
  additionalProperties: {'department': 'engineering'},
));
```

---

## File Uploads

Use `type: string, format: binary` for file fields. Tonik generates a `TonikFile` property — use `TonikFileBytes` for in-memory data or `TonikFilePath` for a path on disk:

```yaml
properties:
  file:
    type: string
    format: binary
  description:
    type: string
```

```dart
// From bytes (e.g. from a file picker)
await api.postUpload(body: UploadForm(
  file: TonikFileBytes(bytes, fileName: 'photo.jpg'),
  description: 'Profile photo',
));

// From a path on disk (native platforms only)
await api.postUpload(body: UploadForm(
  file: TonikFilePath('/tmp/photo.jpg'),
  description: 'Profile photo',
));
```

The optional `fileName` parameter sets the part's filename. When omitted, the property name is used as a fallback.

> `TonikFilePath` is not supported on web — use `TonikFileBytes` there instead.

---

## Arrays

By default, each array element is sent as a separate part with the same field name:

```dart
await api.post(body: Form(tags: ['dart', 'flutter', 'openapi']));
// → three separate parts, all named "tags"
```

Arrays of binary files work the same way — each `TonikFile` becomes its own part.

Content-based encoding applies to each array item individually, including when
`encoding.{field}.contentType` is `application/json`. For example, an array of
`[1, 2]` produces two JSON parts with bodies `1` and `2`. String items in JSON
parts include quotes. Content-based arrays omit null items.

### Delimited Arrays

Outside OAS 3.0 documents, you can use explicit style fields in `encoding` to
send an array as a single delimited value. OAS 3.1 and 3.2 use the same rules:

```yaml
encoding:
  tags:
    style: pipeDelimited
    explode: false
```

```dart
await api.post(body: Form(tags: ['dart', 'flutter']));
// → one part: tags=dart|flutter
```

Supported styles: `form` (comma-separated), `spaceDelimited`, `pipeDelimited`.

An explicit `style`, `explode`, or `allowReserved` selects style-based encoding
and overrides `contentType`. An explicit `false` also selects style-based
encoding; an empty encoding object uses content-based encoding. If `style` is
omitted in style mode, it defaults to `form`. The default `explode` is `true`
for `form` and `false` for the other styles.

Style-based multipart names and values are sent literally, without URI
percent-encoding. Spaces, reserved characters, and existing percent sequences
are preserved. The `allowReserved` value has no effect on multipart escaping.
A content-based part with `contentType: application/x-www-form-urlencoded`
uses that media type's escaping rules.

> In OAS 3.0 documents, `style`, `explode`, and `allowReserved` in multipart
> encoding objects are ignored. Arrays use content-based encoding with separate
> parts for their items.

---

## Per-Part Headers

Headers defined in `encoding.{field}.headers` become extra parameters on the generated method:

```yaml
encoding:
  file:
    headers:
      X-File-Hash:
        schema: { type: string }
        required: true
      X-File-Tag:
        schema: { type: string }
```

```dart
await api.postUpload(
  body: form,
  fileFileHash: 'sha256:abc123',   // required
  fileFileTag: 'v2',               // optional, nullable
);
```

Parameter names follow the pattern `{fieldName}{HeaderName}` in camelCase.

---

## Custom Content Types

Map any content type to multipart in [configuration](configuration.md#content-type-mapping):

```yaml
# tonik.yaml
contentTypes:
  application/vnd.my-form: multipart
```

---

## Limitations

| | |
|---|---|
| Multipart responses | Not supported |
| Arrays of arrays | Not supported |
| Untyped dynamic map values | Not supported |
| Recursive dynamic collection values | Not supported |
| Dynamic sources inside `allOf` | Not supported |
| Unmatched or non-writable encoding keys | Encoding error |
| `deepObject` style on arrays | Not supported |
| `style` / `explode` / `allowReserved` in OAS 3.0 | Ignored — arrays use content-based encoding with separate parts |
