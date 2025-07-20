import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('RequestHeader', () {
    test('resolve preserves original object with provided name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final header = RequestHeaderObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final resolved = header.resolve(name: 'newName');

      expect(resolved.name, 'newName');
      expect(resolved.rawName, 'originalRawName');
      expect(resolved.description, 'description');
      expect(resolved.isRequired, isTrue);
      expect(resolved.isDeprecated, isFalse);
      expect(resolved.allowEmptyValue, isFalse);
      expect(resolved.explode, isFalse);
      expect(resolved.model, model);
      expect(resolved.encoding, HeaderParameterEncoding.simple);
      expect(resolved.context, context);
    });

    test('resolve preserves original name when no new name provided', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final header = RequestHeaderObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final resolved = header.resolve();

      expect(resolved.name, 'originalName');
    });

    test('RequestHeaderAlias.resolve resolves with alias name', () {
      final context = Context.initial();
      final model = StringModel(context: context);

      final originalHeader = RequestHeaderObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final alias = RequestHeaderAlias(
        name: 'aliasName',
        header: originalHeader,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.name, 'aliasName');
      expect(resolved.rawName, 'originalRawName');
    });

    test(
      'RequestHeaderAlias.resolve with provided name overrides alias name',
      () {
        final context = Context.initial();
        final model = StringModel(context: context);

        final originalHeader = RequestHeaderObject(
          name: 'originalName',
          rawName: 'originalRawName',
          description: 'description',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: model,
          encoding: HeaderParameterEncoding.simple,
          context: context,
        );

        final alias = RequestHeaderAlias(
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

      final originalHeader = RequestHeaderObject(
        name: 'originalName',
        rawName: 'originalRawName',
        description: 'description',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: model,
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final firstAlias = RequestHeaderAlias(
        name: 'firstAliasName',
        header: originalHeader,
        context: context,
      );

      final secondAlias = RequestHeaderAlias(
        name: 'secondAliasName',
        header: firstAlias,
        context: context,
      );

      final resolved = secondAlias.resolve();

      expect(resolved.name, 'secondAliasName');
      expect(resolved.rawName, 'originalRawName');
    });
  });
}
