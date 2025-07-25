import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('QueryParameter', () {
    test('resolve preserves original object with provided name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final param = QueryParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: model,
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final resolved = param.resolve(name: 'newName');

      expect(resolved.name, 'newName');
      expect(resolved.rawName, 'originalRawName');
      expect(resolved.description, 'description');
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.allowEmptyValue, isFalse);
      expect(resolved.allowReserved, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, model);
      expect(resolved.encoding, QueryParameterEncoding.form);
      expect(resolved.context, context);
    });

    test('resolve preserves original name when no new name provided', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final param = QueryParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: model,
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final resolved = param.resolve();

      expect(resolved.name, 'originalName');
    });

    test('QueryParameterAlias.resolve resolves with alias name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalParam = QueryParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: model,
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final alias = QueryParameterAlias(
        name: 'aliasName',
        parameter: originalParam,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.name, 'aliasName');
      expect(resolved.rawName, 'originalRawName');
    });

    test(
      'QueryParameterAlias.resolve with provided name overrides alias name',
      () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalParam = QueryParameterObject(
          name: 'originalName',
          rawName: 'originalRawName',
          description: 'description',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: model,
          encoding: QueryParameterEncoding.form,
          context: context,
        );

        final alias = QueryParameterAlias(
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

      final originalParam = QueryParameterObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: model,
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final firstAlias = QueryParameterAlias(
        name: 'firstAliasName',
        parameter: originalParam,
        context: context,
      );

      final secondAlias = QueryParameterAlias(
        name: 'secondAliasName',
        parameter: firstAlias,
        context: context,
      );

      final resolved = secondAlias.resolve();

      expect(resolved.name, 'secondAliasName');
      expect(resolved.rawName, 'originalRawName');
    });
  });
}
