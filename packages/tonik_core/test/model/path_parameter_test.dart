import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('PathParameter', () {
    test('resolve preserves original object with provided name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final param = PathParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final resolved = param.resolve(name: 'newName');

      expect(resolved.name, equals('newName'));
      expect(resolved.rawName, equals('originalRawName'));
      expect(resolved.description, equals('description'));
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.allowEmptyValue, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, equals(model));
      expect(resolved.encoding, equals(PathParameterEncoding.simple));
      expect(resolved.context, equals(context));
    });

    test('resolve preserves original name when no new name provided', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final param = PathParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final resolved = param.resolve();

      expect(resolved.name, equals('originalName'));
    });

    test('PathParameterAlias.resolve resolves with alias name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalParam = PathParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final alias = PathParameterAlias(
        name: 'aliasName',
        parameter: originalParam,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.name, equals('aliasName'));
      expect(resolved.rawName, equals('originalRawName'));
    });

    test(
      'PathParameterAlias.resolve with provided name overrides alias name',
      () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = PathParameterObject(
          name: 'originalName',
          rawName: 'originalRawName',
          description: 'description',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: model,
          encoding: PathParameterEncoding.simple,
          context: context,
        );

        final alias = PathParameterAlias(
          name: 'aliasName',
          parameter: originalParam,
          context: context,
        );

        final resolved = alias.resolve(name: 'overrideName');

        expect(resolved.name, equals('overrideName'));
      },
    );

    test('Nested aliases resolve correctly', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalParam = PathParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final firstAlias = PathParameterAlias(
        name: 'firstAliasName',
        parameter: originalParam,
        context: context,
      );

      final secondAlias = PathParameterAlias(
        name: 'secondAliasName',
        parameter: firstAlias,
        context: context,
      );

      final resolved = secondAlias.resolve();

      expect(resolved.name, equals('secondAliasName'));
      expect(resolved.rawName, equals('originalRawName'));
    });
  });
}
