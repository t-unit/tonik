import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('CookieParameter', () {
    test('resolve preserves original object with provided name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final param = CookieParameterObject(
        name: 'originalName',
        rawName: 'session_id',
        description: 'Session identifier',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final resolved = param.resolve(name: 'newName');

      expect(resolved.name, 'newName');
      expect(resolved.rawName, 'session_id');
      expect(resolved.description, 'Session identifier');
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, model);
      expect(resolved.encoding, CookieParameterEncoding.form);
      expect(resolved.context, context);
    });

    test('resolve preserves original name when no new name provided', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final param = CookieParameterObject(
        name: 'originalName',
        rawName: 'session_id',
        description: 'Session identifier',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final resolved = param.resolve();

      expect(resolved.name, 'originalName');
    });

    test('CookieParameterAlias.resolve resolves with alias name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalParam = CookieParameterObject(
        name: 'originalName',
        rawName: 'session_id',
        description: 'Session identifier',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final alias = CookieParameterAlias(
        name: 'aliasName',
        parameter: originalParam,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.name, 'aliasName');
      expect(resolved.rawName, 'session_id');
    });

    test(
      'CookieParameterAlias.resolve with provided name overrides alias name',
      () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = CookieParameterObject(
          name: 'originalName',
          rawName: 'session_id',
          description: 'Session identifier',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: model,
          encoding: CookieParameterEncoding.form,
          context: context,
        );

        final alias = CookieParameterAlias(
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

      final originalParam = CookieParameterObject(
        name: 'originalName',
        rawName: 'session_id',
        description: 'Session identifier',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final firstAlias = CookieParameterAlias(
        name: 'firstAliasName',
        parameter: originalParam,
        context: context,
      );

      final secondAlias = CookieParameterAlias(
        name: 'secondAliasName',
        parameter: firstAlias,
        context: context,
      );

      final resolved = secondAlias.resolve();

      expect(resolved.name, 'secondAliasName');
      expect(resolved.rawName, 'session_id');
    });

    group('description override', () {
      test('CookieParameterAlias stores description override', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = CookieParameterObject(
          name: 'originalName',
          rawName: 'session_id',
          description: 'Original description',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: model,
          encoding: CookieParameterEncoding.form,
          context: context,
        );

        final alias = CookieParameterAlias(
          name: 'aliasName',
          parameter: originalParam,
          context: context,
          description: 'Overridden description',
        );

        expect(alias.description, 'Overridden description');
        expect(alias.resolve().description, 'Original description');
      });

      test('CookieParameterAlias description is null when not overridden', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = CookieParameterObject(
          name: 'originalName',
          rawName: 'session_id',
          description: 'Original description',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: model,
          encoding: CookieParameterEncoding.form,
          context: context,
        );

        final alias = CookieParameterAlias(
          name: 'aliasName',
          parameter: originalParam,
          context: context,
        );

        expect(alias.description, isNull);
      });
    });

    group('equality', () {
      test('CookieParameterAlias equality includes all fields', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final param = CookieParameterObject(
          name: 'name',
          rawName: 'session_id',
          description: 'desc',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: model,
          encoding: CookieParameterEncoding.form,
          context: context,
        );

        final alias1 = CookieParameterAlias(
          name: 'alias',
          parameter: param,
          context: context,
          description: 'override',
        );

        final alias2 = CookieParameterAlias(
          name: 'alias',
          parameter: param,
          context: context,
          description: 'override',
        );

        expect(alias1, alias2);
        expect(alias1.hashCode, alias2.hashCode);
      });

      test(
        'CookieParameterAlias with different descriptions are not equal',
        () {
          final context = Context.initial();
          final model = StringModel(context: context);

          final param = CookieParameterObject(
            name: 'name',
            rawName: 'session_id',
            description: 'desc',
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: model,
            encoding: CookieParameterEncoding.form,
            context: context,
          );

          final alias1 = CookieParameterAlias(
            name: 'alias',
            parameter: param,
            context: context,
            description: 'override1',
          );

          final alias2 = CookieParameterAlias(
            name: 'alias',
            parameter: param,
            context: context,
            description: 'override2',
          );

          expect(alias1, isNot(alias2));
        },
      );
    });
  });
}
