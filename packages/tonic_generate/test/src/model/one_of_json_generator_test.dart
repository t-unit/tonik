import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/one_of_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  late OneOfGenerator generator;
  late NameManger nameManger;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManger = NameManger(generator: nameGenerator);
    generator = OneOfGenerator(
      nameManger: nameManger,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('OneOf with primitive types', () {
    late Class generatedClass;

    setUp(() {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (discriminatorValue: 'success', model: StringModel(context: context)),
          (discriminatorValue: 'error', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      generatedClass = generator.generateClass(model);
    });

    test('has private constructor for methods', () {
      expect(generatedClass.constructors.any((c) => c.name == '_'), isTrue);
    });

    test('toJson method', () {
      final toJson = generatedClass.methods.firstWhere(
        (m) => m.name == 'toJson',
      );
      expect(toJson.returns?.accept(emitter).toString(), 'dynamic');

      final body = toJson.body?.accept(emitter).toString() ?? '';

      const expectedBody = '''
        final (dynamic json, String? discriminator) = switch (this) {
          ResultSuccess(:final value) => (value, 'success'),
          ResultError(:final value) => (value, 'error')
        };

        return json;''';

      expect(body.normalizeCode(), expectedBody.normalizeCode());
    });

    test('fromJson method', () {
      final fromJson = generatedClass.methods.firstWhere(
        (m) => m.name == 'fromJson',
      );
      expect(fromJson.static, isTrue);
      expect(fromJson.returns?.accept(emitter).toString(), 'Result');
      expect(
        fromJson.requiredParameters.first.type?.accept(emitter).toString(),
        'dynamic',
      );

      final body = fromJson.body?.accept(emitter).toString() ?? '';

      const expectedBody = r'''
        return switch (json) {
          String() => Result.success(json),
          int() => Result.error(json),
          _ => throw ArgumentError('Invalid JSON type for Result: \${json.runtimeType}')
        };''';

      expect(body.normalizeCode(), expectedBody.normalizeCode());
    });
  });

  group('OneOf with complex types and discriminator', () {
    late Class generatedClass;

    setUp(() {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (
            discriminatorValue: 'success',
            model: ClassModel(
              name: 'Success',
              properties: {
                Property(
                  name: 'value',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              },
              context: context,
            ),
          ),
          (
            discriminatorValue: 'error',
            model: ClassModel(
              name: 'Error',
              properties: {
                Property(
                  name: 'value',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              },
              context: context,
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      generatedClass = generator.generateClass(model);
    });

    test('toJson method', () {
      final toJson = generatedClass.methods.firstWhere(
        (m) => m.name == 'toJson',
      );
      expect(toJson.returns?.accept(emitter).toString(), 'dynamic');

      final body = toJson.body?.accept(emitter).toString() ?? '';

      const expectedBody = '''
        final (dynamic json, String? discriminator) = switch (this) {
          ResultSuccess(:final value) => (value.toJson(), 'success'),
          ResultError(:final value) => (value.toJson(), 'error')
        };
        
        if (discriminator != null && json is Map<String, dynamic>) {
          json.putIfAbsent('type', () => discriminator);
        }

        return json;''';

      expect(body.normalizeCode(), expectedBody.normalizeCode());
    });

    test('fromJson method', () {
      final fromJson = generatedClass.methods.firstWhere(
        (m) => m.name == 'fromJson',
      );
      expect(fromJson.static, isTrue);
      expect(
        fromJson.requiredParameters.first.type?.accept(emitter).toString(),
        'Map<String, dynamic>',
      );

      final body = fromJson.body?.accept(emitter).toString() ?? '';

      const expectedBody = r'''
        return switch (json['type']) {
          'success' => Result.success(Success.fromJson(json)),
          'error' => Result.error(Error.fromJson(json)),
          _ => throw ArgumentError('Invalid discriminator value for Result: \${json['type']}')
        };''';

      expect(body.normalizeCode(), expectedBody.normalizeCode());
    });
  });

  group('OneOf with mixed types', () {
    late Class generatedClass;

    setUp(() {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Success',
              properties: {
                Property(
                  name: 'value',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              },
              context: context,
            ),
          ),
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: 'error',
            model: ClassModel(
              name: 'Error',
              properties: {
                Property(
                  name: 'value',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              },
              context: context,
            ),
          ),
        },
        discriminator: 'discriminator',
        context: context,
      );

      generatedClass = generator.generateClass(model);
    });

    test('toJson method', () {
      final toJson = generatedClass.methods.firstWhere(
        (m) => m.name == 'toJson',
      );
      expect(toJson.returns?.accept(emitter).toString(), 'dynamic');

      final body = toJson.body?.accept(emitter).toString() ?? '';

      const expectedBody = '''
        final (dynamic json, String? discriminator) = switch (this) {
          ResultSuccess(:final value) => (value.toJson(), null),
          ResultAnonymous(:final value) => (value, null),
          ResultError(:final value) => (value.toJson(), 'error')
        };

        if (discriminator != null && json is Map<String, dynamic>) {
          json.putIfAbsent('discriminator', () => discriminator);
        }

        return json;''';

      expect(body.normalizeCode(), expectedBody.normalizeCode());
    });

    test('fromJson method', () {
      final fromJson = generatedClass.methods.firstWhere(
        (m) => m.name == 'fromJson',
      );
      expect(fromJson.static, isTrue);
      expect(
        fromJson.requiredParameters.first.type?.accept(emitter).toString(),
        'dynamic',
      );

      final body = fromJson.body?.accept(emitter).toString() ?? '';

      const expectedBody = '''
        final discriminator = json is Map<String, dynamic> ? json['discriminator'] : null;

        final result = switch (discriminator) {
          'error' => Result.error(Error.fromJson(json)),
          _ => null
        };

        if (result != null) {
          return result;
        }

        if (json is String) {
          return Result.primitive(json);
        }

        try {
          return Result.success(Success.fromJson(json as Map<String, dynamic>));
        } catch (_) {}

        throw ArgumentError('Invalid JSON for Result');''';

      expect(body.normalizeCode(), expectedBody.normalizeCode());
    });
  });
}

extension on String {
  String normalizeCode() => replaceAll(RegExp(r'\s+'), ' ').trim();
}
