import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AnyOfGenerator generator;
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
    generator = AnyOfGenerator(
      nameManager: nameManager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('Method signatures', () {
    test('fromForm constructor has correct signature', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Test',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final fromFormConstructor = klass.constructors.firstWhere(
        (c) => c.name == 'fromForm',
      );

      expect(fromFormConstructor.factory, isTrue);
      expect(fromFormConstructor.requiredParameters.length, 1);
      expect(fromFormConstructor.requiredParameters[0].name, 'value');
      expect(
        fromFormConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromFormConstructor.optionalParameters.length, 1);
      expect(fromFormConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromFormConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromFormConstructor.optionalParameters[0].required, isTrue);
    });

    test('toForm method has correct signature', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Test',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final toFormMethod = klass.methods.firstWhere((m) => m.name == 'toForm');

      expect(
        toFormMethod.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(toFormMethod.requiredParameters.single.name, 'paramName');
      expect(toFormMethod.optionalParameters, hasLength(6));
      expect(
        toFormMethod.optionalParameters.map((p) => p.name),
        containsAll([
          'explode',
          'allowEmpty',
          'useQueryComponent',
          'allowReserved',
          'fieldEncodings',
          'textEncoding',
        ]),
      );
      expect(
        toFormMethod.optionalParameters.take(2).every((p) => p.required),
        isTrue,
      );
      expect(toFormMethod.optionalParameters.last.required, isFalse);
    });

    test('currentEncodingShape getter has correct signature', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Test',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final getter = klass.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(getter.returns?.accept(emitter).toString(), 'EncodingShape');
    });
  });

  group('currentEncodingShape getter generation', () {
    test('primitive-only anyOf returns dynamic shape', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Flexible',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = r'''
        EncodingShape get currentEncodingShape {
          final _$shapes = <EncodingShape>{};
          if (this.int != null) {
            _$shapes.add(EncodingShape.simple);
          }
          if (this.string != null) {
            _$shapes.add(EncodingShape.simple);
          }
          if (_$shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (_$shapes.length > 1) return EncodingShape.mixed;
          return _$shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('complex-only anyOf returns dynamic shape', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'A',
        properties: const [],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final classB = ClassModel(
        isDeprecated: false,
        name: 'B',
        properties: const [],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: [
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = r'''
        EncodingShape get currentEncodingShape {
          final _$shapes = <EncodingShape>{};
          if (this.a != null) {
            _$shapes.add(this.a!.currentEncodingShape);
          }
          if (this.b != null) {
            _$shapes.add(this.b!.currentEncodingShape);
          }
          if (_$shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (_$shapes.length > 1) return EncodingShape.mixed;
          return _$shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('mixed primitive and complex anyOf returns dynamic shape', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'Data',
        properties: [
          Property(
            name: 'value',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Flexible',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = r'''
        EncodingShape get currentEncodingShape {
          final _$shapes = <EncodingShape>{};
          if (this.data != null) {
            _$shapes.add(this.data!.currentEncodingShape);
          }
          if (this.string != null) {
            _$shapes.add(EncodingShape.simple);
          }
          if (_$shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (_$shapes.length > 1) return EncodingShape.mixed;
          return _$shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });
  });

  group('fromForm constructor generation', () {
    test('primitive-only anyOf tries all variants independently', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Flexible',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        factory Flexible.fromForm(String? value, {required bool explode}) {
          int? _$decodedint;
          try {
            _$decodedint = value.decodeFormInt(context: r'Flexible');
          } on Object catch (_) {
            _$decodedint = null;
          }

          String? _$decodedstring;
          try {
            _$decodedstring = value.decodeFormString(context: r'Flexible');
          } on Object catch (_) {
            _$decodedstring = null;
          }

          if (_$decodedint == null && _$decodedstring == null) {
            throw FormDecodingException(
              r'Invalid form value for Flexible: all variants failed to decode',
            );
          }
          return Flexible(int: _$decodedint, string: _$decodedstring);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('complex-only anyOf tries all variants', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'A',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final classB = ClassModel(
        isDeprecated: false,
        name: 'B',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: [
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        factory Choice.fromForm(String? value, {required bool explode}) {
          A? _$decodeda;
          try {
            _$decodeda = A.fromForm(value, explode: explode);
          } on Object catch (_) {
            _$decodeda = null;
          }

          B? _$decodedb;
          try {
            _$decodedb = B.fromForm(value, explode: explode);
          } on Object catch (_) {
            _$decodedb = null;
          }

          if (_$decodeda == null && _$decodedb == null) {
            throw FormDecodingException(
              r'Invalid form value for Choice: all variants failed to decode',
            );
          }
          return Choice(a: _$decodeda, b: _$decodedb);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('mixed primitive and complex tries all', () {
      final classA = ClassModel(
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'SearchKey',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        factory SearchKey.fromForm(String? value, {required bool explode}) {
          User? _$decodeduser;
          try {
            _$decodeduser = User.fromForm(value, explode: explode);
          } on Object catch (_) {
            _$decodeduser = null;
          }

          String? _$decodedstring;
          try {
            _$decodedstring = value.decodeFormString(context: r'SearchKey');
          } on Object catch (_) {
            _$decodedstring = null;
          }

          if (_$decodeduser == null && _$decodedstring == null) {
            throw FormDecodingException(
              r'Invalid form value for SearchKey: all variants failed to decode',
            );
          }
          return SearchKey(user: _$decodeduser, string: _$decodedstring);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'anyOf with complex lists and simple type tries decodable variants',
      () {
        final classA = ClassModel(
          isDeprecated: false,
          name: 'ClassA',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final classB = ClassModel(
          isDeprecated: false,
          name: 'ClassB',
          properties: [
            Property(
              name: 'value',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          additionalPropertiesPolicy: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final listA = ListModel(
          content: classA,
          context: context,
          examples: const [],
          name: null,
          nameOverride: null,
          isNullable: false,
          isContentNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final listB = ListModel(
          content: classB,
          context: context,
          examples: const [],
          name: null,
          nameOverride: null,
          isNullable: false,
          isContentNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'MixedAnyOf',
          models: [
            (discriminatorValue: null, model: listA),
            (discriminatorValue: null, model: listB),
            (discriminatorValue: null, model: StringModel(context: context)),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expectedMethod = r'''
      factory MixedAnyOf.fromForm(String? value, {required bool explode}) {
        String? _$decodedstring;
        try {
          _$decodedstring = value.decodeFormString(context: r'MixedAnyOf');
        } on Object catch (_) {
          _$decodedstring = null;
        }

        if (_$decodedstring == null) {
          throw FormDecodingException(
            r'Invalid form value for MixedAnyOf: all variants failed to decode',
          );
        }
        return MixedAnyOf(list: null, list2: null, string: _$decodedstring);
      }
    ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('toForm method generation', () {
    test('primitive-only anyOf encodes each field to form', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Simple',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        List<ParameterEntry> toForm(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
          required Encoding textEncoding,
          bool useQueryComponent = false,
          bool allowReserved = false,
          Map<String, FormFieldEncoding> fieldEncodings = const {},
        }) {
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          if (this.int != null) {
            final _$intForm = this.int!.toForm(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved,
              textEncoding: textEncoding,
            );
            _$entryLists.add(_$intForm);
            _$values.add(_$intForm.map((e) => e.value).join(','));
          }
          if (this.string != null) {
            final _$stringForm = this.string!.toForm(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved,
              textEncoding: textEncoding,
            );
            _$entryLists.add(_$stringForm);
            _$values.add(_$stringForm.map((e) => e.value).join(','));
          }
          if (_$values.isEmpty) {
            return const <ParameterEntry>[];
          }
          return _$entryLists.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('complex-only anyOf merges parameterProperties', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'A',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Wrapper',
        models: [(discriminatorValue: null, model: classA)],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        List<ParameterEntry> toForm(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
          required Encoding textEncoding,
          bool useQueryComponent = false,
          bool allowReserved = false,
          Map<String, FormFieldEncoding> fieldEncodings = const {},
        }) {
          final _$mapValues = <Map<String, PropertyValue>>[];
          if (this.a != null) {
            final _$aForm = this.a!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$aForm);
          }
          final _$map = <String, PropertyValue>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          return _$map.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
            fieldEncodings: fieldEncodings,
            textEncoding: textEncoding,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('multiple complex fields merge with discriminator', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'A',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final classB = ClassModel(
        isDeprecated: false,
        name: 'B',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: [
          (discriminatorValue: 'a', model: classA),
          (discriminatorValue: 'b', model: classB),
        ],
        discriminator: 'type',
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        List<ParameterEntry> toForm(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
          required Encoding textEncoding,
          bool useQueryComponent = false,
          bool allowReserved = false,
          Map<String, FormFieldEncoding> fieldEncodings = const {},
        }) {
          final _$mapValues = <Map<String, PropertyValue>>[];
          String? _$discriminatorValue;
          if (this.a != null) {
            final _$aForm = this.a!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$aForm);
            _$discriminatorValue ??= r'a';
          }
          if (this.b != null) {
            final _$bForm = this.b!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$bForm);
            _$discriminatorValue ??= r'b';
          }
          final _$map = <String, PropertyValue>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent(r'type', () => PropertyValue.scalar(_$discValue));
          }
          return _$map.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
            fieldEncodings: fieldEncodings,
            textEncoding: textEncoding,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('mixed primitive and complex checks for ambiguity', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'Data',
        properties: [
          Property(
            name: 'value',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Mixed',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        List<ParameterEntry> toForm(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
          required Encoding textEncoding,
          bool useQueryComponent = false,
          bool allowReserved = false,
          Map<String, FormFieldEncoding> fieldEncodings = const {},
        }) {
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$mapValues = <Map<String, PropertyValue>>[];
          if (this.data != null) {
            final _$dataForm = this.data!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$dataForm);
          }
          if (this.string != null) {
            final _$stringForm = this.string!.toForm(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved,
              textEncoding: textEncoding,
            );
            _$entryLists.add(_$stringForm);
            _$values.add(_$stringForm.map((e) => e.value).join(','));
          }
          if (_$values.isEmpty && _$mapValues.isEmpty) {
            return const <ParameterEntry>[];
          }
          if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf form encoding for Mixed: mixing simple and complex values',
            );
          }
          if (_$values.isNotEmpty) {
            return _$entryLists.first;
          } else {
            final _$map = <String, PropertyValue>{};
            for (final _$m in _$mapValues) {
              _$map.addAll(_$m);
            }
            return _$map.toForm(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved,
              fieldEncodings: fieldEncodings,
              textEncoding: textEncoding,
            );
          }
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });

  group('Edge cases', () {
    test('nested anyOf properly delegates to inner fromForm', () {
      final innerAnyOf = AnyOfModel(
        isDeprecated: false,
        name: 'Inner',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Outer',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerAnyOf),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        factory Outer.fromForm(String? value, {required bool explode}) {
          Inner? _$decodedinner;
          try {
            _$decodedinner = Inner.fromForm(value, explode: explode);
          } on Object catch (_) {
            _$decodedinner = null;
          }

          String? _$decodedstring;
          try {
            _$decodedstring = value.decodeFormString(context: r'Outer');
          } on Object catch (_) {
            _$decodedstring = null;
          }

          if (_$decodedinner == null && _$decodedstring == null) {
            throw FormDecodingException(
              r'Invalid form value for Outer: all variants failed to decode',
            );
          }
          return Outer(inner: _$decodedinner, string: _$decodedstring);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('Runtime shape checking', () {
    group('toForm method', () {
      test('uses runtime check for nested oneOf with dynamic shape', () {
        final innerOneOf = OneOfModel(
          isDeprecated: false,
          name: 'InnerChoice',
          models: [
            (discriminatorValue: 'str', model: StringModel(context: context)),
            (
              discriminatorValue: 'obj',
              model: ClassModel(
                isDeprecated: false,
                name: 'Inner',
                properties: [
                  Property(
                    name: 'field',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                    isReadOnly: false,
                    isWriteOnly: false,
                    nameOverride: null,
                    description: null,
                  ),
                ],
                context: context,
                examples: const [],
                nameOverride: null,
                description: null,
                additionalPropertiesPolicy: null,
                isNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
            ),
          ],
          discriminator: 'type',
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'TestAnyOf',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: innerOneOf),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = r'''
          List<ParameterEntry> toForm(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
            required Encoding textEncoding,
            bool useQueryComponent = false,
            bool allowReserved = false,
            Map<String, FormFieldEncoding> fieldEncodings = const {},
          }) {
            final _$entryLists = <List<ParameterEntry>>[];
            final _$values = <String>{};
            final _$mapValues = <Map<String, PropertyValue>>[];
            if (this.innerChoice != null) {
              switch (this.innerChoice!.currentEncodingShape) {
                case EncodingShape.simple:
                  final _$innerChoiceForm = this.innerChoice!.toForm(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    useQueryComponent: useQueryComponent,
                    allowReserved: allowReserved,
                    textEncoding: textEncoding,
                  );
                  _$entryLists.add(_$innerChoiceForm);
                  _$values.add(_$innerChoiceForm.map((e) => e.value).join(','));
                  break;
                case EncodingShape.complex:
                  final _$innerChoiceForm = this.innerChoice!.parameterProperties(
                    allowEmpty: allowEmpty,
                  );
                  _$mapValues.add(_$innerChoiceForm);
                  break;
                case EncodingShape.mixed:
                  throw EncodingException(
                    'Cannot encode field with mixed encoding shape',
                  );
              }
            }
            if (this.string != null) {
              final _$stringForm = this.string!.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                textEncoding: textEncoding,
              );
              _$entryLists.add(_$stringForm);
              _$values.add(_$stringForm.map((e) => e.value).join(','));
            }
            if (_$values.isEmpty && _$mapValues.isEmpty) {
              return const <ParameterEntry>[];
            }
            if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
              throw EncodingException(
                r'Ambiguous anyOf form encoding for TestAnyOf: mixing simple and complex values',
              );
            }
            if (_$values.isNotEmpty) {
              return _$entryLists.first;
            } else {
              final _$map = <String, PropertyValue>{};
              for (final _$m in _$mapValues) {
                _$map.addAll(_$m);
              }
              return _$map.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                fieldEncodings: fieldEncodings,
                textEncoding: textEncoding,
              );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('uses runtime check for nested anyOf', () {
        final innerAnyOf = AnyOfModel(
          isDeprecated: false,
          name: 'InnerAnyOf',
          models: [
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'Inner',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                    isReadOnly: false,
                    isWriteOnly: false,
                    nameOverride: null,
                    description: null,
                  ),
                ],
                context: context,
                examples: const [],
                nameOverride: null,
                description: null,
                additionalPropertiesPolicy: null,
                isNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
            ),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'TestAnyOf',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: innerAnyOf),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = r'''
          List<ParameterEntry> toForm(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
            required Encoding textEncoding,
            bool useQueryComponent = false,
            bool allowReserved = false,
            Map<String, FormFieldEncoding> fieldEncodings = const {},
          }) {
            final _$entryLists = <List<ParameterEntry>>[];
            final _$values = <String>{};
            final _$mapValues = <Map<String, PropertyValue>>[];
            if (this.innerAnyOf != null) {
              switch (this.innerAnyOf!.currentEncodingShape) {
                case EncodingShape.simple:
                  final _$innerAnyOfForm = this.innerAnyOf!.toForm(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    useQueryComponent: useQueryComponent,
                    allowReserved: allowReserved,
                    textEncoding: textEncoding,
                  );
                  _$entryLists.add(_$innerAnyOfForm);
                  _$values.add(_$innerAnyOfForm.map((e) => e.value).join(','));
                  break;
                case EncodingShape.complex:
                  final _$innerAnyOfForm = this.innerAnyOf!.parameterProperties(
                    allowEmpty: allowEmpty,
                  );
                  _$mapValues.add(_$innerAnyOfForm);
                  break;
                case EncodingShape.mixed:
                  throw EncodingException(
                    'Cannot encode field with mixed encoding shape',
                  );
              }
            }
            if (this.string != null) {
              final _$stringForm = this.string!.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                textEncoding: textEncoding,
              );
              _$entryLists.add(_$stringForm);
              _$values.add(_$stringForm.map((e) => e.value).join(','));
            }
            if (_$values.isEmpty && _$mapValues.isEmpty) {
              return const <ParameterEntry>[];
            }
            if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
              throw EncodingException(
                r'Ambiguous anyOf form encoding for TestAnyOf: mixing simple and complex values',
              );
            }
            if (_$values.isNotEmpty) {
              return _$entryLists.first;
            } else {
              final _$map = <String, PropertyValue>{};
              for (final _$m in _$mapValues) {
                _$map.addAll(_$m);
              }
              return _$map.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                fieldEncodings: fieldEncodings,
                textEncoding: textEncoding,
              );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('uses direct calls for static types without runtime checks', () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'TestAnyOf',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'MyClass',
                properties: [
                  Property(
                    name: 'field',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                    isReadOnly: false,
                    isWriteOnly: false,
                    nameOverride: null,
                    description: null,
                  ),
                ],
                context: context,
                examples: const [],
                nameOverride: null,
                description: null,
                additionalPropertiesPolicy: null,
                isNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
            ),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);

        const expected = r'''
          @override
          List<ParameterEntry> toForm(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
            required Encoding textEncoding,
            bool useQueryComponent = false,
            bool allowReserved = false,
            Map<String, FormFieldEncoding> fieldEncodings = const {},
          }) {
            final _$entryLists = <List<ParameterEntry>>[];
            final _$values = <String>{};
            final _$mapValues = <Map<String, PropertyValue>>[];
            if (this.myClass != null) {
              final _$myClassForm = this.myClass!.parameterProperties(allowEmpty: allowEmpty);
              _$mapValues.add(_$myClassForm);
            }
            if (this.int != null) {
              final _$intForm = this.int!.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                textEncoding: textEncoding,
              );
              _$entryLists.add(_$intForm);
              _$values.add(_$intForm.map((e) => e.value).join(','));
            }
            if (this.string != null) {
              final _$stringForm = this.string!.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                textEncoding: textEncoding,
              );
              _$entryLists.add(_$stringForm);
              _$values.add(_$stringForm.map((e) => e.value).join(','));
            }
            if (_$values.isEmpty && _$mapValues.isEmpty) {
              return const <ParameterEntry>[];
            }
            if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
              throw EncodingException(
                r'Ambiguous anyOf form encoding for TestAnyOf: mixing simple and complex values',
              );
            }
            if (_$values.isNotEmpty) {
              return _$entryLists.first;
            } else {
              final _$map = <String, PropertyValue>{};
              for (final _$m in _$mapValues) {
                _$map.addAll(_$m);
              }
              return _$map.toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                allowReserved: allowReserved,
                fieldEncodings: fieldEncodings,
                textEncoding: textEncoding,
              );
            }
          }
        ''';

        final toFormMethod = klass.methods.singleWhere(
          (method) => method.name == 'toForm',
        );
        expect(
          collapseWhitespace(format(toFormMethod.accept(emitter).toString())),
          collapseWhitespace(format(expected)),
        );
      });

      test('handles mixed shape with exception in switch', () {
        final innerOneOf = OneOfModel(
          isDeprecated: false,
          name: 'InnerChoice',
          models: [
            (discriminatorValue: 'a', model: StringModel(context: context)),
            (
              discriminatorValue: 'b',
              model: ClassModel(
                isDeprecated: false,
                name: 'ComplexData',
                properties: [
                  Property(
                    name: 'id',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                    isReadOnly: false,
                    isWriteOnly: false,
                    nameOverride: null,
                    description: null,
                  ),
                ],
                context: context,
                examples: const [],
                nameOverride: null,
                description: null,
                additionalPropertiesPolicy: null,
                isNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
            ),
          ],
          discriminator: 'type',
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'TestAnyOf',
          models: [(discriminatorValue: null, model: innerOneOf)],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          case EncodingShape.mixed:
            throw EncodingException(
              'Cannot encode field with mixed encoding shape',
            );
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });
    });

    group('toSimple method', () {
      test('uses runtime check for nested oneOf', () {
        final innerOneOf = OneOfModel(
          isDeprecated: false,
          name: 'InnerChoice',
          models: [
            (discriminatorValue: 'str', model: StringModel(context: context)),
            (
              discriminatorValue: 'obj',
              model: ClassModel(
                isDeprecated: false,
                name: 'Inner',
                properties: [
                  Property(
                    name: 'field',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                    isReadOnly: false,
                    isWriteOnly: false,
                    nameOverride: null,
                    description: null,
                  ),
                ],
                context: context,
                examples: const [],
                nameOverride: null,
                description: null,
                additionalPropertiesPolicy: null,
                isNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
            ),
          ],
          discriminator: 'type',
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'TestAnyOf',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: innerOneOf),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = r'''
          if (this.innerChoice != null) {
            switch (this.innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                _$values.add(
                  this.innerChoice!.toSimple(
                    explode: explode,
                    allowEmpty: allowEmpty,
                    literal: literal,
                  ),
                );
                break;
              case EncodingShape.complex:
                final _$innerChoiceSimple = this.innerChoice!.parameterProperties(
                  allowEmpty: allowEmpty,
                );
                _$mapValues.add(_$innerChoiceSimple);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('uses direct calls for static types', () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'TestAnyOf',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = r'''
          String toSimple({
            required bool explode,
            required bool allowEmpty,
            bool literal = false,
          }) {
            final _$values = <String>{};
            if (this.int != null) {
              final _$intSimple = this.int!.toSimple(
                explode: explode,
                allowEmpty: allowEmpty,
                literal: literal,
              );
              _$values.add(_$intSimple);
            }
            if (this.string != null) {
              final _$stringSimple = this.string!.toSimple(
                explode: explode,
                allowEmpty: allowEmpty,
                literal: literal,
              );
              _$values.add(_$stringSimple);
            }
            if (_$values.isEmpty) return '';
            return _$values.first;
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });
    });

    test('skips runtime check for static complex types', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: [
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'MyClass',
              properties: [
                Property(
                  name: 'field',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                  isReadOnly: false,
                  isWriteOnly: false,
                  nameOverride: null,
                  description: null,
                ),
              ],
              context: context,
              examples: const [],
              nameOverride: null,
              description: null,
              additionalPropertiesPolicy: null,
              isNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(
        klass.methods
            .firstWhere((m) => m.name == 'parameterProperties')
            .accept(emitter)
            .toString(),
      );

      const expected = r'''
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) { final _$mapValues = <Map<String, PropertyValue>>[]; if (this.myClass != null) { _$mapValues.add(this.myClass!.parameterProperties(allowEmpty: allowEmpty)); } final _$map = <String, PropertyValue>{}; for (final _$m in _$mapValues) { _$map.addAll(_$m); } return _$map; }
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expected))),
      );
    });
  });

  group('BinaryModel field encoding', () {
    test('throws for the binary variant and encodes the primitive variant', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'WithBinary',
        models: [
          (discriminatorValue: null, model: BinaryModel(context: context)),
          (discriminatorValue: null, model: StringModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        List<ParameterEntry> toForm(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
          required Encoding textEncoding, bool useQueryComponent = false,
          bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
        }) {
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          if (this.tonikFile != null) {
            throw EncodingException('Binary data cannot be form-encoded');
          }
          if (this.string != null) {
            final _$stringForm = this.string!.toForm(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved, textEncoding: textEncoding,
            );
            _$entryLists.add(_$stringForm);
            _$values.add(_$stringForm.map((e) => e.value).join(','));
          }
          if (_$values.isEmpty) {
            return const <ParameterEntry>[];
          }
          return _$entryLists.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });
}
