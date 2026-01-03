import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

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

      expect(resolved.name, 'newName');
      expect(resolved.description, 'description');
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, model);
      expect(resolved.encoding, ResponseHeaderEncoding.simple);
      expect(resolved.context, context);
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

      expect(resolved.name, 'originalName');
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

      expect(resolved.name, 'aliasName');
      expect(resolved.description, 'description');
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

        expect(resolved.name, 'overrideName');
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

      expect(resolved.name, 'secondAliasName');
      expect(resolved.description, 'description');
    });

    group('description override', () {
      test('ResponseHeaderAlias stores description override', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalHeader = ResponseHeaderObject(
          name: 'originalName',
          description: 'Original description',
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
          description: 'Overridden description',
        );

        expect(alias.description, 'Overridden description');
        expect(alias.resolve().description, 'Original description');
      });

      test('ResponseHeaderAlias description is null when not overridden', () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalHeader = ResponseHeaderObject(
          name: 'originalName',
          description: 'Original description',
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

        expect(alias.description, isNull);
      });
    });
  });
}
