import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';

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

      expect(resolved.name, equals('newName'));
      expect(resolved.rawName, equals('originalRawName'));
      expect(resolved.description, equals('description'));
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.allowEmptyValue, isFalse);
      expect(resolved.allowReserved, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, equals(model));
      expect(resolved.encoding, equals(QueryParameterEncoding.form));
      expect(resolved.context, equals(context));
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

      expect(resolved.name, equals('originalName'));
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

      expect(resolved.name, equals('aliasName'));
      expect(resolved.rawName, equals('originalRawName'));
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

        expect(resolved.name, equals('overrideName'));
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

      expect(resolved.name, equals('secondAliasName'));
      expect(resolved.rawName, equals('originalRawName'));
    });
  });
}
