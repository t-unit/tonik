import 'package:code_builder/code_builder.dart';
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
        name: 'User',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);
      expect(result.name, 'User');
    });

    test('generates class with immutable annotation', () {
      final model = ClassModel(
        name: 'User',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);

      expect(result.annotations.length, 1);

      final annotation = result.annotations.first;
      expect(annotation.accept(emitter).toString(), 'immutable');
    });

    test('generates currentEncodingShape getter for class with properties', () {
      final model = ClassModel(
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
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.complex',
      );
    });

    test('generates currentEncodingShape getter for empty class', () {
      final model = ClassModel(
        name: 'Empty',
        properties: const [],
        context: context,
      );


      final result = generator.generateClass(model);
      final getter = result.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.complex',
      );
    });

    test('generates currentEncodingShape getter for complex class', () {
      final nestedClass = ClassModel(
        name: 'Address',
        properties: const [],
        context: context,
      );

      final model = ClassModel(
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
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.complex',
      );
    });

    test('generates constructor with required and optional parameters', () {
      final model = ClassModel(
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
        final requiredParams =
            constructor.optionalParameters
                .where((p) => p.required)
                .map((p) => p.name)
                .toList();
        final optionalParams =
            constructor.optionalParameters
                .where((p) => !p.required)
                .map((p) => p.name)
                .toList();

        // Verify all required parameters come before optional ones
        final allParams =
            constructor.optionalParameters.map((p) => p.name).toList();
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
          name: 'User',
          properties: [
            Property(
              name: 'address',
              model: ClassModel(
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

    test(
      'generates constructor with required fields before non-required fields',
      () {
        final model = ClassModel(
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

        expect(constructor.optionalParameters, hasLength(2));

        final idParam = constructor.optionalParameters[0];
        expect(idParam.name, 'id');
        expect(idParam.required, isTrue);

        final nameParam = constructor.optionalParameters[1];
        expect(nameParam.name, 'name');
        expect(nameParam.required, isFalse);
      },
    );

    test('generates field with Uri type for UriModel property', () {
      final model = ClassModel(
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

    group('simpleProperties method', () {
      test('generates simpleProperties method with primitive properties', () {
        final model = ClassModel(
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

        const expectedSimplePropertiesMethod = '''
          Map<String,String> simpleProperties({bool allowEmpty = true}) {
            return Map<String,String> 
              .from({
                r'id': id.toSimple(explode: false, allowEmpty: allowEmpty),
                if (name != null) r'name': name!.toSimple(explode: false, allowEmpty: allowEmpty),
              });
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedSimplePropertiesMethod)),
        );
      });

      test('throws exception for model with complex nested class', () {
        final nestedModel = ClassModel(
          name: 'Address',
          properties: [
            Property(
              name: 'street',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final model = ClassModel(
          name: 'User',
          properties: [
            Property(
              name: 'address',
              model: nestedModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedSimplePropertiesMethod = '''
          Map<String,String> simpleProperties({bool allowEmpty = true}) {
            throw EncodingException('simpleProperties not supported for User: contains nested data');
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedSimplePropertiesMethod)),
        );
      });

      test('throws exception for model with list properties', () {
        final model = ClassModel(
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

        const expectedSimplePropertiesMethod = '''
          Map<String,String> simpleProperties({bool allowEmpty = true}) {
            throw EncodingException('simpleProperties not supported for User: contains nested data');
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedSimplePropertiesMethod)),
        );
      });

      test('handles empty model correctly', () {
        final model = ClassModel(
          name: 'Empty',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedSimplePropertiesMethod = '''
          Map<String,String> simpleProperties({bool allowEmpty = true}) => <String, String>{};
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedSimplePropertiesMethod)),
        );
      });

      test('generates simpleProperties with complex simple types', () {
        final model = ClassModel(
          name: 'Product',
          properties: [
            Property(
              name: 'status',
              model: EnumModel<String>(
                values: const {'active', 'inactive'},
                isNullable: false,
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'created_at',
              model: DateTimeModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'price',
              model: DoubleModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'precise_value',
              model: DecimalModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'release_date',
              model: DateModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedSimplePropertiesMethod = '''
          Map<String,String> simpleProperties({bool allowEmpty = true}) {
            return Map<String,String> .from({
              r'status': status.toSimple(explode: false, allowEmpty: allowEmpty),
              r'created_at': createdAt.toSimple(explode: false, allowEmpty: allowEmpty),
              if (price != null) r'price': price!.toSimple(explode: false, allowEmpty: allowEmpty),
              r'precise_value': preciseValue.toSimple(explode: false, allowEmpty: allowEmpty),
              if (releaseDate != null) r'release_date': releaseDate!.toSimple(explode: false, allowEmpty: allowEmpty),
            });
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedSimplePropertiesMethod)),
        );
      });

      test('handles required nullable properties with allowEmpty=true', () {
        final model = ClassModel(
          name: 'RequiredNullableModel',
          properties: [
            Property(
              name: 'nullable_name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'nullable_count',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedSimplePropertiesMethod = '''
          Map<String,String> simpleProperties({bool allowEmpty = true}) {
            return Map<String,String> 
              .from({
                if (allowEmpty || nullableName != null) r'nullable_name': nullableName?.toSimple(explode: false, allowEmpty: allowEmpty) ?? '',
                if (allowEmpty || nullableCount != null) r'nullable_count': nullableCount?.toSimple(explode: false, allowEmpty: allowEmpty) ?? '',
              });
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedSimplePropertiesMethod)),
        );
      });
    });

    group('form encoding', () {
      test('generates fromForm constructor for simple properties', () {
        final model = ClassModel(
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
        'generates fromForm constructor that throws for complex properties',
        () {
          final model = ClassModel(
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

          const expectedFromFormBody = '''
          throw SimpleDecodingException('Form encoding not supported for ComplexModel: contains complex types');
        ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedFromFormBody)),
          );
        },
      );

      test('generates fromForm constructor for empty model', () {
        final model = ClassModel(
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
        expect(toFormMethod.optionalParameters.length, 2);
        expect(toFormMethod.optionalParameters.first.name, 'explode');
        expect(toFormMethod.optionalParameters.first.required, isTrue);
        expect(toFormMethod.optionalParameters.first.named, isTrue);
        expect(toFormMethod.optionalParameters.last.name, 'allowEmpty');
        expect(toFormMethod.optionalParameters.last.required, isTrue);
        expect(toFormMethod.optionalParameters.last.named, isTrue);
      });

      test('generates toForm method that throws for complex properties', () {
        final model = ClassModel(
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
          String toForm({required bool explode, required bool allowEmpty, }) {
            throw EncodingException('toForm not supported for ComplexModel: contains nested data');
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedToFormBody)),
        );
      });

      test('generates toForm method for empty model', () {
        final model = ClassModel(
          name: 'EmptyModel',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToFormMethod = '''
          String toForm({required bool explode, required bool allowEmpty, }) => '';
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      });

      test('generates formProperties method for simple properties', () {
        final model = ClassModel(
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

        const expectedFormPropertiesMethod = '''
          Map<String,String> formProperties({bool allowEmpty = true}) {
            return Map<String,String>
              .from({
                r'name': name.toForm(explode: false, allowEmpty: allowEmpty),
                if (count != null) r'count': count!.toForm(explode: false, allowEmpty: allowEmpty),
            });
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedFormPropertiesMethod)),
        );
      });

      test(
        'generates formProperties method that throws for complex properties',
        () {
          final model = ClassModel(
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

          const expectedFormPropertiesMethod = '''
          Map<String,String> formProperties({bool allowEmpty = true}) {
            throw EncodingException('formProperties not supported for ComplexModel: contains nested data');
          }
        ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedFormPropertiesMethod)),
          );
        },
      );

      test('handles required nullable properties in formProperties', () {
        final model = ClassModel(
          name: 'RequiredNullableModel',
          properties: [
            Property(
              name: 'nullable_name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'nullable_count',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedFormPropertiesMethod = '''
          Map<String,String> formProperties({bool allowEmpty = true}) {
            return Map<String,String> .from({
              if (allowEmpty || nullableName != null) r'nullable_name': nullableName?.toForm(explode: false, allowEmpty: allowEmpty) ?? '',
              if (allowEmpty || nullableCount != null) r'nullable_count': nullableCount?.toForm(explode: false, allowEmpty: allowEmpty) ?? '',
            });
          }
        ''';

        expect(
          collapseWhitespace(result.accept(emitter).toString()),
          contains(collapseWhitespace(expectedFormPropertiesMethod)),
        );
      });

      test(
        'generates complete fromForm constructor for supported model with '
        'properties',
        () {
          final model = ClassModel(
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

          // Test constructor exists using object introspection
          final fromFormConstructor = result.constructors.firstWhere(
            (c) => c.name == 'fromForm',
          );
          expect(fromFormConstructor.factory, isTrue);
          expect(fromFormConstructor.requiredParameters.length, 1);
          expect(fromFormConstructor.optionalParameters.length, 1);

          // Test parameter types
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
            return UserForm(name: values['name'].decodeFormString(context: r'UserForm.name'), age: values['age'].decodeFormInt(context: r'UserForm.age'), email: values['email'].decodeFormNullableString(context: r'UserForm.email'), );
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedReturnStatement)),
          );
        },
      );

      test(
        'generates complete toForm method for supported model with properties',
        () {
          final model = ClassModel(
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
          String toForm({required bool explode, required bool allowEmpty, }) {
            return formProperties(allowEmpty: allowEmpty).toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          }
        ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedToFormMethod)),
          );
        },
      );

      test(
        'generates complete formProperties method for supported model with '
        'mixed property types',
        () {
          final model = ClassModel(
            name: 'ProductForm',
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
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'price',
                model: DoubleModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
              ),
              Property(
                name: 'active',
                model: BooleanModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
              Property(
                name: 'created_at',
                model: DateTimeModel(context: context),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
              ),
            ],
            context: context,
          );

          final result = generator.generateClass(model);

          const expectedFormPropertiesMethod = '''
          Map<String,String> formProperties({bool allowEmpty = true}) {
            return Map<String,String>
              .from({
                r'id': id.toForm(explode: false, allowEmpty: allowEmpty),
                r'name': name.toForm(explode: false, allowEmpty: allowEmpty),
                if (price != null) r'price': price!.toForm(explode: false, allowEmpty: allowEmpty),
                r'active': active.toForm(explode: false, allowEmpty: allowEmpty),
                if (createdAt != null) r'created_at': createdAt!.toForm(explode: false, allowEmpty: allowEmpty),
            });
          }
        ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedFormPropertiesMethod)),
          );
        },
      );

      test('generates fromForm constructor with all primitive types', () {
        final model = ClassModel(
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
          return AllTypesForm(text: values['text'].decodeFormString(context: r'AllTypesForm.text'), number: values['number'].decodeFormInt(context: r'AllTypesForm.number'), decimal: values['decimal'].decodeFormDouble(context: r'AllTypesForm.decimal'), flag: values['flag'].decodeFormBool(context: r'AllTypesForm.flag'), timestamp: values['timestamp'].decodeFormDateTime(context: r'AllTypesForm.timestamp'), dateOnly: values['date_only'].decodeFormDate(context: r'AllTypesForm.date_only'), preciseAmount: values['precise_amount'].decodeFormBigDecimal(context: r'AllTypesForm.precise_amount'), website: values['website'].decodeFormUri(context: r'AllTypesForm.website'), );
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
            return NullableForm(requiredNullableName: values['required_nullable_name'].decodeFormNullableString(context: r'NullableForm.required_nullable_name'), requiredNullableCount: values['required_nullable_count'].decodeFormNullableInt(context: r'NullableForm.required_nullable_count'), );
          ''';

          expect(
            collapseWhitespace(result.accept(emitter).toString()),
            contains(collapseWhitespace(expectedReturnStatement)),
          );
        },
      );
    });
  });
}
