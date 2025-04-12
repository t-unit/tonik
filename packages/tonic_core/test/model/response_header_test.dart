import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';

void main() {
  group('ResponseHeader', () {
    test('resolve preserves original object with provided name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final header = ResponseHeaderObject(
        name: 'originalName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: ResponseHeaderEncoding.simple,
        context: context,
      );

      final resolved = header.resolve(name: 'newName');

      expect(resolved.name, equals('newName'));
      expect(resolved.description, equals('description'));
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, equals(model));
      expect(resolved.encoding, equals(ResponseHeaderEncoding.simple));
      expect(resolved.context, equals(context));
    });

    test('resolve preserves original name when no new name provided', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final header = ResponseHeaderObject(
        name: 'originalName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: ResponseHeaderEncoding.simple,
        context: context,
      );

      final resolved = header.resolve();

      expect(resolved.name, equals('originalName'));
    });

    test('ResponseHeaderAlias.resolve resolves with alias name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalHeader = ResponseHeaderObject(
        name: 'originalName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: ResponseHeaderEncoding.simple,
        context: context,
      );

      final alias = ResponseHeaderAlias(
        name: 'aliasName',
        header: originalHeader,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.name, equals('aliasName'));
      expect(resolved.description, equals('description'));
    });

    test(
      'ResponseHeaderAlias.resolve with provided name overrides alias name',
      () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalHeader = ResponseHeaderObject(
          name: 'originalName',
          description: 'description',
          isRequired: true,
          isDeprecated: false,
          explode: false,
          model: model,
          encoding: ResponseHeaderEncoding.simple,
          context: context,
        );

        final alias = ResponseHeaderAlias(
          name: 'aliasName',
          header: originalHeader,
          context: context,
        );

        final resolved = alias.resolve(name: 'overrideName');

        expect(resolved.name, equals('overrideName'));
      },
    );

    test('Nested aliases resolve correctly', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalHeader = ResponseHeaderObject(
        name: 'originalName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: model,
        encoding: ResponseHeaderEncoding.simple,
        context: context,
      );

      final firstAlias = ResponseHeaderAlias(
        name: 'firstAliasName',
        header: originalHeader,
        context: context,
      );

      final secondAlias = ResponseHeaderAlias(
        name: 'secondAliasName',
        header: firstAlias,
        context: context,
      );

      final resolved = secondAlias.resolve();

      expect(resolved.name, equals('secondAliasName'));
      expect(resolved.description, equals('description'));
    });
  });
}
