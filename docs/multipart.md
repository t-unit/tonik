# Multipart Form Data

Tonik supports `multipart/form-data` request bodies for file uploads and mixed-field forms. The request body schema must be an object — each property maps to one part of the multipart request.

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

### Delimited Arrays (OAS 3.1)

In OAS 3.1 specs, you can use `encoding` to send an array as a single delimited value:

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

> In OAS 3.0, `style` and `explode` in `encoding` objects are ignored — arrays always use separate parts.

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
| `deepObject` style on arrays | Not supported |
| `style` / `explode` in OAS 3.0 | Ignored — arrays always use separate parts |
