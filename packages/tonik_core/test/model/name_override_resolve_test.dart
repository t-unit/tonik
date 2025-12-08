import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('QueryParameter.resolve nameOverride propagation', () {
    test(
      'preserves nameOverride from original parameter when not overridden',
      () {
        final param = QueryParameterObject(
          name: 'originalName',
          nameOverride: 'customName',
          rawName: 'original_name',
          description: null,
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: StringModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
        );

        final resolved = param.resolve();

        expect(resolved.nameOverride, 'customName');
      },
    );

    test('allows overriding nameOverride via resolve parameter', () {
      final param = QueryParameterObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'original_name',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final resolved = param.resolve(nameOverride: 'newOverride');

      expect(resolved.nameOverride, 'newOverride');
    });

    test('alias resolve propagates nameOverride from underlying parameter', () {
      final originalParam = QueryParameterObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'original_name',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final alias = QueryParameterAlias(
        name: 'aliasName',
        parameter: originalParam,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.nameOverride, 'customName');
    });

    test('alias resolve allows setting new nameOverride', () {
      final originalParam = QueryParameterObject(
        name: 'originalName',
        rawName: 'original_name',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final alias = QueryParameterAlias(
        name: 'aliasName',
        parameter: originalParam,
        context: context,
      );

      final resolved = alias.resolve(nameOverride: 'newOverride');

      expect(resolved.nameOverride, 'newOverride');
    });
  });

  group('PathParameter.resolve nameOverride propagation', () {
    test(
      'preserves nameOverride from original parameter when not overridden',
      () {
        final param = PathParameterObject(
          name: 'originalName',
          nameOverride: 'customName',
          rawName: 'original_name',
          description: null,
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: StringModel(context: context),
          encoding: PathParameterEncoding.simple,
          context: context,
        );

        final resolved = param.resolve();

        expect(resolved.nameOverride, 'customName');
      },
    );

    test('allows overriding nameOverride via resolve parameter', () {
      final param = PathParameterObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'original_name',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final resolved = param.resolve(nameOverride: 'newOverride');

      expect(resolved.nameOverride, 'newOverride');
    });

    test('alias resolve propagates nameOverride from underlying parameter', () {
      final originalParam = PathParameterObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'original_name',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final alias = PathParameterAlias(
        name: 'aliasName',
        parameter: originalParam,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.nameOverride, 'customName');
    });
  });

  group('RequestHeader.resolve nameOverride propagation', () {
    test('preserves nameOverride from original header when not overridden', () {
      final header = RequestHeaderObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'X-Original-Header',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final resolved = header.resolve();

      expect(resolved.nameOverride, 'customName');
    });

    test('allows overriding nameOverride via resolve parameter', () {
      final header = RequestHeaderObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'X-Original-Header',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final resolved = header.resolve(nameOverride: 'newOverride');

      expect(resolved.nameOverride, 'newOverride');
    });

    test('alias resolve propagates nameOverride from underlying header', () {
      final originalHeader = RequestHeaderObject(
        name: 'originalName',
        nameOverride: 'customName',
        rawName: 'X-Original-Header',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final alias = RequestHeaderAlias(
        name: 'aliasName',
        header: originalHeader,
        context: context,
      );

      final resolved = alias.resolve();

      expect(resolved.nameOverride, 'customName');
    });
  });
}
