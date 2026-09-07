import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/query_generator.dart';

void main() {
  late NameManager nameManager;
  late QueryGenerator generator;
  late Operation operation;
  final context = Context.initial();
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    generator = QueryGenerator(nameManager: nameManager, package: 'api');
    operation = Operation(
      context: context,
      path: '/items',
      method: HttpMethod.get,
      tags: const {},
      isDeprecated: false,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      responses: const {},
      securitySchemes: const {},
    );
  });

  test('encodes a required model as one JSON string parameter', () {
    final parameter = QueryParameterObject(
      name: 'filter',
      rawName: 'filter',
      description: null,
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: true,
      model: ClassModel(
        name: 'Filter',
        isDeprecated: false,
        context: context,
        properties: const [],
        examples: const [],
      ),
      encoding: QueryParameterEncoding.json,
      context: context,
      examples: const [],
      defaultValue: null,
    );

    final method = generator.generateQueryParametersMethod(operation, [
      (normalizedName: 'filter', parameter: parameter),
    ]);

    const expected = r'''
String? _queryParameters({required Filter filter}) {
      final _$entries = <ParameterEntry>[];
      _$entries.addAll(jsonEncode(filter.toJson()).toForm(
        r'filter', explode: false, allowEmpty: false, textEncoding: utf8,
      ));
      if (_$entries.isEmpty) {
        return null;
      }
      return _$entries.map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}').join('&');
    }''';
    expect(format(method.accept(emitter).toString()), format(expected));
  });

  test('guards optional immutable maps and converts formatted JSON values', () {
    generator = QueryGenerator(
      nameManager: nameManager,
      package: 'api',
      useImmutableCollections: true,
    );
    final parameter = QueryParameterObject(
      name: 'filter',
      rawName: r'filter&$name',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: false,
      model: MapModel(
        valueModel: DateTimeModel(context: context),
        context: context,
        examples: const [],
      ),
      encoding: QueryParameterEncoding.json,
      context: context,
      examples: const [],
      defaultValue: null,
    );

    final method = generator.generateQueryParametersMethod(operation, [
      (normalizedName: 'filter', parameter: parameter),
    ]);

    const expected = r'''
String? _queryParameters({IMap<String, DateTime>? filter}) {
      final _$entries = <ParameterEntry>[];
      if (filter != null) {
        _$entries.addAll(jsonEncode(filter.unlock.map((k, v) => MapEntry(k, v.toTimeZonedIso8601String()))).toForm(
          r'filter&$name', explode: false, allowEmpty: false, textEncoding: utf8,
        ));
      }
      if (_$entries.isEmpty) {
        return null;
      }
      return _$entries.map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}').join('&');
    }''';
    expect(format(method.accept(emitter).toString()), format(expected));
  });

  test(
    'shares recursive helpers across required and optional JSON parameters',
    () {
      final model = MapModel(
        name: 'Filter',
        isNullable: true,
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );
      model.valueModel = model;
      final requiredFilter = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: model,
        encoding: QueryParameterEncoding.json,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final optionalFilter = QueryParameterObject(
        name: 'other',
        rawName: 'other',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: model,
        encoding: QueryParameterEncoding.json,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final method = generator.generateQueryParametersMethod(operation, [
        (normalizedName: 'filter', parameter: requiredFilter),
        (normalizedName: 'other', parameter: optionalFilter),
      ]);

      const expected = r'''
String? _queryParameters({required Filter filter, Filter? other}) {
        late final Object? Function(Object?) _$encodeFilter;
        _$encodeFilter = (Object? raw) {
          if (raw is! Filter) {
            throw EncodingException(
              'Cannot encode value as Filter; got: '
              '${raw.runtimeType}',
            );
          }
          final v = raw;
          return v?.map((k, v) => MapEntry(
            k, v == null ? null : _$encodeFilter(v),
          ));
        };
        final _$entries = <ParameterEntry>[];
        _$entries.addAll(jsonEncode(
          filter == null ? null : _$encodeFilter(filter),
        ).toForm(r'filter', explode: false, allowEmpty: false, textEncoding: utf8));
        if (other != null) {
          _$entries.addAll(jsonEncode(
            _$encodeFilter(other),
          ).toForm(r'other', explode: false, allowEmpty: false, textEncoding: utf8));
        }
        if (_$entries.isEmpty) {
          return null;
        }
        return _$entries.map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}').join('&');
      }''';
      expect(format(method.accept(emitter).toString()), format(expected));
    },
  );
  test('serializes a required nullable list as JSON null or an array', () {
    final parameter = QueryParameterObject(
      name: 'filter',
      rawName: 'filter',
      description: null,
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: false,
      model: ListModel(
        content: DateTimeModel(context: context),
        context: context,
        examples: const [],
        isNullable: true,
      ),
      encoding: QueryParameterEncoding.json,
      context: context,
      examples: const [],
      defaultValue: null,
    );

    final method = generator.generateQueryParametersMethod(operation, [
      (normalizedName: 'filter', parameter: parameter),
    ]);

    const expected = r'''
    String? _queryParameters({required List<DateTime>? filter}) {
      final _$entries = <ParameterEntry>[];
      _$entries.addAll(jsonEncode(
        filter?.map((e) => e.toTimeZonedIso8601String()).toList(),
      ).toForm(r'filter', explode: false, allowEmpty: false, textEncoding: utf8));
      if (_$entries.isEmpty) {
        return null;
      }
      return _$entries
          .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}').join('&');
    }''';
    expect(format(method.accept(emitter).toString()), format(expected));
  });

  test('promotes optional nullable lists before JSON conversion', () {
    final parameter = QueryParameterObject(
      name: 'filter',
      rawName: 'filter',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: false,
      model: ListModel(
        content: DateTimeModel(context: context),
        context: context,
        examples: const [],
        isNullable: true,
      ),
      encoding: QueryParameterEncoding.json,
      context: context,
      examples: const [],
      defaultValue: null,
    );

    final method = generator.generateQueryParametersMethod(operation, [
      (normalizedName: 'filter', parameter: parameter),
    ]);

    const expected = r'''
    String? _queryParameters({List<DateTime>? filter}) {
      final _$entries = <ParameterEntry>[];
      if (filter != null) {
        _$entries.addAll(jsonEncode(
          filter.map((e) => e.toTimeZonedIso8601String()).toList(),
        ).toForm(r'filter', explode: false, allowEmpty: false, textEncoding: utf8));
      }
      if (_$entries.isEmpty) {
        return null;
      }
      return _$entries
          .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}').join('&');
    }''';
    expect(format(method.accept(emitter).toString()), format(expected));
  });
}
