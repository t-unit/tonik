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

    applier
      ..applyPathParameterOverrides({path}, 'getPet', {'getPet.pet_id': 'id'})
      ..applyHeaderOverrides(
        {header},
        'getPet',
        {'getPet.X-Trace-Id': 'traceId'},
      );

    expect(path.nameOverride, 'id');
    expect(header.nameOverride, 'traceId');
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
}
