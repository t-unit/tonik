import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/transport/dio/dio_multipart_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/multipart_body_planner.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'dio parsed 3.1 form style keeps DateTime text despite JSON content type',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'required': ['value'],
                      'properties': {
                        'value': {'type': 'string', 'format': 'date-time'},
                      },
                    },
                    'encoding': {
                      'value': {
                        'style': 'form',
                        'contentType': 'application/json',
                      },
                    },
                  },
                },
              },
              'responses': {
                '204': {'description': 'Uploaded'},
              },
            },
          },
        },
      });
      final content =
          api.operations.single.requestBody!.resolvedContent.single
              as MultipartRequestContent;
      final model = content.model as ClassModel;
      expect(model.properties.single.model.resolved, isA<DateTimeModel>());
      expect(content.encoding['value']!.style, EncodingStyle.form);
      expect(content.encoding['value']!.contentType, ContentType.json);
      expect(content.encoding['value']!.rawContentType, 'application/json');
      final plan = const MultipartBodyPlanner(backend: TransportBackend.dio)
          .plan(
            content,
            bodyAccessor: 'body',
            isRequired: true,
          );
      final method = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of(buildMultipartBodyStatements(plan).statements),
      );
      final actual = method
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      const expected = r'''
Object? encode() {
  final _$formData = FormData();
  _$formData.files.add(MapEntry(r'value', MultipartFile.fromString(
    body.value.toTimeZonedIso8601String(), contentType: DioMediaType.parse(r'text/plain'),
  )));
  return _$formData;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      expect(
        collapseWhitespace(formatter.format(actual)),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );

  test(
    'dio parsed 3.1 form style keeps enum text despite JSON content type',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'required': ['value'],
                      'properties': {
                        'value': {
                          'type': 'string',
                          'enum': ['ready', 'done'],
                        },
                      },
                    },
                    'encoding': {
                      'value': {
                        'style': 'form',
                        'contentType': 'application/json',
                      },
                    },
                  },
                },
              },
              'responses': {
                '204': {'description': 'Uploaded'},
              },
            },
          },
        },
      });
      final content =
          api.operations.single.requestBody!.resolvedContent.single
              as MultipartRequestContent;
      final model = content.model as ClassModel;
      expect(model.properties.single.model.resolved, isA<EnumModel<String>>());
      expect(content.encoding['value']!.style, EncodingStyle.form);
      expect(content.encoding['value']!.contentType, ContentType.json);
      expect(content.encoding['value']!.rawContentType, 'application/json');
      final plan = const MultipartBodyPlanner(backend: TransportBackend.dio)
          .plan(
            content,
            bodyAccessor: 'body',
            isRequired: true,
          );
      final method = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of(buildMultipartBodyStatements(plan).statements),
      );
      final actual = method
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      const expected = r'''
Object? encode() {
  final _$formData = FormData();
  _$formData.files.add(MapEntry(r'value', MultipartFile.fromString(
    body.value.toJson(), contentType: DioMediaType.parse(r'text/plain'),
  )));
  return _$formData;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      expect(
        collapseWhitespace(formatter.format(actual)),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );

  test(
    'http parsed 3.1 form style keeps DateTime text despite JSON content type',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'required': ['value'],
                      'properties': {
                        'value': {'type': 'string', 'format': 'date-time'},
                      },
                    },
                    'encoding': {
                      'value': {
                        'style': 'form',
                        'contentType': 'application/json',
                      },
                    },
                  },
                },
              },
              'responses': {
                '204': {'description': 'Uploaded'},
              },
            },
          },
        },
      });
      final content =
          api.operations.single.requestBody!.resolvedContent.single
              as MultipartRequestContent;
      final model = content.model as ClassModel;
      expect(model.properties.single.model.resolved, isA<DateTimeModel>());
      expect(content.encoding['value']!.style, EncodingStyle.form);
      expect(content.encoding['value']!.contentType, ContentType.json);
      expect(content.encoding['value']!.rawContentType, 'application/json');
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            content,
            bodyAccessor: 'body',
            isRequired: true,
          );
      final method = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final actual = method
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'value', utf8.encode(body.value.toTimeZonedIso8601String()),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      expect(
        collapseWhitespace(formatter.format(actual)),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );

  test(
    'http parsed 3.1 form style keeps enum text despite JSON content type',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'required': ['value'],
                      'properties': {
                        'value': {
                          'type': 'string',
                          'enum': ['ready', 'done'],
                        },
                      },
                    },
                    'encoding': {
                      'value': {
                        'style': 'form',
                        'contentType': 'application/json',
                      },
                    },
                  },
                },
              },
              'responses': {
                '204': {'description': 'Uploaded'},
              },
            },
          },
        },
      });
      final content =
          api.operations.single.requestBody!.resolvedContent.single
              as MultipartRequestContent;
      final model = content.model as ClassModel;
      expect(model.properties.single.model.resolved, isA<EnumModel<String>>());
      expect(content.encoding['value']!.style, EncodingStyle.form);
      expect(content.encoding['value']!.contentType, ContentType.json);
      expect(content.encoding['value']!.rawContentType, 'application/json');
      final plan = const MultipartBodyPlanner(backend: TransportBackend.http)
          .plan(
            content,
            bodyAccessor: 'body',
            isRequired: true,
          );
      final method = Method(
        (b) => b
          ..name = 'encode'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of(buildHttpMultipartBodyStatements(plan)),
      );
      final actual = method
          .accept(DartEmitter(useNullSafetySyntax: true))
          .toString();
      const expected = r'''
Object? encode() {
  final _$multipartFiles = <MultipartFile>[];
  _$multipartFiles.add(MultipartFile.fromBytes(
    r'value', utf8.encode(body.value.toJson()),
    contentType: MediaType.parse(r'text/plain'),
  ));
  return _$multipartFiles;
}
''';
      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      expect(
        collapseWhitespace(formatter.format(actual)),
        collapseWhitespace(formatter.format(expected)),
      );
    },
  );

  test('dio parsed bare alias cycle remains unsupported as multipart root', () {
    expect(
      () {
        final api = Importer().import({
          'openapi': '3.0.3',
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': {
            '/upload': {
              'post': {
                'operationId': 'upload',
                'requestBody': {
                  'required': true,
                  'content': {
                    'multipart/form-data': {
                      'schema': {r'$ref': '#/components/schemas/AliasA'},
                    },
                  },
                },
                'responses': {
                  '204': {'description': 'Uploaded'},
                },
              },
            },
          },
          'components': {
            'schemas': {
              'AliasA': {r'$ref': '#/components/schemas/AliasB'},
              'AliasB': {r'$ref': '#/components/schemas/AliasA'},
            },
          },
        });
        final content =
            api.operations.single.requestBody!.resolvedContent.single
                as MultipartRequestContent;
        const MultipartBodyPlanner(backend: TransportBackend.dio).plan(
          content,
          bodyAccessor: 'body',
          isRequired: true,
        );
      },
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Unsupported multipart body model AnyModel at components/schemas; '
              'expected a class, alias, or allOf of classes.',
        ),
      ),
    );
  });

  test(
    'http parsed bare alias cycle remains unsupported as multipart root',
    () {
      expect(
        () {
          final api = Importer().import({
            'openapi': '3.0.3',
            'info': {'title': 'Test', 'version': '1.0.0'},
            'paths': {
              '/upload': {
                'post': {
                  'operationId': 'upload',
                  'requestBody': {
                    'required': true,
                    'content': {
                      'multipart/form-data': {
                        'schema': {r'$ref': '#/components/schemas/AliasA'},
                      },
                    },
                  },
                  'responses': {
                    '204': {'description': 'Uploaded'},
                  },
                },
              },
            },
            'components': {
              'schemas': {
                'AliasA': {r'$ref': '#/components/schemas/AliasB'},
                'AliasB': {r'$ref': '#/components/schemas/AliasA'},
              },
            },
          });
          final content =
              api.operations.single.requestBody!.resolvedContent.single
                  as MultipartRequestContent;
          const MultipartBodyPlanner(backend: TransportBackend.http).plan(
            content,
            bodyAccessor: 'body',
            isRequired: true,
          );
        },
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Unsupported multipart body model AnyModel at components/schemas; '
                'expected a class, alias, or allOf of classes.',
          ),
        ),
      );
    },
  );
}
