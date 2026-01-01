import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ClassGenerator', () {
    late ClassGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('generates class with correct name', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);
      expect(result.name, 'User');
    });

    test('generates class with immutable annotation', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);

      expect(result.annotations.length, 1);

      final annotation = result.annotations.first;
      expect(annotation.accept(emitter).toString(), 'immutable');
    });

    test('generates class implementing ParameterEncodable', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);

      expect(result.implements.length, 1);
      expect(
        result.implements.first.accept(emitter).toString(),
        'ParameterEncodable',
      );
    });

    group('doc comments', () {
      test('generates class with doc comment from description', () {
        final model = ClassModel(
          isDeprecated: false,
          description: 'A user in the system',
          name: 'User',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        expect(result.docs, ['/// A user in the system']);
      });

      test('generates class with multiline doc comment', () {
        final model = ClassModel(
          isDeprecated: false,
          description: 'A user in the system.\nContains user details.',
          name: 'User',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        expect(result.docs, [
          '/// A user in the system.',
          '/// Contains user details.',
        ]);
      });

      test('generates class without doc comment when description is null', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        expect(result.docs, isEmpty);
      });

      test('generates class without doc comment when description is empty', () {
        final model = ClassModel(
          isDeprecated: false,
          description: '',
          name: 'User',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        expect(result.docs, isEmpty);
      });

      test('generates field with doc comment from property description', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              description: 'The unique identifier',
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.docs, ['/// The unique identifier']);
      });

      test('generates field with multiline doc comment', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              description: 'The user status.\nCan be active or inactive.',
              name: 'status',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.docs, [
          '/// The user status.',
          '/// Can be active or inactive.',
        ]);
      });

      test('generates field without doc comment when description is null', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.docs, isEmpty);
      });

      test(
        'generates field with both doc comment and deprecated annotation',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: [
              Property(
                description: 'Use userId instead',
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: true,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);
          final field = result.fields.first;

          expect(field.docs, ['/// Use userId instead']);
          expect(field.annotations, hasLength(1));
        },
      );
    });

    test('generates currentEncodingShape getter for class with properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);
      final getter = result.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(getter.returns?.accept(emitter).toString(), 'EncodingShape');
      expect(getter.lambda, isTrue);
      expect(getter.body?.accept(emitter).toString(), 'EncodingShape.complex');
    });

    test('generates currentEncodingShape getter for empty class', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Empty',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);
      final getter = result.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(getter.returns?.accept(emitter).toString(), 'EncodingShape');
      expect(getter.lambda, isTrue);
      expect(getter.body?.accept(emitter).toString(), 'EncodingShape.complex');
    });

    test('generates currentEncodingShape getter for complex class', () {
      final nestedClass = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
      );

      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'address',
            model: nestedClass,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);
      final getter = result.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(getter.returns?.accept(emitter).toString(), 'EncodingShape');
      expect(getter.lambda, isTrue);
      expect(getter.body?.accept(emitter).toString(), 'EncodingShape.complex');
    });

    test('generates constructor with required and optional parameters', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);
      final constructor = result.constructors.first;

      expect(constructor.constant, isTrue);
      expect(constructor.optionalParameters, hasLength(2));

      final idParam = constructor.optionalParameters[0];
      expect(idParam.name, 'id');
      expect(idParam.named, isTrue);
      expect(idParam.required, isTrue);
      expect(idParam.toThis, isTrue);

      final nameParam = constructor.optionalParameters[1];
      expect(nameParam.name, 'name');
      expect(nameParam.named, isTrue);
      expect(nameParam.required, isFalse);
      expect(nameParam.toThis, isTrue);
    });

    test(
      'generates constructor with required fields before non-required fields',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'nickname',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'bio',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final constructor = result.constructors.first;

        // Get the required and optional parameters
        final requiredParams = constructor.optionalParameters
            .where((p) => p.required)
            .map((p) => p.name)
            .toList();
        final optionalParams = constructor.optionalParameters
            .where((p) => !p.required)
            .map((p) => p.name)
            .toList();

        // Verify all required parameters come before optional ones
        final allParams = constructor.optionalParameters
            .map((p) => p.name)
            .toList();
        final requiredIndices = requiredParams.map(allParams.indexOf);
        final optionalIndices = optionalParams.map(allParams.indexOf);

        // Check that every required parameter index is less
        // than every optional parameter index
        for (final reqIndex in requiredIndices) {
          for (final optIndex in optionalIndices) {
            expect(reqIndex < optIndex, isTrue);
          }
        }

        // Verify the exact order: required params should be id and name,
        // optional params should be nickname and bio
        expect(requiredParams, ['id', 'name']);
        expect(optionalParams, ['nickname', 'bio']);
      },
    );

    test('generates filename in snake_case', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'UserProfile',
        properties: const [],
        context: Context.initial(),
      );

      final result = generator.generate(model);
      expect(result.filename, 'user_profile.dart');
    });

    group('property generation', () {
      test('generates required non-nullable int property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'id');
        expect(field.type?.accept(emitter).toString(), 'int');
        expect(field.annotations, isEmpty);
      });

      test('generates optional nullable string property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'name');
        expect(field.type?.accept(emitter).toString(), 'String?');
        expect(field.annotations, isEmpty);
      });

      test('generates decimal property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'balance',
              model: DecimalModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'balance');
        expect(field.type?.accept(emitter).toString(), 'BigDecimal');
        expect(field.annotations, isEmpty);
      });

      test('generates list of strings property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'tags');
        expect(field.type?.accept(emitter).toString(), 'List<String>');
        expect(field.annotations, isEmpty);
      });

      test('generates nested class property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'address',
              model: ClassModel(
                isDeprecated: false,
                name: 'Address',
                properties: const [],
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'address');
        expect(field.type?.accept(emitter).toString(), 'Address');
        expect(field.annotations, isEmpty);
      });

      test('generates deprecated property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'username',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: true,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'username');
        expect(field.type?.accept(emitter).toString(), 'String');
        expect(field.annotations, hasLength(1));
        expect(
          field.annotations.first.code.accept(emitter).toString(),
          "Deprecated('This property is deprecated.')",
        );
      });

      test('generates optional non-nullable property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'photoUrl',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'photoUrl');
        expect(field.type?.accept(emitter).toString(), 'String?');
        expect(field.annotations, isEmpty);
      });

      test('generates required nullable property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'photoUrl',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'photoUrl');
        expect(field.type?.accept(emitter).toString(), 'String?');
        expect(field.annotations, isEmpty);
      });
    });

    test('generates field with Uri type for UriModel property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'endpoint',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);
      final field = result.fields.first;

      expect(field.name, 'endpoint');
      expect(field.modifier, FieldModifier.final$);

      final typeRef = field.type! as TypeReference;
      expect(typeRef.symbol, 'Uri');
      expect(typeRef.url, 'dart:core');
      expect(typeRef.isNullable, isFalse);
    });

    test('generates nullable Uri field for nullable UriModel property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'optionalEndpoint',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);
      final field = result.fields.first;

      expect(field.name, 'optionalEndpoint');

      final typeRef = field.type! as TypeReference;
      expect(typeRef.symbol, 'Uri');
      expect(typeRef.url, 'dart:core');
      expect(typeRef.isNullable, isTrue);
    });

    test('generates constructor parameter for Uri property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'endpoint',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'callback',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);
      final constructor = result.constructors.first;

      expect(constructor.optionalParameters, hasLength(2));

      final endpointParam = constructor.optionalParameters[0];
      expect(endpointParam.name, 'endpoint');
      expect(endpointParam.required, isTrue);
      expect(endpointParam.toThis, isTrue);

      final callbackParam = constructor.optionalParameters[1];
      expect(callbackParam.name, 'callback');
      expect(callbackParam.required, isFalse);
      expect(callbackParam.toThis, isTrue);
    });

    group('form encoding', () {
      test('generates fromForm constructor for simple properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'SimpleModel',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        final fromFormConstructor = result.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );

        expect(fromFormConstructor.factory, isTrue);
        expect(fromFormConstructor.requiredParameters.length, 1);
        expect(fromFormConstructor.requiredParameters.first.name, 'value');
        expect(
          fromFormConstructor.requiredParameters.first.type
              ?.accept(emitter)
              .toString(),
          'String?',
        );
        expect(fromFormConstructor.optionalParameters.length, 1);
        expect(fromFormConstructor.optionalParameters.first.name, 'explode');
        expect(fromFormConstructor.optionalParameters.first.required, isTrue);
        expect(fromFormConstructor.optionalParameters.first.named, isTrue);
      });

      test(
        'generates working fromForm constructor for list properties with '
        'simple content',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'ModelWithSimpleList',
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedFromFormConstructor = '''
factory ModelWithSimpleList.fromForm(String? value, {required bool explode}) {
  final values = value.decodeObject(
    explode: explode,
    explodeSeparator: '&',
    expectedKeys: {r'items'},
    listKeys: {r'items'},
    context: r'ModelWithSimpleList',
  );
  return ModelWithSimpleList(
    items: values[r'items'].decodeFormStringList(
      context: r'ModelWithSimpleList.items',
    ),
  );
}
        ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedFromFormConstructor)),
          );
        },
      );

      test(
        'generates fromForm constructor that throws for list properties with '
        'complex content',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'ModelWithComplexList',
            properties: [
              Property(
                name: 'items',
                model: ListModel(
                  content: ClassModel(
                    isDeprecated: false,
                    properties: const [],
                    context: context,
                  ),
                  context: context,
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedFromFormConstructor = '''
            factory ModelWithComplexList.fromForm(
              String? value, {
              required bool explode,
            }) {
              throw FormatDecodingException(
                r'Form encoding not supported for ModelWithComplexList: contains complex types',
              );
            }
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedFromFormConstructor)),
          );
        },
      );

      test(
        'form encoding roundtrip works for list with simple content',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'ModelWithSimpleListRoundtrip',
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedFromFormConstructor = '''
factory ModelWithSimpleListRoundtrip.fromForm(
  String? value, {
  required bool explode,
}) {
  final values = value.decodeObject(
    explode: explode,
    explodeSeparator: '&',
    expectedKeys: {r'tags'},
    listKeys: {r'tags'},
    context: r'ModelWithSimpleListRoundtrip',
  );
  return ModelWithSimpleListRoundtrip(
    tags: values[r'tags'].decodeFormStringList(
      context: r'ModelWithSimpleListRoundtrip.tags',
      ),
    );
  }
          ''';

          const expectedToFormMethod = '''
String toForm({
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
).toForm(
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
);
}
          ''';

          const expectedParameterPropertiesMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  result[r'tags'] = tags.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
  );
  return result;
}
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedFromFormConstructor)),
          );

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedToFormMethod)),
          );

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedParameterPropertiesMethod)),
          );
        },
      );

      test('generates fromForm constructor for empty model', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'EmptyModel',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedFromFormBody = '''
          factory EmptyModel.fromForm(String? value, {required bool explode, }) {
            return EmptyModel();
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedFromFormBody)),
        );
      });

      test('generates toForm method for simple properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'SimpleModel',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        final toFormMethod = result.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(toFormMethod.returns?.accept(emitter).toString(), 'String');
        expect(toFormMethod.optionalParameters.length, 3);
        expect(toFormMethod.optionalParameters[0].name, 'explode');
        expect(toFormMethod.optionalParameters[0].required, isTrue);
        expect(toFormMethod.optionalParameters[0].named, isTrue);
        expect(toFormMethod.optionalParameters[1].name, 'allowEmpty');
        expect(toFormMethod.optionalParameters[1].required, isTrue);
        expect(toFormMethod.optionalParameters[1].named, isTrue);
        expect(toFormMethod.optionalParameters[2].name, 'useQueryComponent');
        expect(toFormMethod.optionalParameters[2].required, isFalse);
        expect(toFormMethod.optionalParameters[2].named, isTrue);
      });

      test('generates toForm method for complex properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ComplexModel',
          properties: [
            Property(
              name: 'items',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToFormBody = '''
          String toForm({required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
            return parameterProperties(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ).toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, useQueryComponent: useQueryComponent, );
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedToFormBody)),
        );
      });

      test('generates toForm method for empty model', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'EmptyModel',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToFormMethod = '''
          String toForm({required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
            return parameterProperties(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ).toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, useQueryComponent: useQueryComponent, );
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      });

      test(
        'generates fromForm constructor with mixed property types',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'UserForm',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'age',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'email',
                model: StringModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);

          final fromFormConstructor = result.constructors.firstWhere(
            (c) => c.name == 'fromForm',
          );
          expect(fromFormConstructor.factory, isTrue);
          expect(fromFormConstructor.requiredParameters.length, 1);
          expect(fromFormConstructor.optionalParameters.length, 1);

          expect(
            fromFormConstructor.requiredParameters.first.type
                ?.accept(emitter)
                .toString(),
            'String?',
          );
          expect(
            fromFormConstructor.optionalParameters.first.type
                ?.accept(emitter)
                .toString(),
            'bool',
          );
          final generatedCode = result.accept(emitter).toString();
          const expectedReturnStatement = '''
            return UserForm(name: values[r'name'].decodeFormString(context: r'UserForm.name'), age: values[r'age'].decodeFormInt(context: r'UserForm.age'), email: values[r'email'].decodeFormNullableString(context: r'UserForm.email'), );
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedReturnStatement)),
          );
        },
      );

      test(
        'generates fromForm with nullable decoder for optional '
        'non-nullable properties',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'OptionalForm',
            properties: [
              Property(
                name: 'required',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'optional',
                model: StringModel(context: context),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);
          final generatedCode = result.accept(emitter).toString();

          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                "values[r'optional'].decodeFormNullableString(context: "
                "r'OptionalForm.optional')",
              ),
            ),
          );

          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                "values[r'required'].decodeFormString(context: "
                "r'OptionalForm.required')",
              ),
            ),
          );
        },
      );

      test(
        'generates fromForm with null-safe list operations for optional lists',
        () {
          // Tests that optional list fields use null-safe navigation (.?map)
          // to avoid calling methods on potentially null lists
          final model = ClassModel(
            isDeprecated: false,
            name: 'ListForm',
            properties: [
              Property(
                name: 'required',
                model: ListModel(
                  content: IntegerModel(context: context),
                  context: context,
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'optional',
                model: ListModel(
                  content: IntegerModel(context: context),
                  context: context,
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);
          final generatedCode = result.accept(emitter).toString();

          // Required list should use regular .map()
          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                "values[r'required'].decodeFormStringList(context: "
                "r'ListForm.required').map",
              ),
            ),
          );

          // Optional list should use null-safe ?.map()
          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                "values[r'optional'].decodeFormNullableStringList(context: "
                "r'ListForm.optional')?.map",
              ),
            ),
          );
        },
      );

      test(
        'generates toForm method with mixed property types',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'UserForm',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'age',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'email',
                model: StringModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);

          const expectedToFormMethod = '''
          String toForm({required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
            return parameterProperties(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ).toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, useQueryComponent: useQueryComponent, );
          }
        ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedToFormMethod)),
          );
        },
      );

      test('generates fromForm constructor with all primitive types', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'AllTypesForm',
          properties: [
            Property(
              name: 'text',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'number',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'decimal',
              model: DoubleModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'flag',
              model: BooleanModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'timestamp',
              model: DateTimeModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'date_only',
              model: DateModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'precise_amount',
              model: DecimalModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'website',
              model: UriModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        final fromFormConstructor = result.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );
        expect(fromFormConstructor.factory, isTrue);
        expect(fromFormConstructor.requiredParameters.length, 1);
        expect(fromFormConstructor.optionalParameters.length, 1);

        const expectedReturnStatement = '''
          return AllTypesForm(text: values[r'text'].decodeFormString(context: r'AllTypesForm.text'), number: values[r'number'].decodeFormInt(context: r'AllTypesForm.number'), decimal: values[r'decimal'].decodeFormDouble(context: r'AllTypesForm.decimal'), flag: values[r'flag'].decodeFormBool(context: r'AllTypesForm.flag'), timestamp: values[r'timestamp'].decodeFormDateTime(context: r'AllTypesForm.timestamp'), dateOnly: values[r'date_only'].decodeFormDate(context: r'AllTypesForm.date_only'), preciseAmount: values[r'precise_amount'].decodeFormBigDecimal(context: r'AllTypesForm.precise_amount'), website: values[r'website'].decodeFormUri(context: r'AllTypesForm.website'), );
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedReturnStatement)),
        );
      });

      test(
        'generates fromForm constructor with required nullable properties',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'NullableForm',
            properties: [
              Property(
                name: 'required_nullable_name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: true,
                isDeprecated: false,
              ),
              Property(
                name: 'required_nullable_count',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: true,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);

          final fromFormConstructor = result.constructors.firstWhere(
            (c) => c.name == 'fromForm',
          );
          expect(fromFormConstructor.factory, isTrue);
          expect(fromFormConstructor.requiredParameters.length, 1);
          expect(fromFormConstructor.optionalParameters.length, 1);

          const expectedReturnStatement = '''
            return NullableForm(requiredNullableName: values[r'required_nullable_name'].decodeFormNullableString(context: r'NullableForm.required_nullable_name'), requiredNullableCount: values[r'required_nullable_count'].decodeFormNullableInt(context: r'NullableForm.required_nullable_count'), );
          ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedReturnStatement)),
          );
        },
      );
    });

    group('toMatrix method', () {
      test('generates toMatrix method for simple properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'SimpleModel',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        final toMatrixMethod = result.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );
        expect(toMatrixMethod.returns?.accept(emitter).toString(), 'String');
        expect(toMatrixMethod.requiredParameters.length, 1);
        expect(toMatrixMethod.requiredParameters.first.name, 'paramName');
        expect(
          toMatrixMethod.requiredParameters.first.type
              ?.accept(emitter)
              .toString(),
          'String',
        );
        expect(toMatrixMethod.optionalParameters.length, 2);
        expect(toMatrixMethod.optionalParameters.first.name, 'explode');
        expect(toMatrixMethod.optionalParameters.first.required, isTrue);
        expect(toMatrixMethod.optionalParameters.first.named, isTrue);
        expect(
          toMatrixMethod.optionalParameters.first.type
              ?.accept(emitter)
              .toString(),
          'bool',
        );
        expect(toMatrixMethod.optionalParameters.last.name, 'allowEmpty');
        expect(toMatrixMethod.optionalParameters.last.required, isTrue);
        expect(toMatrixMethod.optionalParameters.last.named, isTrue);
        expect(
          toMatrixMethod.optionalParameters.last.type
              ?.accept(emitter)
              .toString(),
          'bool',
        );

        const expectedToMatrixMethod = '''
          String toMatrix(String paramName, {required bool explode, required bool allowEmpty, }) {
            return parameterProperties(allowEmpty: allowEmpty).toMatrix(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          }
        ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToMatrixMethod)),
        );
      });

      test('generates toMatrix method for complex properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ComplexModel',
          properties: [
            Property(
              name: 'simpleProp',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'complexProp',
              model: ClassModel(
                isDeprecated: false,
                name: 'NestedModel',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        // Test method signature
        final toMatrixMethod = result.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );
        expect(toMatrixMethod.returns?.accept(emitter).toString(), 'String');
        expect(toMatrixMethod.requiredParameters.length, 1);
        expect(toMatrixMethod.requiredParameters.first.name, 'paramName');
        expect(toMatrixMethod.optionalParameters.length, 2);
        expect(toMatrixMethod.optionalParameters.first.name, 'explode');
        expect(toMatrixMethod.optionalParameters.last.name, 'allowEmpty');

        const expectedToMatrixMethod = '''
          String toMatrix(String paramName, {required bool explode, required bool allowEmpty, }) {
            return parameterProperties(allowEmpty: allowEmpty).toMatrix(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          }
        ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToMatrixMethod)),
        );
      });

      test('generates toMatrix method for empty model', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'EmptyModel',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);
        final toMatrixMethod = result.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );
        expect(toMatrixMethod.returns?.accept(emitter).toString(), 'String');
        expect(toMatrixMethod.requiredParameters.length, 1);
        expect(toMatrixMethod.requiredParameters.first.name, 'paramName');
        expect(toMatrixMethod.optionalParameters.length, 2);
        expect(toMatrixMethod.optionalParameters.first.name, 'explode');
        expect(toMatrixMethod.optionalParameters.last.name, 'allowEmpty');

        const expectedToMatrixMethod = '''
          String toMatrix(String paramName, {required bool explode, required bool allowEmpty, }) {
            return parameterProperties(allowEmpty: allowEmpty).toMatrix(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          }
        ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToMatrixMethod)),
        );
      });

      test(
        'toMatrix method generates proper method body for single '
        'property model',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'TestModel',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);

          final toMatrixMethod = result.methods.firstWhere(
            (m) => m.name == 'toMatrix',
          );
          expect(toMatrixMethod.name, 'toMatrix');
          expect(toMatrixMethod.returns?.accept(emitter).toString(), 'String');
          expect(
            toMatrixMethod.lambda,
            isNot(isTrue),
          );

          const expectedToMatrixMethod = '''
          String toMatrix(String paramName, {required bool explode, required bool allowEmpty, }) {
            return parameterProperties(allowEmpty: allowEmpty).toMatrix(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          }
        ''';

          final generatedCode = result.accept(emitter).toString();
          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedToMatrixMethod)),
          );
        },
      );

      test('encoding methods have @override annotation', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'TestModel',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        // Verify toSimple has @override
        final toSimple = result.methods.firstWhere((m) => m.name == 'toSimple');
        expect(toSimple.annotations, hasLength(1));
        expect(
          toSimple.annotations.first.code.accept(emitter).toString(),
          'override',
        );

        // Verify toForm has @override
        final toForm = result.methods.firstWhere((m) => m.name == 'toForm');
        expect(toForm.annotations, hasLength(1));
        expect(
          toForm.annotations.first.code.accept(emitter).toString(),
          'override',
        );

        // Verify toLabel has @override
        final toLabel = result.methods.firstWhere((m) => m.name == 'toLabel');
        expect(toLabel.annotations, hasLength(1));
        expect(
          toLabel.annotations.first.code.accept(emitter).toString(),
          'override',
        );

        // Verify toMatrix has @override
        final toMatrix = result.methods.firstWhere((m) => m.name == 'toMatrix');
        expect(toMatrix.annotations, hasLength(1));
        expect(
          toMatrix.annotations.first.code.accept(emitter).toString(),
          'override',
        );

        // Verify toDeepObject has @override
        final toDeepObject = result.methods.firstWhere(
          (m) => m.name == 'toDeepObject',
        );
        expect(toDeepObject.annotations, hasLength(1));
        expect(
          toDeepObject.annotations.first.code.accept(emitter).toString(),
          'override',
        );

        // Verify toJson has @override
        final toJson = result.methods.firstWhere((m) => m.name == 'toJson');
        expect(toJson.annotations, hasLength(1));
        expect(
          toJson.annotations.first.code.accept(emitter).toString(),
          'override',
        );
      });
    });

    group('nullable class generation', () {
      test('generates Raw prefix for nullable class', () {
        final model = ClassModel(
          name: 'User',
          properties: const [],
          context: context,
          isDeprecated: false,
          isNullable: true,
        );

        final classes = generator.generateClasses(model);

        expect(classes.length, 2);
        expect(classes[0], isA<Class>());
        expect(classes[1], isA<TypeDef>());

        final classSpec = classes[0] as Class;
        expect(classSpec.name, r'$RawUser');
      });

      test('generates typedef for nullable class', () {
        final model = ClassModel(
          name: 'Product',
          properties: const [],
          context: context,
          isDeprecated: false,
          isNullable: true,
        );

        final classes = generator.generateClasses(model);

        final typedef = classes[1] as TypeDef;
        expect(typedef.name, 'Product');
        expect(
          typedef.definition.accept(emitter).toString(),
          r'$RawProduct?',
        );
      });

      test('non-nullable class generates only class without typedef', () {
        final model = ClassModel(
          name: 'Order',
          properties: const [],
          context: context,
          isDeprecated: false,
        );

        final classes = generator.generateClasses(model);

        // Without properties, no copyWith is generated.
        expect(classes.length, 1);
        expect(classes.whereType<Class>().length, 1);
        expect(classes.whereType<TypeDef>().length, 0);

        final classSpec = classes[0] as Class;
        expect(classSpec.name, 'Order');
      });

      test('generates correct filename for nullable class', () {
        final model = ClassModel(
          name: 'UserProfile',
          properties: const [],
          context: context,
          isDeprecated: false,
          isNullable: true,
        );

        final result = generator.generate(model);
        expect(result.filename, 'user_profile.dart');
      });

      test('nullable class with properties uses Raw prefix', () {
        final model = ClassModel(
          name: 'Account',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          isDeprecated: false,
          isNullable: true,
        );

        final classes = generator.generateClasses(model);

        final classSpec = classes[0] as Class;
        expect(classSpec.name, r'$RawAccount');
        expect(classSpec.fields.length, 1);
        expect(classSpec.fields.first.name, 'id');

        // Typedef should be the last element.
        final typedef = classes.last as TypeDef;
        expect(typedef.name, 'Account');
        expect(
          typedef.definition.accept(emitter).toString(),
          r'$RawAccount?',
        );
      });
    });
  });
}
