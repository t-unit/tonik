import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ClassGenerator defaults', () {
    late ClassGenerator generator;
    late NameManager nameManager;
    late Context context;
    late DartEmitter emitter;
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      nameManager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    String renderAssignment(Code? assignment) =>
        assignment == null ? '' : assignment.accept(emitter).toString();

    test('emits static const + defaultTo for optional string property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 'anon',
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      final constField =
          result.fields.firstWhere((f) => f.name == 'nameDefault');
      expect(constField.static, isTrue);
      expect(constField.modifier, FieldModifier.constant);
      expect(constField.type?.symbol, 'String');
      expect(constField.type?.accept(emitter).toString(), 'String');
      expect(renderAssignment(constField.assignment), "r'anon'");

      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.type?.accept(emitter).toString(), 'String?');

      final constructor =
          result.constructors.firstWhere((c) => c.name == null);
      final nameParam =
          constructor.optionalParameters.firstWhere((p) => p.name == 'name');
      expect(nameParam.required, isFalse);
      expect(nameParam.defaultTo?.accept(emitter).toString(), 'nameDefault');
    });

    test(
      'required property with default emits non-required param and '
      'non-nullable field',
      () {
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
              defaultValue: 'anon',
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        final constField =
            result.fields.firstWhere((f) => f.name == 'nameDefault');
        expect(constField.type?.accept(emitter).toString(), 'String');
        expect(renderAssignment(constField.assignment), "r'anon'");

        final nameField = result.fields.firstWhere((f) => f.name == 'name');
        expect(nameField.type?.accept(emitter).toString(), 'String');

        final constructor =
            result.constructors.firstWhere((c) => c.name == null);
        final nameParam =
            constructor.optionalParameters.firstWhere((p) => p.name == 'name');
        expect(nameParam.required, isFalse);
        expect(nameParam.defaultTo?.accept(emitter).toString(), 'nameDefault');
      },
    );

    test('integer default emits static const int', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Counter',
        properties: [
          Property(
            name: 'count',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 0,
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      final constField =
          result.fields.firstWhere((f) => f.name == 'countDefault');
      expect(constField.static, isTrue);
      expect(constField.modifier, FieldModifier.constant);
      expect(constField.type?.symbol, 'int');
      expect(constField.type?.accept(emitter).toString(), 'int');
      expect(renderAssignment(constField.assignment), '0');
    });

    test('double default emits static const double', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Rate',
        properties: [
          Property(
            name: 'rate',
            model: DoubleModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 1.5,
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      final constField =
          result.fields.firstWhere((f) => f.name == 'rateDefault');
      expect(constField.static, isTrue);
      expect(constField.modifier, FieldModifier.constant);
      expect(constField.type?.symbol, 'double');
      expect(constField.type?.accept(emitter).toString(), 'double');
      expect(renderAssignment(constField.assignment), '1.5');
    });

    test('number default emits static const num', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Score',
        properties: [
          Property(
            name: 'score',
            model: NumberModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 3,
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      final constField =
          result.fields.firstWhere((f) => f.name == 'scoreDefault');
      expect(constField.static, isTrue);
      expect(constField.modifier, FieldModifier.constant);
      expect(constField.type?.symbol, 'num');
      expect(constField.type?.accept(emitter).toString(), 'num');
      expect(renderAssignment(constField.assignment), '3');
    });

    test('boolean default emits static const bool', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Toggle',
        properties: [
          Property(
            name: 'active',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: true,
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      final constField =
          result.fields.firstWhere((f) => f.name == 'activeDefault');
      expect(constField.static, isTrue);
      expect(constField.modifier, FieldModifier.constant);
      expect(constField.type?.symbol, 'bool');
      expect(constField.type?.accept(emitter).toString(), 'bool');
      expect(renderAssignment(constField.assignment), 'true');
    });

    test('type mismatch drops default, logs one warning, no static const', () {
      final logs = <LogRecord>[];
      final subscription =
          Logger('ClassGenerator').onRecord.listen(logs.add);
      addTearDown(subscription.cancel);

      final model = ClassModel(
        isDeprecated: false,
        name: 'Mismatched',
        properties: [
          Property(
            name: 'tier',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 'no',
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      expect(
        result.fields.where((f) => f.name == 'tierDefault'),
        isEmpty,
      );

      final constructor = result.constructors.firstWhere((c) => c.name == null);
      final tierParam =
          constructor.optionalParameters.firstWhere((p) => p.name == 'tier');
      expect(tierParam.required, isTrue);
      expect(tierParam.defaultTo, isNull);

      final warnings =
          logs.where((r) => r.level == Level.WARNING).toList();
      expect(warnings, hasLength(1));
      expect(
        warnings.single.message,
        'Dropping default for Mismatched.tier '
        '(property, expected IntegerModel, value: "no"): '
        'value does not match the expected type.',
      );
    });

    test('alias-carried mismatched default still drops + logs once', () {
      final logs = <LogRecord>[];
      final subscription =
          Logger('ClassGenerator').onRecord.listen(logs.add);
      addTearDown(subscription.cancel);

      final model = ClassModel(
        isDeprecated: false,
        name: 'WithAliasedBadDefault',
        properties: [
          Property(
            name: 'count',
            model: AliasModel(
              name: 'CountAlias',
              model: IntegerModel(context: context),
              context: context,
              examples: const [],
              defaultValue: 'bad',
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

      generator.generateClass(model);

      final warnings = logs.where((r) => r.level == Level.WARNING).toList();
      expect(warnings, hasLength(1));
      expect(
        warnings.single.message,
        'Dropping default for WithAliasedBadDefault.count '
        '(property, expected IntegerModel, value: "bad"): '
        'value does not match the expected type.',
      );
    });

    test('composite target with default emits NO warning and NO const', () {
      final logs = <LogRecord>[];
      final subscription =
          Logger('ClassGenerator').onRecord.listen(logs.add);
      addTearDown(subscription.cancel);

      final model = ClassModel(
        isDeprecated: false,
        name: 'WithChild',
        properties: [
          Property(
            name: 'child',
            model: ClassModel(
              isDeprecated: false,
              name: 'Child',
              properties: const [],
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: const <String, Object?>{},
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      expect(
        result.fields.where((f) => f.name == 'childDefault'),
        isEmpty,
      );
      expect(logs.where((r) => r.level == Level.WARNING), isEmpty);
    });

    test(
      'nullable + default: null produces no static const',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Nickname',
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
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        expect(
          result.fields.where((f) => f.name == 'nicknameDefault'),
          isEmpty,
          reason: 'raw default is null and Property.defaultValue is null — '
              'absent and explicit-null defaults collapse to the no-default '
              'path',
        );

        final constructor =
            result.constructors.firstWhere((c) => c.name == null);
        final nicknameParam = constructor.optionalParameters
            .firstWhere((p) => p.name == 'nickname');
        expect(nicknameParam.defaultTo, isNull);
      },
    );

    test(
      'nullable string property with non-null default (via alias) materialises'
      ' as static const String?',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'WithAliasedNullDefault',
          properties: [
            Property(
              name: 'nickname',
              model: AliasModel(
                name: 'NullableNickname',
                model: StringModel(context: context),
                context: context,
                examples: const [],
                defaultValue: 'placeholder',
                isNullable: true,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: 'placeholder',
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final constField =
            result.fields.firstWhere((f) => f.name == 'nicknameDefault');
        expect(constField.static, isTrue);
        expect(constField.modifier, FieldModifier.constant);
        expect(constField.type?.symbol, 'NullableNickname');
        expect(
          constField.type?.accept(emitter).toString(),
          'NullableNickname?',
        );
        expect(renderAssignment(constField.assignment), "r'placeholder'");
      },
    );

    test(
      'required + nullable + literal default: const stays nullable, '
      'param is non-required, present-null still decodes to null',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Greeting',
          properties: [
            Property(
              name: 'salutation',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: 'hi',
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        final constField =
            result.fields.firstWhere((f) => f.name == 'salutationDefault');
        expect(constField.static, isTrue);
        expect(constField.modifier, FieldModifier.constant);
        expect(constField.type?.symbol, 'String');
        expect(constField.type?.accept(emitter).toString(), 'String?');
        expect(renderAssignment(constField.assignment), "r'hi'");

        final constructor =
            result.constructors.firstWhere((c) => c.name == null);
        final salutationParam = constructor.optionalParameters
            .firstWhere((p) => p.name == 'salutation');
        expect(salutationParam.required, isFalse);
        expect(
          salutationParam.defaultTo?.accept(emitter).toString(),
          'salutationDefault',
        );

        final generated = format(result.accept(emitter).toString());
        const expectedFromJson = r'''
factory Greeting.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'Greeting');
  return Greeting(
    salutation: _$map.containsKey(r'salutation')
        ? _$map[r'salutation'].decodeJsonNullableString(
          context: r'Greeting.salutation',
        )
        : salutationDefault,
  );
}
''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedFromJson)),
        );
      },
    );

    test(
      'fromJson body uses containsKey template for defaulted property',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'DefaultedPrimitives',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: 'anon',
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final generated = format(result.accept(emitter).toString());

        const expectedFromJson = r'''
factory DefaultedPrimitives.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'DefaultedPrimitives');
  return DefaultedPrimitives(
    name: _$map.containsKey(r'name')
        ? _$map[r'name'].decodeJsonString(
          context: r'DefaultedPrimitives.name',
        )
        : nameDefault,
  );
}
''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedFromJson)),
        );
      },
    );

    test('fromJson nullable defaulted property decodes in nullable mode', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'WithNullable',
        properties: [
          Property(
            name: 'nickname',
            model: AliasModel(
              name: 'NullableNickname',
              model: StringModel(context: context),
              context: context,
              examples: const [],
              defaultValue: 'fallback',
              isNullable: true,
            ),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: 'fallback',
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      final generated = format(result.accept(emitter).toString());

      const expectedFromJson = r'''
factory WithNullable.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'WithNullable');
  return WithNullable(
    nickname: _$map.containsKey(r'nickname')
        ? _$map[r'nickname'].decodeJsonNullableString(
            context: r'WithNullable.nickname',
          )
        : nicknameDefault,
  );
}
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedFromJson)),
      );
    });

    test(
      'collision: property valueDefault forces suffix on value default',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Collide',
          properties: [
            Property(
              name: 'value',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: 'x',
            ),
            Property(
              name: 'valueDefault',
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

        final constField =
            result.fields.firstWhere((f) => f.name == 'valueDefault2');
        expect(constField.static, isTrue);
        expect(constField.modifier, FieldModifier.constant);
        expect(constField.type?.symbol, 'String');
        expect(constField.type?.accept(emitter).toString(), 'String');
        expect(renderAssignment(constField.assignment), "r'x'");

        final constructor =
            result.constructors.firstWhere((c) => c.name == null);
        final valueParam =
            constructor.optionalParameters.firstWhere((p) => p.name == 'value');
        expect(
          valueParam.defaultTo?.accept(emitter).toString(),
          'valueDefault2',
        );

        expect(
          result.fields.where((f) => f.name == 'valueDefault'),
          isNotEmpty,
          reason: 'the original property field named valueDefault still '
              'exists; the renamed const must not shadow it',
        );
      },
    );

    test('fromSimple uses containsKey template for defaulted property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'DefaultedSimple',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 'anon',
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      final generated = format(result.accept(emitter).toString());

      const expectedFromSimple = r'''
factory DefaultedSimple.fromSimple(String? value, {required bool explode}) {
  final _$values = value.decodeObject(
    explode: explode,
    explodeSeparator: ',',
    expectedKeys: {r'name'},
    listKeys: {},
    context: r'DefaultedSimple',
  );
  return DefaultedSimple(
    name: _$values.containsKey(r'name')
        ? _$values[r'name'].decodeSimpleString(
          context: r'DefaultedSimple.name',
        )
        : nameDefault,
  );
}
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedFromSimple)),
      );
    });

    test('fromForm uses containsKey template for defaulted property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'DefaultedForm',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 'anon',
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      final generated = format(result.accept(emitter).toString());

      const expectedFromForm = r'''
factory DefaultedForm.fromForm(String? value, {required bool explode}) {
  final _$values = value.decodeObject(
    explode: explode,
    explodeSeparator: '&',
    expectedKeys: {r'name'},
    listKeys: {},
    context: r'DefaultedForm',
  );
  return DefaultedForm(
    name: _$values.containsKey(r'name')
        ? _$values[r'name'].decodeFormString(context: r'DefaultedForm.name')
        : nameDefault,
  );
}
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedFromForm)),
      );
    });

    test(
      'alias-carried default propagates when property has no local default',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'RegionHolder',
          properties: [
            Property(
              name: 'region',
              model: AliasModel(
                name: 'Region',
                model: StringModel(context: context),
                context: context,
                examples: const [],
                defaultValue: 'us',
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

        final constField =
            result.fields.firstWhere((f) => f.name == 'regionDefault');
        expect(constField.static, isTrue);
        expect(constField.modifier, FieldModifier.constant);
        expect(constField.type?.symbol, 'Region');
        expect(constField.type?.accept(emitter).toString(), 'Region');
        expect(renderAssignment(constField.assignment), "r'us'");
      },
    );

    test(
      'property-local default overrides alias-carried default',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'OverridingHolder',
          properties: [
            Property(
              name: 'region',
              model: AliasModel(
                name: 'Region',
                model: StringModel(context: context),
                context: context,
                examples: const [],
                defaultValue: 'us',
              ),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: 'eu',
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);

        final constField =
            result.fields.firstWhere((f) => f.name == 'regionDefault');
        expect(constField.type?.accept(emitter).toString(), 'Region');
        expect(renderAssignment(constField.assignment), "r'eu'");
      },
    );

    test('AliasModel chain to primitive still materialises default', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'WithAlias',
        properties: [
          Property(
            name: 'tag',
            model: AliasModel(
              name: 'Tag',
              model: StringModel(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: 'hi',
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);

      final constField =
          result.fields.firstWhere((f) => f.name == 'tagDefault');
      expect(constField.static, isTrue);
      expect(constField.modifier, FieldModifier.constant);
      expect(constField.type?.symbol, 'Tag');
      expect(constField.type?.accept(emitter).toString(), 'Tag');
      expect(renderAssignment(constField.assignment), "r'hi'");
    });
  });
}
