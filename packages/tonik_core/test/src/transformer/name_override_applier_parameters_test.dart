import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/name_override_applier.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  final applier = NameOverrideApplier();
  final context = Context.initial();

  test('inline path and header overrides match their wire names', () {
    final path = PathParameterObject(
      name: null,
      rawName: 'pet_id',
      description: null,
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final header = RequestHeaderObject(
      name: null,
      rawName: 'X-Trace-Id',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: HeaderParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );

    final paths = <PathParameter>{path};
    final headers = <RequestHeader>{header};

    applier
      ..applyPathParameterOverrides(paths, 'getPet', {'getPet.pet_id': 'id'})
      ..applyHeaderOverrides(headers, 'getPet', {
        'getPet.X-Trace-Id': 'traceId',
      });

    expect(paths.single.resolve().nameOverride, 'id');
    expect(headers.single.resolve().nameOverride, 'traceId');
    expect(path.nameOverride, isNull);
    expect(header.nameOverride, isNull);
    expect(path.rawName, 'pet_id');
    expect(header.rawName, 'X-Trace-Id');
  });

  test('referenced query override uses wire name and stays local', () {
    final component = QueryParameterObject(
      name: 'LimitParam',
      rawName: 'page_size',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: true,
      model: IntegerModel(context: context),
      encoding: QueryParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final firstAlias = QueryParameterAlias(
      name: 'LimitParam',
      parameter: component,
      context: context.push('first'),
      description: null,
    );
    final secondAlias = QueryParameterAlias(
      name: 'LimitParam',
      parameter: component,
      context: context.push('second'),
      description: null,
    );
    final firstOperation = <QueryParameter>{firstAlias};
    final secondOperation = <QueryParameter>{secondAlias};

    applier.applyQueryParameterOverrides(firstOperation, 'listItems', {
      'listItems.LimitParam': 'wrong',
      'listItems.page_size': 'size',
    });

    expect(firstOperation.single, isA<QueryParameterObject>());
    expect(firstOperation.single.resolve().nameOverride, 'size');
    expect(firstOperation.single.resolve().rawName, 'page_size');
    expect(component.nameOverride, isNull);
    expect(secondOperation.single, same(secondAlias));
    expect(secondOperation.single.resolve().nameOverride, isNull);
  });

  test('component keys do not match parameter overrides', () {
    final component = QueryParameterObject(
      name: 'LimitParam',
      rawName: 'page_size',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: true,
      model: IntegerModel(context: context),
      encoding: QueryParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final alias = QueryParameterAlias(
      name: 'LimitParam',
      parameter: component,
      context: context,
      description: null,
    );
    final parameters = <QueryParameter>{alias};

    applier.applyQueryParameterOverrides(parameters, 'listItems', {
      'listItems.LimitParam': 'size',
    });

    expect(parameters.single, same(alias));
    expect(parameters.single.resolve().nameOverride, isNull);
  });

  test('existing parameter names take precedence over config', () {
    final inline = QueryParameterObject(
      name: null,
      rawName: 'status',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: true,
      model: StringModel(context: context),
      encoding: QueryParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: 'petStatus',
    );
    final component = QueryParameterObject(
      name: 'LimitParam',
      rawName: 'page_size',
      description: null,
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      allowReserved: false,
      explode: true,
      model: IntegerModel(context: context),
      encoding: QueryParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: 'pageSize',
    );
    final alias = QueryParameterAlias(
      name: 'LimitParam',
      parameter: component,
      context: context,
      description: null,
    );
    final parameters = <QueryParameter>{inline, alias};

    applier.applyQueryParameterOverrides(parameters, 'listItems', {
      'listItems.status': 'state',
      'listItems.page_size': 'size',
    });

    expect(inline.nameOverride, 'petStatus');
    expect(parameters, contains(alias));
    expect(alias.resolve().nameOverride, 'pageSize');
  });

  test('referenced cookie override stays local', () {
    final component = CookieParameterObject(
      name: 'SessionParam',
      rawName: 'session_id',
      description: null,
      isRequired: false,
      isDeprecated: false,
      explode: true,
      model: StringModel(context: context),
      encoding: CookieParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final alias = CookieParameterAlias(
      name: 'SessionParam',
      parameter: component,
      context: context,
      description: null,
    );
    final parameters = <CookieParameter>{alias};

    applier.applyCookieParameterOverrides(parameters, 'getItem', {
      'getItem.session_id': 'session',
    });

    expect(parameters.single, isA<CookieParameterObject>());
    expect(parameters.single.resolve().nameOverride, 'session');
    expect(component.nameOverride, isNull);
  });

  test('shared query overrides are independent and preserve metadata', () {
    final shared = QueryParameterObject(
      name: 'LimitParameter',
      rawName: 'limit',
      description: 'Maximum results',
      isRequired: true,
      isDeprecated: true,
      allowEmptyValue: true,
      allowReserved: true,
      explode: true,
      model: IntegerModel(context: context),
      encoding: QueryParameterEncoding.form,
      context: context,
      examples: const [
        Example(name: null, summary: null, description: null, value: 10),
      ],
      defaultValue: 10,
      nameOverride: null,
    );
    final first = <QueryParameter>{shared};
    final second = <QueryParameter>{shared};
    final third = <QueryParameter>{shared};
    const overrides = {'first.limit': 'maxResults', 'second.limit': 'count'};

    applier
      ..applyQueryParameterOverrides(first, 'first', overrides)
      ..applyQueryParameterOverrides(second, 'second', overrides)
      ..applyQueryParameterOverrides(third, 'third', overrides);

    final renamed = first.single.resolve();
    expect(renamed.nameOverride, 'maxResults');
    expect(second.single.resolve().nameOverride, 'count');
    expect(third.single.resolve().nameOverride, isNull);
    expect(shared.nameOverride, isNull);
    expect(identical(first.single, shared), isFalse);
    expect(identical(second.single, shared), isFalse);
    expect(identical(third.single, shared), isTrue);
    expect(renamed.name, 'LimitParameter');
    expect(renamed.rawName, 'limit');
    expect(renamed.description, 'Maximum results');
    expect(renamed.isRequired, isTrue);
    expect(renamed.isDeprecated, isTrue);
    expect(renamed.allowEmptyValue, isTrue);
    expect(renamed.allowReserved, isTrue);
    expect(renamed.explode, isTrue);
    expect(renamed.encoding, QueryParameterEncoding.form);
    expect(renamed.model, same(shared.model));
    expect(renamed.context, context);
    expect(renamed.examples.single.value, 10);
    expect(renamed.defaultValue, 10);
  });

  test('shared inline path overrides use the wire name and stay local', () {
    final shared = PathParameterObject(
      name: null,
      rawName: 'pet_id',
      description: 'Pet identifier',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: IntegerModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final first = <PathParameter>{shared};
    final second = <PathParameter>{shared};
    final third = <PathParameter>{shared};
    const overrides = {'first.pet_id': 'id', 'second.pet_id': 'animalId'};

    applier
      ..applyPathParameterOverrides(second, 'second', overrides)
      ..applyPathParameterOverrides(first, 'first', overrides)
      ..applyPathParameterOverrides(third, 'third', overrides);

    expect(first.single.resolve().nameOverride, 'id');
    expect(second.single.resolve().nameOverride, 'animalId');
    expect(third.single.resolve().nameOverride, isNull);
    expect(shared.nameOverride, isNull);
    expect(identical(first.single, shared), isFalse);
    expect(identical(second.single, shared), isFalse);
    expect(identical(third.single, shared), isTrue);
    expect(first.single.resolve().rawName, 'pet_id');
    expect(first.single.resolve().isRequired, isTrue);
    expect(first.single.resolve().description, 'Pet identifier');
  });

  test('shared header overrides use the wire name and stay local', () {
    final shared = RequestHeaderObject(
      name: 'RequestToken',
      rawName: 'X-Request-Token',
      description: 'Request token',
      isRequired: false,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: HeaderParameterEncoding.simple,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final first = <RequestHeader>{shared};
    final second = <RequestHeader>{shared};
    final third = <RequestHeader>{shared};
    const overrides = {
      'first.X-Request-Token': 'token',
      'second.X-Request-Token': 'requestId',
    };

    applier
      ..applyHeaderOverrides(first, 'first', overrides)
      ..applyHeaderOverrides(second, 'second', overrides)
      ..applyHeaderOverrides(third, 'third', overrides);

    expect(first.single.resolve().nameOverride, 'token');
    expect(second.single.resolve().nameOverride, 'requestId');
    expect(third.single.resolve().nameOverride, isNull);
    expect(shared.nameOverride, isNull);
    expect(identical(first.single, shared), isFalse);
    expect(identical(second.single, shared), isFalse);
    expect(identical(third.single, shared), isTrue);
    expect(first.single.resolve().rawName, 'X-Request-Token');
    expect(first.single.resolve().description, 'Request token');
  });

  test(
    'overridden aliases retain their descriptions and component defaults',
    () {
      final shared = QueryParameterObject(
        name: 'LimitParameter',
        rawName: 'limit',
        description: 'Component description',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: IntegerModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: 10,
        nameOverride: null,
      );
      final alias = QueryParameterAlias(
        name: 'LimitAlias',
        parameter: shared,
        context: context,
        description: 'Operation description',
      );
      final first = <QueryParameter>{alias};
      final second = <QueryParameter>{alias};

      NameOverrideApplier().applyQueryParameterOverrides(first, 'first', {
        'first.limit': 'maxResults',
      });

      expect(first.single.resolve().nameOverride, 'maxResults');
      expect(first.single.resolve().description, 'Operation description');
      expect(first.single.resolve().defaultValue, 10);
      expect(second.single.resolve().nameOverride, isNull);
      expect(shared.description, 'Component description');
      expect(shared.nameOverride, isNull);
      expect(identical(second.single, alias), isTrue);
    },
  );

  test('shared cookie overrides stay local to each operation', () {
    final shared = CookieParameterObject(
      name: 'SessionParameter',
      rawName: 'session_id',
      description: 'Session identifier',
      isRequired: false,
      isDeprecated: false,
      explode: true,
      model: StringModel(context: context),
      encoding: CookieParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
      nameOverride: null,
    );
    final first = <CookieParameter>{shared};
    final second = <CookieParameter>{shared};
    final third = <CookieParameter>{shared};
    const overrides = {
      'first.session_id': 'session',
      'second.session_id': 'sessionToken',
    };

    applier
      ..applyCookieParameterOverrides(first, 'first', overrides)
      ..applyCookieParameterOverrides(second, 'second', overrides)
      ..applyCookieParameterOverrides(third, 'third', overrides);

    expect(first.single.resolve().nameOverride, 'session');
    expect(second.single.resolve().nameOverride, 'sessionToken');
    expect(third.single.resolve().nameOverride, isNull);
    expect(shared.nameOverride, isNull);
    expect(first.single, isNot(same(shared)));
    expect(second.single, isNot(same(shared)));
    expect(third.single, same(shared));
    expect(first.single.resolve().rawName, 'session_id');
    expect(first.single.resolve().description, 'Session identifier');
  });
}
