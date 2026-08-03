import 'package:code_builder/code_builder.dart';

/// Private request types needed for exact multipart wire serialization.
List<Spec> buildHttpMultipartSupport({
  required bool includesPartHeaders,
  required bool includesPlainFields,
}) => [
  if (includesPartHeaders || includesPlainFields)
    _multipartFileClass(
      includesPartHeaders: includesPartHeaders,
      includesPlainFields: includesPlainFields,
    ),
  _multipartRequestClass(
    includesPartHeaders: includesPartHeaders,
    includesPlainFields: includesPlainFields,
  ),
];

Class _multipartFileClass({
  required bool includesPartHeaders,
  required bool includesPlainFields,
}) => Class(
  (builder) => builder
    ..name = '_TonikMultipartFile'
    ..extend = refer('MultipartFile', 'package:http/http.dart')
    ..fields.addAll([
      if (includesPartHeaders)
        Field(
          (field) => field
            ..name = 'partHeaders'
            ..modifier = FieldModifier.final$
            ..type = TypeReference(
              (type) => type
                ..symbol = 'Map'
                ..url = 'dart:core'
                ..types.addAll([
                  refer('String', 'dart:core'),
                  refer('String', 'dart:core'),
                ]),
            ),
        ),
      if (includesPlainFields)
        Field(
          (field) => field
            ..name = 'isPlainField'
            ..modifier = FieldModifier.final$
            ..type = refer('bool', 'dart:core'),
        ),
    ])
    ..constructors.add(
      Constructor(
        (constructor) => constructor
          ..name = 'fromBytes'
          ..requiredParameters.addAll([
            Parameter(
              (parameter) => parameter
                ..name = 'field'
                ..type = refer('String', 'dart:core'),
            ),
            Parameter(
              (parameter) => parameter
                ..name = 'bytes'
                ..type = TypeReference(
                  (type) => type
                    ..symbol = 'List'
                    ..url = 'dart:core'
                    ..types.add(refer('int', 'dart:core')),
                ),
            ),
          ])
          ..optionalParameters.addAll([
            Parameter(
              (parameter) => parameter
                ..name = 'filename'
                ..named = true
                ..type = TypeReference(
                  (type) => type
                    ..symbol = 'String'
                    ..url = 'dart:core'
                    ..isNullable = true,
                ),
            ),
            Parameter(
              (parameter) => parameter
                ..name = 'contentType'
                ..named = true
                ..type = TypeReference(
                  (type) => type
                    ..symbol = 'MediaType'
                    ..url = 'package:http/http.dart'
                    ..isNullable = true,
                ),
            ),
            if (includesPartHeaders)
              Parameter(
                (parameter) => parameter
                  ..name = 'partHeaders'
                  ..named = true
                  ..toThis = true
                  ..defaultTo = const Code('const {}'),
              ),
            if (includesPlainFields)
              Parameter(
                (parameter) => parameter
                  ..name = 'isPlainField'
                  ..named = true
                  ..toThis = true
                  ..defaultTo = const Code('false'),
              ),
          ])
          ..initializers.add(
            Block.of([
              const Code('super(field, '),
              refer(
                'ByteStream',
                'package:http/http.dart',
              ).property('fromBytes').call([refer('bytes')]).code,
              const Code(
                ', bytes.length, filename: filename, '
                'contentType: contentType)',
              ),
            ]),
          ),
      ),
    ),
);

Class _multipartRequestClass({
  required bool includesPartHeaders,
  required bool includesPlainFields,
}) => Class(
  (builder) => builder
    ..name = '_TonikMultipartRequest'
    ..extend = refer('MultipartRequest', 'package:http/http.dart')
    ..mixins.add(refer('Abortable', 'package:http/http.dart'))
    ..fields.addAll([
      Field(
        (field) => field
          ..name = 'abortTrigger'
          ..annotations.add(refer('override', 'dart:core'))
          ..modifier = FieldModifier.final$
          ..type = TypeReference(
            (type) => type
              ..symbol = 'Future'
              ..url = 'dart:async'
              ..types.add(refer('void'))
              ..isNullable = true,
          ),
      ),
      Field(
        (field) => field
          ..name = '_boundary'
          ..modifier = FieldModifier.final$
          ..type = refer('String', 'dart:core')
          ..assignment = Block.of([
            const Code(r"'tonik-${"),
            refer(
              'DateTime',
              'dart:core',
            ).property('now').call([]).property('microsecondsSinceEpoch').code,
            const Code("}'"),
          ]),
      ),
    ])
    ..constructors.add(
      Constructor(
        (constructor) => constructor
          ..requiredParameters.addAll([
            Parameter(
              (parameter) => parameter
                ..name = 'method'
                ..toSuper = true,
            ),
            Parameter(
              (parameter) => parameter
                ..name = 'url'
                ..toSuper = true,
            ),
          ])
          ..optionalParameters.add(
            Parameter(
              (parameter) => parameter
                ..name = 'abortTrigger'
                ..named = true
                ..toThis = true,
            ),
          ),
      ),
    )
    ..methods.addAll([
      Method(
        (method) => method
          ..name = 'contentLength'
          ..annotations.add(refer('override', 'dart:core'))
          ..type = MethodType.getter
          ..returns = refer('int', 'dart:core')
          ..body = Block.of([
            const Code('var length = 0;'),
            const Code('for (final file in files) {'),
            const Code('  length += '),
            refer('utf8', 'dart:convert')
                .property('encode')
                .call([const CodeExpression(Code(r"'--$_boundary\r\n'"))])
                .property('length')
                .code,
            const Code(' + '),
            refer('utf8', 'dart:convert')
                .property('encode')
                .call([
                  refer('_headerForFile').call([refer('file')]),
                ])
                .property('length')
                .code,
            const Code(' + file.length + 2;'),
            const Code('}'),
            const Code('return length + '),
            refer('utf8', 'dart:convert')
                .property('encode')
                .call([
                  const CodeExpression(Code(r"'--$_boundary--\r\n'")),
                ])
                .property('length')
                .code,
            const Code(';'),
          ]),
      ),
      Method(
        (method) => method
          ..name = 'contentLength'
          ..annotations.add(refer('override', 'dart:core'))
          ..type = MethodType.setter
          ..requiredParameters.add(
            Parameter(
              (parameter) => parameter
                ..name = 'value'
                ..type = TypeReference(
                  (type) => type
                    ..symbol = 'int'
                    ..url = 'dart:core'
                    ..isNullable = true,
                ),
            ),
          )
          ..body = refer('UnsupportedError', 'dart:core')
              .newInstance([
                literalString(
                  'Cannot set the contentLength property of multipart '
                  'requests.',
                ),
              ])
              .thrown
              .statement,
      ),
      Method(
        (method) => method
          ..name = 'finalize'
          ..annotations.add(refer('override', 'dart:core'))
          ..returns = refer('ByteStream', 'package:http/http.dart')
          ..body = Block.of([
            const Code('super.finalize();'),
            const Code(
              "headers['content-type'] = "
              r"'multipart/form-data; boundary=$_boundary';",
            ),
            refer(
              'ByteStream',
              'package:http/http.dart',
            ).newInstance([refer('_finalize').call([])]).returned.statement,
          ]),
      ),
      Method(
        (method) => method
          ..name = '_finalize'
          ..modifier = MethodModifier.asyncStar
          ..returns = TypeReference(
            (type) => type
              ..symbol = 'Stream'
              ..url = 'dart:async'
              ..types.add(
                TypeReference(
                  (type) => type
                    ..symbol = 'List'
                    ..url = 'dart:core'
                    ..types.add(refer('int', 'dart:core')),
                ),
              ),
          )
          ..body = Block.of([
            declareFinal('separator')
                .assign(
                  refer('utf8', 'dart:convert').property('encode').call([
                    const CodeExpression(Code(r"'--$_boundary\r\n'")),
                  ]),
                )
                .statement,
            declareFinal('close')
                .assign(
                  refer('utf8', 'dart:convert').property('encode').call([
                    const CodeExpression(Code(r"'--$_boundary--\r\n'")),
                  ]),
                )
                .statement,
            const Code('for (final file in files) {'),
            const Code('  yield separator;'),
            const Code('  yield '),
            refer('utf8', 'dart:convert').property('encode').call([
              refer('_headerForFile').call([refer('file')]),
            ]).code,
            const Code(';'),
            const Code('  yield* file.finalize();'),
            const Code('  yield const [13, 10];'),
            const Code('}'),
            const Code('yield close;'),
          ]),
      ),
      Method(
        (method) => method
          ..name = '_headerForFile'
          ..returns = refer('String', 'dart:core')
          ..requiredParameters.add(
            Parameter(
              (parameter) => parameter
                ..name = 'file'
                ..type = refer('MultipartFile', 'package:http/http.dart'),
            ),
          )
          ..body = switch ((includesPartHeaders, includesPlainFields)) {
            (true, true) => const Code(r'''
final partHeaders = file is _TonikMultipartFile
    ? file.partHeaders
    : const {};
final isPlainField = file is _TonikMultipartFile && file.isPlainField;
final filename = file.filename == null
    ? ''
    : '; filename="${_browserEncode(file.filename!)}"';
return [
  if (!isPlainField) 'content-type: ${file.contentType}',
  'content-disposition: form-data; '
      'name="${_browserEncode(file.field)}"$filename',
  ...partHeaders.entries.map((entry) => '${entry.key}: ${entry.value}'),
  '',
  '',
].join('\r\n');
'''),
            (true, false) => const Code(r'''
final partHeaders = file is _TonikMultipartFile
    ? file.partHeaders
    : const {};
final filename = file.filename == null
    ? ''
    : '; filename="${_browserEncode(file.filename!)}"';
return [
  'content-type: ${file.contentType}',
  'content-disposition: form-data; '
      'name="${_browserEncode(file.field)}"$filename',
  ...partHeaders.entries.map((entry) => '${entry.key}: ${entry.value}'),
  '',
  '',
].join('\r\n');
'''),
            (false, true) => const Code(r'''
final isPlainField = file is _TonikMultipartFile && file.isPlainField;
final filename = file.filename == null
    ? ''
    : '; filename="${_browserEncode(file.filename!)}"';
return [
  if (!isPlainField) 'content-type: ${file.contentType}',
  'content-disposition: form-data; '
      'name="${_browserEncode(file.field)}"$filename',
  '',
  '',
].join('\r\n');
'''),
            (false, false) => const Code(r'''
final filename = file.filename == null
    ? ''
    : '; filename="${_browserEncode(file.filename!)}"';
return [
  'content-type: ${file.contentType}',
  'content-disposition: form-data; '
      'name="${_browserEncode(file.field)}"$filename',
  '',
  '',
].join('\r\n');
'''),
          },
      ),
      Method(
        (method) => method
          ..name = '_browserEncode'
          ..returns = refer('String', 'dart:core')
          ..requiredParameters.add(
            Parameter(
              (parameter) => parameter
                ..name = 'value'
                ..type = refer('String', 'dart:core'),
            ),
          )
          ..lambda = true
          ..body = const Code(
            'value\n'
            r"    .replaceAll('\r\n', '%0D%0A')"
            '\n'
            r"    .replaceAll('\r', '%0D%0A')"
            '\n'
            r"    .replaceAll('\n', '%0D%0A')"
            '\n'
            '''    .replaceAll('"', '%22')''',
          ),
      ),
    ]),
);
