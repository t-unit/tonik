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
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'example',
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
        examples: const [],
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
        examples: const [],
      );

      final result = generator.generateClass(model);

      expect(result.annotations.length, 1);

      final annotation = result.annotations.first;
      expect(annotation.accept(emitter).toString(), 'immutable');
    });

    test(
      'generates class implementing ParameterEncodable and UriEncodable',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        expect(result.implements.length, 2);
        final implementsNames = result.implements
            .map((i) => i.accept(emitter).toString())
            .toList();
        expect(implementsNames, contains('ParameterEncodable'));
        expect(implementsNames, contains('UriEncodable'));
      },
    );

    group('uriEncode', () {
      test('generates uriEncode that throws for class with properties', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'age',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final generated = format(result.accept(emitter).toString());

        const expectedUriEncode = '''
          @override
          String uriEncode({ required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, }) {
            throw EncodingException(
              r'Cannot uriEncode User: complex types cannot be URI-encoded',
            );
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedUriEncode)),
        );
      });

      test('generates uriEncode that throws for empty class', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Empty',
          properties: const [],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final generated = format(result.accept(emitter).toString());

        const expectedUriEncode = '''
          @override
          String uriEncode({ required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, }) {
            throw EncodingException(
              r'Cannot uriEncode Empty: complex types cannot be URI-encoded',
            );
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedUriEncode)),
        );
      });

      test('generates uriEncode with correct signature', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Item',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final uriEncodeMethod = result.methods.firstWhere(
          (m) => m.name == 'uriEncode',
        );

        expect(uriEncodeMethod.returns?.accept(emitter).toString(), 'String');
        expect(
          uriEncodeMethod.annotations.first.accept(emitter).toString(),
          'override',
        );

        final allowEmptyParam = uriEncodeMethod.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(emitter).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final useQueryComponentParam = uriEncodeMethod.optionalParameters
            .firstWhere(
              (p) => p.name == 'useQueryComponent',
            );
        expect(
          useQueryComponentParam.type?.accept(emitter).toString(),
          'bool',
        );
        expect(useQueryComponentParam.named, isTrue);
        expect(useQueryComponentParam.required, isFalse);
        expect(
          useQueryComponentParam.defaultTo?.accept(emitter).toString(),
          'false',
        );
      });
    });

    group('doc comments', () {
      test('generates class with doc comment from description', () {
        final model = ClassModel(
          isDeprecated: false,
          description: 'A user in the system',
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
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
          examples: const [],
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
          examples: const [],
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
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final field = result.fields.first;

          expect(field.docs, ['/// Use userId instead']);
          expect(field.annotations, hasLength(1));
        },
      );

      test('renders class-level examples', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [
            Example(
              name: null,
              summary: null,
              description: null,
              value: {'id': 1, 'name': 'alice'},
            ),
          ],
        );

        final result = generator.generateClass(model);

        expect(result.docs, [
          '/// **Example**:',
          '/// ```json',
          '/// {',
          '///   "id": 1,',
          '///   "name": "alice"',
          '/// }',
          '/// ```',
        ]);
      });

      test('appends class-level examples after description', () {
        final model = ClassModel(
          isDeprecated: false,
          description: 'A user in the system',
          name: 'User',
          properties: const [],
          context: context,
          examples: const [
            Example(
              name: null,
              summary: null,
              description: null,
              value: 1,
            ),
          ],
        );

        final result = generator.generateClass(model);

        expect(result.docs, [
          '/// A user in the system',
          '///',
          '/// **Example**:',
          '/// ```json',
          '/// 1',
          '/// ```',
        ]);
      });

      test('renders property-level examples', () {
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
              examples: const [
                Example(
                  name: null,
                  summary: null,
                  description: null,
                  value: 42,
                ),
              ],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.docs, [
          '/// **Example**:',
          '/// ```json',
          '/// 42',
          '/// ```',
        ]);
      });

      test('appends property-level examples after description', () {
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
              examples: const [
                Example(
                  name: null,
                  summary: null,
                  description: null,
                  value: 42,
                ),
              ],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.docs, [
          '/// The unique identifier',
          '///',
          '/// **Example**:',
          '/// ```json',
          '/// 42',
          '/// ```',
        ]);
      });

      test('skips example separator when example list collapses to empty', () {
        final model = ClassModel(
          isDeprecated: false,
          description: 'A user in the system',
          name: 'User',
          properties: const [],
          context: context,
          examples: const [
            Example(
              name: null,
              summary: null,
              description: null,
              value: null,
            ),
          ],
        );

        final result = generator.generateClass(model);

        expect(result.docs, ['/// A user in the system']);
      });
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
        examples: const [],
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
        examples: const [],
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'bio',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
        examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'tags');
        expect(field.type?.accept(emitter).toString(), 'List<String>');
        expect(field.annotations, isEmpty);
      });

      test('generates list of nullable strings property', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Profile',
          properties: [
            Property(
              name: 'nicknames',
              model: ListModel(
                content: StringModel(context: context),
                isContentNullable: true,
                context: context,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;
        final fieldType = field.type! as TypeReference;

        expect(field.name, 'nicknames');
        expect(fieldType.symbol, 'List');
        expect(fieldType.isNullable, isFalse);
        expect(fieldType.types, hasLength(1));

        final itemType = fieldType.types.first as TypeReference;
        expect(itemType.symbol, 'String');
        expect(itemType.isNullable, isTrue);
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
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'callback',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
      test(
        'an alias-wrapped array property routes form encoding to the contains '
        'complex types path with no explode descriptor',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'ModelWithAliasedList',
            properties: [
              Property(
                name: 'tags',
                model: AliasModel(
                  name: 'TagList',
                  model: ListModel(
                    content: StringModel(context: context),
                    context: context,
                    examples: const [],
                  ),
                  context: context,
                  defaultValue: null,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedParameterPropertiesMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) => throw EncodingException(
  r'parameterProperties not supported for ModelWithAliasedList: contains complex types',
);
          ''';

          const expectedToFormMethod = '''
List<ParameterEntry> toForm(
String paramName, {
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
allowReserved: allowReserved, fieldEncodings: fieldEncodings,
).toForm(
paramName,
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
fieldEncodings: fieldEncodings,
);
}
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedParameterPropertiesMethod)),
          );
          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedToFormMethod)),
          );
        },
      );

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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedFromFormConstructor = r'''
factory ModelWithSimpleList.fromForm(String? value, {required bool explode}) {
  final _$values = value.decodeObject(
    explode: explode,
    explodeSeparator: '&',
    expectedKeys: {r'items'},
    listKeys: {r'items'},
    context: r'ModelWithSimpleList',
  );
  return ModelWithSimpleList(
    items: _$values[r'items'].decodeFormStringList(
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
                    examples: const [],
                  ),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedFromFormConstructor = '''
            factory ModelWithComplexList.fromForm(
              String? value, {
              required bool explode,
            }) {
              throw FormDecodingException(
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
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedFromFormConstructor = r'''
factory ModelWithSimpleListRoundtrip.fromForm(
  String? value, {
  required bool explode,
}) {
  final _$values = value.decodeObject(
    explode: explode,
    explodeSeparator: '&',
    expectedKeys: {r'tags'},
    listKeys: {r'tags'},
    context: r'ModelWithSimpleListRoundtrip',
  );
  return ModelWithSimpleListRoundtrip(
    tags: _$values[r'tags'].decodeFormStringList(
      context: r'ModelWithSimpleListRoundtrip.tags',
      ),
    );
  }
          ''';

          const expectedToFormMethod = '''
List<ParameterEntry> toForm(
String paramName, {
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
allowReserved: allowReserved, fieldEncodings: fieldEncodings,
).toForm(
paramName,
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
fieldEncodings: fieldEncodings,
explodedValues: <String, List<String>>{
r'tags': tags
    .map(
      (e) => e.uriEncode(
        allowEmpty: true,
        useQueryComponent: useQueryComponent,
        allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
      ),
    )
    .toList(),
},
);
}
          ''';

          const expectedParameterPropertiesMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'tags'] = tags.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
  );
  return _$result;
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

      test(
        'array property whose raw name differs from the Dart field keys all '
        'three maps by the raw name',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'RawNameListModel',
            properties: [
              Property(
                name: 'user-tags',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedToFormMethod = '''
List<ParameterEntry> toForm(
String paramName, {
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
allowReserved: allowReserved, fieldEncodings: fieldEncodings,
).toForm(
paramName,
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
fieldEncodings: fieldEncodings,
explodedValues: <String, List<String>>{
r'user-tags': userTags
    .map(
      (e) => e.uriEncode(
        allowEmpty: true,
        useQueryComponent: useQueryComponent,
        allowReserved:
            fieldEncodings[r'user-tags']?.allowReserved ?? allowReserved,
      ),
    )
    .toList(),
},
);
}
          ''';

          const expectedParameterPropertiesMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'user-tags'] = userTags.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'user-tags']?.allowReserved ?? allowReserved,
  );
  return _$result;
}
          ''';

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

      test(
        'toForm null-guards explodedValues for an optional array property',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'OptionalListModel',
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedToFormMethod = '''
List<ParameterEntry> toForm(
String paramName, {
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
allowReserved: allowReserved, fieldEncodings: fieldEncodings,
).toForm(
paramName,
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
fieldEncodings: fieldEncodings,
explodedValues: <String, List<String>>{
r'tags': tags == null
    ? const <String>[]
    : tags!
        .map(
          (e) => e.uriEncode(
            allowEmpty: true,
            useQueryComponent: useQueryComponent,
            allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
          ),
        )
        .toList(),
},
);
}
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedToFormMethod)),
          );
        },
      );

      test(
        'toForm explodedValues maps null elements of a nullable-content array '
        'property to empty strings',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'NullableElementListModel',
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: context),
                  isContentNullable: true,
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedToFormMethod = '''
List<ParameterEntry> toForm(
String paramName, {
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
allowReserved: allowReserved, fieldEncodings: fieldEncodings,
).toForm(
paramName,
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
fieldEncodings: fieldEncodings,
explodedValues: <String, List<String>>{
r'tags': tags
    .map(
      (e) => e == null
          ? ''
          : e.uriEncode(
              allowEmpty: true,
              useQueryComponent: useQueryComponent,
              allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
            ),
    )
    .toList(),
},
);
}
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedToFormMethod)),
          );
        },
      );

      test(
        'toForm explodedValues unlocks an immutable-collection array property '
        'before mapping elements',
        () {
          final immutableGenerator = ClassGenerator(
            nameManager: nameManager,
            package: 'example',
            useImmutableCollections: true,
          );

          final model = ClassModel(
            isDeprecated: false,
            name: 'ImmutableListModel',
            properties: [
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = immutableGenerator.generateClass(model);
          final generatedCode = format(result.accept(emitter).toString());

          const expectedToFormMethod = '''
List<ParameterEntry> toForm(
String paramName, {
required bool explode,
required bool allowEmpty,
bool useQueryComponent = false,
bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
return parameterProperties(
allowEmpty: allowEmpty,
useQueryComponent: useQueryComponent,
allowReserved: allowReserved, fieldEncodings: fieldEncodings,
).toForm(
paramName,
explode: explode,
allowEmpty: allowEmpty,
alreadyEncoded: true,
useQueryComponent: useQueryComponent,
fieldEncodings: fieldEncodings,
explodedValues: <String, List<String>>{
r'tags': tags.unlock
    .map(
      (e) => e.uriEncode(
        allowEmpty: true,
        useQueryComponent: useQueryComponent,
        allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
      ),
    )
    .toList(),
},
);
}
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedToFormMethod)),
          );
        },
      );

      test('generates fromForm constructor for empty model', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'EmptyModel',
          properties: const [],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        final toFormMethod = result.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(
          toFormMethod.returns?.accept(emitter).toString(),
          'List<ParameterEntry>',
        );
        expect(toFormMethod.requiredParameters.length, 1);
        expect(toFormMethod.requiredParameters[0].name, 'paramName');
        expect(toFormMethod.optionalParameters.length, 5);
        expect(toFormMethod.optionalParameters[0].name, 'explode');
        expect(toFormMethod.optionalParameters[0].required, isTrue);
        expect(toFormMethod.optionalParameters[0].named, isTrue);
        expect(toFormMethod.optionalParameters[1].name, 'allowEmpty');
        expect(toFormMethod.optionalParameters[1].required, isTrue);
        expect(toFormMethod.optionalParameters[1].named, isTrue);
        expect(toFormMethod.optionalParameters[2].name, 'useQueryComponent');
        expect(toFormMethod.optionalParameters[2].required, isFalse);
        expect(toFormMethod.optionalParameters[2].named, isTrue);
        expect(toFormMethod.optionalParameters[3].name, 'allowReserved');
        expect(toFormMethod.optionalParameters[3].required, isFalse);
        expect(toFormMethod.optionalParameters[3].named, isTrue);
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
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        const expectedToFormBody = '''
          List<ParameterEntry> toForm(String paramName, {required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String,FormFieldEncoding> fieldEncodings = const {}, }) {
            return parameterProperties(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, allowReserved: allowReserved, fieldEncodings: fieldEncodings, ).toForm(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, useQueryComponent: useQueryComponent, fieldEncodings: fieldEncodings, explodedValues: <String, List<String>>{r'items': items.map((e) => e.uriEncode(allowEmpty: true, useQueryComponent: useQueryComponent, allowReserved: fieldEncodings[r'items']?.allowReserved ?? allowReserved, )).toList()}, );
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
          examples: const [],
        );

        final result = generator.generateClass(model);

        const expectedToFormMethod = '''
          List<ParameterEntry> toForm(String paramName, {required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String,FormFieldEncoding> fieldEncodings = const {}, }) {
            return parameterProperties(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, allowReserved: allowReserved, fieldEncodings: fieldEncodings, ).toForm(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, useQueryComponent: useQueryComponent, fieldEncodings: fieldEncodings, );
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
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'age',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'email',
                model: StringModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
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
          const expectedReturnStatement = r'''
            return UserForm(name: _$values[r'name'].decodeFormString(context: r'UserForm.name'), age: _$values[r'age'].decodeFormInt(context: r'UserForm.age'), email: _$values[r'email'].decodeFormNullableString(context: r'UserForm.email'), );
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
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'optional',
                model: StringModel(context: context),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = result.accept(emitter).toString();

          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                r"_$values[r'optional'].decodeFormNullableString(context: "
                "r'OptionalForm.optional')",
              ),
            ),
          );

          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                r"_$values[r'required'].decodeFormString(context: "
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
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'optional',
                model: ListModel(
                  content: IntegerModel(context: context),
                  context: context,
                  examples: const [],
                ),
                isRequired: false,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final generatedCode = result.accept(emitter).toString();

          // Required list should use regular .map()
          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                r"_$values[r'required'].decodeFormStringList(context: "
                "r'ListForm.required').map",
              ),
            ),
          );

          // Optional list should use null-safe ?.map()
          expect(
            collapseWhitespace(generatedCode),
            contains(
              collapseWhitespace(
                r"_$values[r'optional'].decodeFormNullableStringList(context: "
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
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'age',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'email',
                model: StringModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);

          const expectedToFormMethod = '''
          List<ParameterEntry> toForm(String paramName, {required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String,FormFieldEncoding> fieldEncodings = const {}, }) {
            return parameterProperties(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, allowReserved: allowReserved, fieldEncodings: fieldEncodings, ).toForm(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, useQueryComponent: useQueryComponent, fieldEncodings: fieldEncodings, );
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'number',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'decimal',
              model: DoubleModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'flag',
              model: BooleanModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'timestamp',
              model: DateTimeModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'date_only',
              model: DateModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'precise_amount',
              model: DecimalModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'website',
              model: UriModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        final fromFormConstructor = result.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );
        expect(fromFormConstructor.factory, isTrue);
        expect(fromFormConstructor.requiredParameters.length, 1);
        expect(fromFormConstructor.optionalParameters.length, 1);

        const expectedReturnStatement = r'''
          return AllTypesForm(text: _$values[r'text'].decodeFormString(context: r'AllTypesForm.text'), number: _$values[r'number'].decodeFormInt(context: r'AllTypesForm.number'), decimal: _$values[r'decimal'].decodeFormDouble(context: r'AllTypesForm.decimal'), flag: _$values[r'flag'].decodeFormBool(context: r'AllTypesForm.flag'), timestamp: _$values[r'timestamp'].decodeFormDateTime(context: r'AllTypesForm.timestamp'), dateOnly: _$values[r'date_only'].decodeFormDate(context: r'AllTypesForm.date_only'), preciseAmount: _$values[r'precise_amount'].decodeFormBigDecimal(context: r'AllTypesForm.precise_amount'), website: _$values[r'website'].decodeFormUri(context: r'AllTypesForm.website'), );
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
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'required_nullable_count',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);

          final fromFormConstructor = result.constructors.firstWhere(
            (c) => c.name == 'fromForm',
          );
          expect(fromFormConstructor.factory, isTrue);
          expect(fromFormConstructor.requiredParameters.length, 1);
          expect(fromFormConstructor.optionalParameters.length, 1);

          const expectedReturnStatement = r'''
            return NullableForm(requiredNullableName: _$values[r'required_nullable_name'].decodeFormNullableString(context: r'NullableForm.required_nullable_name'), requiredNullableCount: _$values[r'required_nullable_count'].decodeFormNullableInt(context: r'NullableForm.required_nullable_count'), );
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
          examples: const [],
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
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
          examples: const [],
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
          examples: const [],
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
          examples: const [],
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
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          isDeprecated: false,
          isNullable: true,
          examples: const [],
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

    group('additionalProperties', () {
      group('constructor', () {
        test(
          'includes AP parameter with const {} default for unrestricted',
          () {
            final model = ClassModel(
              isDeprecated: false,
              name: 'Config',
              properties: [
                Property(
                  name: 'name',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              context: context,
              additionalProperties: const UnrestrictedAdditionalProperties(),
              examples: const [],
            );

            final result = generator.generateClass(model);
            final constructor = result.constructors.first;

            final apParam = constructor.optionalParameters.firstWhere(
              (p) => p.name == 'additionalProperties',
            );
            expect(apParam.named, isTrue);
            expect(apParam.required, isFalse);
            expect(apParam.toThis, isTrue);
            expect(
              apParam.defaultTo?.accept(emitter).toString(),
              'const {}',
            );
          },
        );

        test('includes AP parameter with const {} default for typed', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Labels',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: StringModel(context: context),
            ),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final constructor = result.constructors.first;

          final apParam = constructor.optionalParameters.firstWhere(
            (p) => p.name == 'additionalProperties',
          );
          expect(apParam.named, isTrue);
          expect(apParam.required, isFalse);
          expect(apParam.toThis, isTrue);
          expect(
            apParam.defaultTo?.accept(emitter).toString(),
            'const {}',
          );
        });

        test('omits AP parameter for NoAdditionalProperties', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Strict',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const NoAdditionalProperties(),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final constructor = result.constructors.first;

          final apParams = constructor.optionalParameters.where(
            (p) => p.name == 'additionalProperties',
          );
          expect(apParams, isEmpty);
        });

        test('omits AP parameter when additionalProperties is null', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Plain',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final result = generator.generateClass(model);
          final constructor = result.constructors.first;

          final apParams = constructor.optionalParameters.where(
            (p) => p.name == 'additionalProperties',
          );
          expect(apParams, isEmpty);
        });
      });

      group('field', () {
        test('generates Map<String, Object?> field for unrestricted', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Config',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const UnrestrictedAdditionalProperties(),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final apField = result.fields.firstWhere(
            (f) => f.name == 'additionalProperties',
          );

          expect(
            apField.type?.accept(emitter).toString(),
            'Map<String,Object?>',
          );
          expect(apField.modifier, FieldModifier.final$);
        });

        test('generates Map<String, String> field for typed string', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Labels',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: StringModel(context: context),
            ),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final apField = result.fields.firstWhere(
            (f) => f.name == 'additionalProperties',
          );

          expect(
            apField.type?.accept(emitter).toString(),
            'Map<String,String>',
          );
        });

        test('generates Map<String, Widget> field for typed complex', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'WidgetMap',
            properties: [
              Property(
                name: 'version',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: ClassModel(
                isDeprecated: false,
                name: 'Widget',
                properties: const [],
                context: context,
                examples: const [],
              ),
            ),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final apField = result.fields.firstWhere(
            (f) => f.name == 'additionalProperties',
          );

          expect(
            apField.type?.accept(emitter).toString(),
            'Map<String,Widget>',
          );
        });

        test('omits AP field for NoAdditionalProperties', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Strict',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const NoAdditionalProperties(),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final apFields = result.fields.where(
            (f) => f.name == 'additionalProperties',
          );
          expect(apFields, isEmpty);
        });
      });

      group('collision renaming', () {
        test(
          'renames AP field when property named additionalProperties exists',
          () {
            final model = ClassModel(
              isDeprecated: false,
              name: 'Collision',
              properties: [
                Property(
                  name: 'additionalProperties',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              context: context,
              additionalProperties: const UnrestrictedAdditionalProperties(),
              examples: const [],
            );

            final result = generator.generateClass(model);

            // The regular property keeps its name
            final regularField = result.fields.firstWhere(
              (f) => f.name == 'additionalProperties',
            );
            expect(
              regularField.type?.accept(emitter).toString(),
              'String',
            );

            // AP field is renamed to additionalProperties2
            final apField = result.fields.firstWhere(
              (f) => f.name == 'additionalProperties2',
            );
            expect(
              apField.type?.accept(emitter).toString(),
              'Map<String,Object?>',
            );
          },
        );

        test('renames AP constructor param when collision exists', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Collision',
            properties: [
              Property(
                name: 'additionalProperties',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const UnrestrictedAdditionalProperties(),
            examples: const [],
          );

          final result = generator.generateClass(model);
          final constructor = result.constructors.first;

          final apParam = constructor.optionalParameters.firstWhere(
            (p) => p.name == 'additionalProperties2',
          );
          expect(apParam.named, isTrue);
          expect(apParam.required, isFalse);
          expect(apParam.toThis, isTrue);
        });
      });

      group('equality', () {
        test('includes AP in equals for unrestricted', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Config',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const UnrestrictedAdditionalProperties(),
            examples: const [],
          );

          const expectedMethod = r'''
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    const _$deepEquals = DeepCollectionEquality();
    return other is Config &&
        other.name == this.name &&
        _$deepEquals.equals(
          other.additionalProperties,
          this.additionalProperties,
        );
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('includes AP in hashCode for unrestricted', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Config',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const UnrestrictedAdditionalProperties(),
            examples: const [],
          );

          const expectedMethod = '''
  @override
  int get hashCode {
    const deepEquals = DeepCollectionEquality();
    return Object.hashAll([name, deepEquals.hash(additionalProperties)]);
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('excludes AP from equals for NoAdditionalProperties', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Strict',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const NoAdditionalProperties(),
            examples: const [],
          );

          const expectedMethod = '''
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Strict && other.name == this.name;
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('excludes AP from hashCode for NoAdditionalProperties', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Strict',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: const NoAdditionalProperties(),
            examples: const [],
          );

          const expectedMethod = '''
  @override
  int get hashCode => name.hashCode;''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('parameterProperties', () {
        test('generates AP loop with uriEncode for typed simple values', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Counts',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: IntegerModel(context: context),
            ),
            examples: const [],
          );

          const expectedMethod = r'''
  Map<String, String> parameterProperties({
    bool allowEmpty = true,
    bool allowLists = true,
    bool useQueryComponent = false,
    bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
  }) {
    final _$result = <String, String>{};
    _$result[r'name'] = name.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
    );
    for (final _$e in additionalProperties.entries) {
      _$result[_$e.key] = _$e.value.uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      );
    }
    return _$result;
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test(
          'generates AP loop with EncodingException for typed complex values',
          () {
            final model = ClassModel(
              isDeprecated: false,
              name: 'WidgetMap',
              properties: [
                Property(
                  name: 'version',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              context: context,
              additionalProperties: TypedAdditionalProperties(
                valueModel: ClassModel(
                  isDeprecated: false,
                  name: 'Widget',
                  properties: const [],
                  context: context,
                  examples: const [],
                ),
              ),
              examples: const [],
            );

            const expectedMethod = r"""
  Map<String, String> parameterProperties({
    bool allowEmpty = true,
    bool allowLists = true,
    bool useQueryComponent = false,
    bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
  }) {
    final _$result = <String, String>{};
    _$result[r'version'] = version.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'version']?.allowReserved ?? allowReserved,
    );
    if (additionalProperties.isNotEmpty) {
      throw EncodingException(
        r'Additional properties with complex types cannot be parameter encoded.',
      );
    }
    return _$result;
  }""";

            final generatedClass = generator.generateClass(model);
            expect(
              collapseWhitespace(
                format(generatedClass.accept(emitter).toString()),
              ),
              contains(collapseWhitespace(expectedMethod)),
            );
          },
        );
      });

      group('fromSimple', () {
        test('captures typed string AP with decode call', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Labels',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: StringModel(context: context),
            ),
            examples: const [],
          );

          const expectedMethod = r'''
  factory Labels.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'id'},
      listKeys: {},
      context: r'Labels',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleString(
          context: r'Labels.additionalProperties',
        );
      }
    }
    return Labels(
      id: _$values[r'id'].decodeSimpleInt(context: r'Labels.id'),
      additionalProperties: _$additional,
    );
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('does not capture complex typed AP', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'WidgetMap',
            properties: [
              Property(
                name: 'version',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: ClassModel(
                isDeprecated: false,
                name: 'Widget',
                properties: const [],
                context: context,
                examples: const [],
              ),
            ),
            examples: const [],
          );

          const expectedMethod = r'''
  factory WidgetMap.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'version'},
      listKeys: {},
      context: r'WidgetMap',
    );
    return WidgetMap(
      version: _$values[r'version'].decodeSimpleInt(
        context: r'WidgetMap.version',
      ),
    );
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('fromForm', () {
        test('captures typed string AP with decode call', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Labels',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: StringModel(context: context),
            ),
            examples: const [],
          );

          const expectedMethod = r'''
  factory Labels.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'id'},
      listKeys: {},
      context: r'Labels',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormString(
          context: r'Labels.additionalProperties',
        );
      }
    }
    return Labels(
      id: _$values[r'id'].decodeFormInt(context: r'Labels.id'),
      additionalProperties: _$additional,
    );
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('captures typed bool AP with decode call', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Flags',
            properties: [
              Property(
                name: 'label',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: BooleanModel(context: context),
            ),
            examples: const [],
          );

          const expectedMethod = r'''
  factory Flags.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'label'},
      listKeys: {},
      context: r'Flags',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'label'};
    final _$additional = <String, bool>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormBool(
          context: r'Flags.additionalProperties',
        );
      }
    }
    return Flags(
      label: _$values[r'label'].decodeFormString(context: r'Flags.label'),
      additionalProperties: _$additional,
    );
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('does not capture complex typed AP', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'WidgetMap',
            properties: [
              Property(
                name: 'version',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: ClassModel(
                isDeprecated: false,
                name: 'Widget',
                properties: const [],
                context: context,
                examples: const [],
              ),
            ),
            examples: const [],
          );

          const expectedMethod = r'''
  factory WidgetMap.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'version'},
      listKeys: {},
      context: r'WidgetMap',
    );
    return WidgetMap(
      version: _$values[r'version'].decodeFormInt(
        context: r'WidgetMap.version',
      ),
    );
  }''';

          final generatedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });
    });

    group('special characters in property names', () {
      test(
        'toJson escapes property name containing single quote',
        () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'FlexibleData',
            properties: [
              Property(
                name: 'id',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: "it's-field",
                model: AnyModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final generatedClass = generator.generateClass(model);
          final generated = format(
            generatedClass.accept(emitter).toString(),
          );

          const expectedToJson =
              '''Object? toJson() => {r'id': id, r"it's-field": encodeAnyToJson(itsField)};''';

          expect(
            collapseWhitespace(generated),
            contains(collapseWhitespace(expectedToJson)),
          );
        },
      );
    });

    group(
      'immutable collections — typed AP with list values in fromJson',
      () {
        late ClassGenerator immutableGenerator;

        setUp(() {
          immutableGenerator = ClassGenerator(
            nameManager: nameManager,
            package: 'example',
            useImmutableCollections: true,
          );
        });

        test(
          'fromJson scratch map uses IList value type for typed AP with '
          'list values',
          () {
            final model = ClassModel(
              isDeprecated: false,
              name: 'TaggedItem',
              properties: [
                Property(
                  name: 'name',
                  model: StringModel(context: context),
                  isRequired: false,
                  isNullable: true,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              context: context,
              additionalProperties: TypedAdditionalProperties(
                valueModel: ListModel(
                  content: StringModel(context: context),
                  context: context,
                  examples: const [],
                ),
              ),
              examples: const [],
            );

            final result = immutableGenerator.generateClass(model);
            final generatedCode = format(result.accept(emitter).toString());

            const expectedFromJson = r'''
factory TaggedItem.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'TaggedItem');
  const _$knownKeys = {r'name'};
  final _$additional = <String, IList<String>>{};
  for (final _$entry in _$map.entries) {
    if (!_$knownKeys.contains(_$entry.key)) {
      _$additional[_$entry.key] = IList(
        _$entry.value.decodeJsonList<String>(
          context: r'TaggedItem.additionalProperties',
        ),
      );
    }
  }
  return TaggedItem(
    name: _$map[r'name'].decodeJsonNullableString(
      context: r'TaggedItem.name',
    ),
    additionalProperties: IMap(_$additional),
  );
}
            ''';

            expect(
              collapseWhitespace(generatedCode),
              contains(collapseWhitespace(expectedFromJson)),
            );
          },
        );
      },
    );

    group('recursion helper dedup across multiple properties', () {
      ClassModel buildTwoTrees() {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: context),
          context: context,
          examples: const [],
        );
        tree.valueModel = tree;
        return ClassModel(
          isDeprecated: false,
          name: 'TwoTrees',
          properties: [
            Property(
              name: 'left',
              model: tree,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'right',
              model: tree,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );
      }

      test(
        r'two Tree-typed properties splice exactly one _$decodeTree helper '
        'into fromJson',
        () {
          final result = generator.generateClass(buildTwoTrees());
          final fromJsonCtor = result.constructors.firstWhere(
            (c) => c.name == 'fromJson',
          );
          final actual = format(
            Class(
              (b) => b
                ..name = 'TwoTrees'
                ..constructors.add(fromJsonCtor),
            ).accept(emitter).toString(),
          );

          const expected = r'''
            class TwoTrees {
              factory TwoTrees.fromJson(Object? json) {
                late final Tree Function(Object?) _$decodeTree;
                _$decodeTree = (Object? v) => v.decodeJsonMap(
                  (v) => _$decodeTree(v),
                  context: r"Tree (at 'TwoTrees.left')",
                );
                final _$map = json.decodeMap(context: r'TwoTrees');
                return TwoTrees(
                  left: _$decodeTree(_$map[r'left']),
                  right: _$decodeTree(_$map[r'right']),
                );
              }
            }
          ''';

          expect(
            collapseWhitespace(actual),
            collapseWhitespace(format(expected)),
          );
        },
      );

      test(
        r'two Tree-typed properties splice exactly one _$encodeTree helper '
        'into toJson',
        () {
          final result = generator.generateClass(buildTwoTrees());
          final toJson = result.methods.firstWhere((m) => m.name == 'toJson');
          final actual = format(toJson.accept(emitter).toString());

          const expected = r'''
            @override
            Object? toJson() {
              late final Object? Function(Object?) _$encodeTree;
              _$encodeTree = (Object? raw) {
                if (raw is! Tree) {
                  throw EncodingException(
                    'Cannot encode value as Tree (at \'TwoTrees.left\'); got: '
                    '${raw.runtimeType}',
                  );
                }
                final v = raw;
                return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
              };
              return {r'left': _$encodeTree(left), r'right': _$encodeTree(right)};
            }
          ''';

          expect(
            collapseWhitespace(actual),
            collapseWhitespace(format(expected)),
          );
        },
      );
    });
  });
}
