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

      expect(resolved.name, 'newName');
      expect(resolved.rawName, 'originalRawName');
      expect(resolved.description, 'description');
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.allowEmptyValue, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, model);
      expect(resolved.encoding, PathParameterEncoding.simple);
      expect(resolved.context, context);
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

      expect(resolved.name, 'originalName');
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

      expect(resolved.name, 'aliasName');
      expect(resolved.rawName, 'originalRawName');
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

        expect(resolved.name, 'overrideName');
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

      expect(resolved.name, 'secondAliasName');
      expect(resolved.rawName, 'originalRawName');
    });

    group('description override', () {
      test('PathParameterAlias stores description override', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = PathParameterObject(
          name: 'originalName',
          rawName: 'originalRawName',
          description: 'Original description',
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
          description: 'Overridden description',
        );

        expect(alias.description, 'Overridden description');
        expect(alias.resolve().description, 'Original description');
      });

      test('PathParameterAlias description is null when not overridden', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = PathParameterObject(
          name: 'originalName',
          rawName: 'originalRawName',
          description: 'Original description',
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

        expect(alias.description, isNull);
      });
    });
  });
}
