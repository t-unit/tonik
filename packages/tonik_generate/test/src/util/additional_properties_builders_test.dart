import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/additional_properties_builders.dart';
import 'package:tonik_generate/src/util/flat_value_codec_plan.dart';

void main() {
  late Context context;
  late DartEmitter emitter;
  late NameManager nameManager;
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
  });

  String formatCodes(List<Code> codes) {
    final method = Method(
      (b) => b
        ..name = 'run'
        ..returns = refer('void', 'dart:core')
        ..body = Block.of(codes),
    );
    final clazz = Class(
      (b) => b
        ..name = 'Temp'
        ..methods.add(method),
    );
    final library = Library((b) => b..body.add(clazz));
    return format(library.accept(emitter).toString());
  }

  EnumModel<String> statusEnum() => EnumModel<String>(
    name: 'Status',
    values: {const EnumEntry(value: 'active')},
    isNullable: false,
    context: context,
    isDeprecated: false,
    examples: const [],
  );

  group('buildApJsonCaptureLoop', () {
    test('typed enum values decode through fromJson with known-key '
        'exclusion', () {
      final result = buildApJsonCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: statusEnum(),
          knownWireKeys: const {'name'},
        ),
        sourceMapVar: r'_$map',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          final _$additional = <String, Status>{};
          for (final _$entry in _$map.entries) {
            if (!_$knownKeys.contains(_$entry.key)) {
              _$additional[_$entry.key] = Status.fromJson(_$entry.value);
            }
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('Any values are captured raw', () {
      final result = buildApJsonCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: AnyModel(context: context),
          knownWireKeys: const {'name'},
        ),
        sourceMapVar: r'_$map',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          final _$additional = <String, Object?>{};
          for (final _$entry in _$map.entries) {
            if (!_$knownKeys.contains(_$entry.key)) {
              _$additional[_$entry.key] = _$entry.value;
            }
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('no known keys skips exclusion entirely', () {
      final result = buildApJsonCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: StringModel(context: context),
          knownWireKeys: const {},
        ),
        sourceMapVar: r'_$map',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          final _$additional = <String, String>{};
          for (final _$entry in _$map.entries) {
            _$additional[_$entry.key] = _$entry.value.decodeJsonString(
              context: r'Order.additionalProperties',
            );
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });
  });

  group('buildApJsonEncode', () {
    test('rejects keys colliding with declared wire keys before '
        'spreading', () {
      final result = buildApJsonEncode(
        AdditionalPropertiesPlan(
          valueModel: StringModel(context: context),
          knownWireKeys: const {'name'},
        ),
        targetMapVar: r'_$map',
        apAccess: 'additionalProperties',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          for (final _$k in additionalProperties.keys) {
            if (_$knownKeys.contains(_$k)) {
              throw EncodingException(
                r'Additional property keys must not collide with declared wire keys of Order',
              );
            }
          }
          _$map.addAll(additionalProperties);
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('Any values encode recursively through the Any JSON codec', () {
      final result = buildApJsonEncode(
        AdditionalPropertiesPlan(
          valueModel: AnyModel(context: context),
          knownWireKeys: const {},
        ),
        targetMapVar: r'_$map',
        apAccess: 'additionalProperties',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          _$map.addAll(
            additionalProperties.map(
              (k, v) => MapEntry(
                k,
                encodeUnknownJson(v, context: r'Order.additionalProperties'),
              ),
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('enum values encode through toJson', () {
      final result = buildApJsonEncode(
        AdditionalPropertiesPlan(
          valueModel: statusEnum(),
          knownWireKeys: const {},
        ),
        targetMapVar: r'_$map',
        apAccess: 'additionalProperties',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          _$map.addAll(additionalProperties.map((k, v) => MapEntry(k, v.toJson())));
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });
  });

  group('buildApFlatCaptureLoop', () {
    test('enum values decode through fromSimple', () {
      final result = buildApFlatCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: statusEnum(),
          knownWireKeys: const {'name'},
        ),
        format: FlatWireFormat.simple,
        sourceMapVar: r'_$values',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          final _$additional = <String, Status>{};
          for (final _$entry in _$values.entries) {
            if (!_$knownKeys.contains(_$entry.key)) {
              _$additional[_$entry.key] = Status.fromSimple(
                _$entry.value,
                explode: explode,
              );
            }
          }
        }
      ''';

      expect(result, isA<CapturingApFlatCapture>());
      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('int values decode through the form decoder', () {
      final result = buildApFlatCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: IntegerModel(context: context),
          knownWireKeys: const {'name'},
        ),
        format: FlatWireFormat.form,
        sourceMapVar: r'_$values',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          final _$additional = <String, int>{};
          for (final _$entry in _$values.entries) {
            if (!_$knownKeys.contains(_$entry.key)) {
              _$additional[_$entry.key] = _$entry.value.decodeFormInt(
                context: r'Order.additionalProperties',
              );
            }
          }
        }
      ''';

      expect(result, isA<CapturingApFlatCapture>());
      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('list value models throw on unknown keys because element '
        'boundaries cannot be recovered', () {
      final result = buildApFlatCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          knownWireKeys: const {'name'},
        ),
        format: FlatWireFormat.simple,
        sourceMapVar: r'_$values',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          for (final _$entry in _$values.entries) {
            if (!_$knownKeys.contains(_$entry.key)) {
              throw SimpleDecodingException(
                r'List values cannot be decoded from a flat value at Order.additionalProperties',
              );
            }
          }
        }
      ''';

      expect(result, isA<RejectingApFlatCapture>());
      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('undecodable value models throw on unknown keys instead of '
        'dropping them', () {
      final result = buildApFlatCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          knownWireKeys: const {'name'},
        ),
        format: FlatWireFormat.form,
        sourceMapVar: r'_$values',
        nameManager: nameManager,
        package: 'package:example/api.dart',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          for (final _$entry in _$values.entries) {
            if (!_$knownKeys.contains(_$entry.key)) {
              throw FormDecodingException(
                r'Map values cannot be decoded from a flat value at Order.additionalProperties',
              );
            }
          }
        }
      ''';

      expect(result, isA<RejectingApFlatCapture>());
      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });
  });

  group('buildApPropertyValueEntries', () {
    test('typed string values become scalar entries with collision '
        'rejection', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: StringModel(context: context),
          knownWireKeys: const {'name'},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          const _$knownKeys = {r'name'};
          for (final _$e in additionalProperties.entries) {
            if (_$knownKeys.contains(_$e.key)) {
              throw EncodingException(
                r'Additional property keys must not collide with declared wire keys of Order',
              );
            }
            _$result[_$e.key] = PropertyValue.scalar(_$e.value);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('Any values omit null entries and use the unknown-flat-scalar '
        'boundary', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: AnyModel(context: context),
          knownWireKeys: const {},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
      );

      const expected = r'''
        class Temp {
          void run() {
            for (final _$e in additionalProperties.entries) {
              final _$v = _$e.value;
              if (_$v == null) continue;
              _$result[_$e.key] = PropertyValue.scalar(
                encodeUnknownFlatScalar(
                  _$v,
                  context: r'Order.additionalProperties',
                ),
              );
            }
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        collapseWhitespace(format(expected)),
      );
    });

    test('nullable typed values omit null entries', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: AliasModel(
            model: StringModel(context: context),
            isNullable: true,
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          knownWireKeys: const {},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          for (final _$e in additionalProperties.entries) {
            final _$v = _$e.value;
            if (_$v == null) continue;
            _$result[_$e.key] = PropertyValue.scalar(_$v);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('enum values become scalar entries through toJson', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: statusEnum(),
          knownWireKeys: const {},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          for (final _$e in additionalProperties.entries) {
            _$result[_$e.key] = PropertyValue.scalar(_$e.value.toJson());
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('array-capable values become array entries', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          knownWireKeys: const {},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
      );

      const expected = r'''
        void run() {
          for (final _$e in additionalProperties.entries) {
            _$result[_$e.key] = PropertyValue.array(_$e.value);
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('array values unlock immutable lists when immutable collections '
        'are enabled', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: ListModel(
            content: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          knownWireKeys: const {},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
        useImmutableCollections: true,
      );

      const expected = r'''
        void run() {
          for (final _$e in additionalProperties.entries) {
            _$result[_$e.key] = PropertyValue.array(
              _$e.value.unlock.map((e) => e.toString()).toList(),
            );
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });

    test('unsupported value models throw before any entry is emitted', () {
      final result = buildApPropertyValueEntries(
        AdditionalPropertiesPlan(
          valueModel: ClassModel(
            properties: const [],
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          knownWireKeys: const {},
        ),
        targetVar: r'_$result',
        apAccess: 'additionalProperties',
        contextClass: 'Order',
      );

      const expected = '''
        void run() {
          if (additionalProperties.isNotEmpty) {
            throw EncodingException(
              r'ClassModel values have no flat representation at Order.additionalProperties',
            );
          }
        }
      ''';

      expect(
        collapseWhitespace(formatCodes(result.codes)),
        contains(collapseWhitespace(expected)),
      );
    });
  });
}
