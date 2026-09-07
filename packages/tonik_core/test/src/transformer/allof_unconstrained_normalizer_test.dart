import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  const normalizer = AllOfNormalizer(normalizeSingleMembers: false);
  late Context context;
  late ApiDocument document;

  setUp(() {
    context = Context.initial();
    document = ApiDocument(
      title: 'Test API',
      version: '1.0.0',
      models: {},
      responseHeaders: {},
      requestHeaders: {},
      servers: {},
      operations: {},
      responses: {},
      queryParameters: {},
      pathParameters: {},
      cookieParameters: {},
      requestBodies: {},
    );
  });

  test('removes neutral members while retaining wrapper and member order', () {
    final integer = IntegerModel(context: context);
    final anyAlias = AliasModel(
      name: 'Anything',
      model: AnyModel(context: context),
      context: context,
      defaultValue: null,
      examples: const [],
    );
    final compound = AllOfModel(
      name: 'Count',
      models: [
        AnyModel(context: context),
        integer,
        anyAlias,
        integer,
      ],
      context: context,
      description: 'A count.',
      isDeprecated: false,
      examples: const [],
    );
    final singleton = AllOfModel(
      name: 'SingleCount',
      models: [integer],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    document.models = {compound, singleton};

    normalizer.apply(document);

    expect(document.models, {compound, singleton});
    expect(compound.models, [integer, integer]);
    expect(compound.description, 'A count.');
    expect(singleton.models, [integer]);
  });

  test('all-unconstrained aliases preserve metadata and shared references', () {
    final compound = AllOfModel(
      name: 'AnyValue',
      models: [
        AnyModel(context: context),
        AnyModel(context: context),
      ],
      context: context,
      description: 'Any JSON value.',
      nameOverride: 'JsonValue',
      isDeprecated: true,
      isReadOnly: true,
      isNullable: true,
      defaultValue: 7,
      examples: const [],
    );
    final map = MapModel(
      name: 'Values',
      valueModel: compound,
      context: context,
      examples: const [],
    );
    final holder = ClassModel(
      name: 'Holder',
      properties: [],
      additionalPropertiesPolicy: AllowedAdditionalProperties(
        valueModel: compound,
      ),
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final cookie = CookieParameterObject(
      name: 'ValueCookie',
      rawName: 'value',
      description: null,
      isRequired: false,
      isDeprecated: false,
      explode: true,
      model: compound,
      encoding: CookieParameterEncoding.form,
      context: context,
      examples: const [],
      defaultValue: null,
    );
    document.models = {map, holder, compound};
    document.cookieParameters.add(cookie);

    normalizer.apply(document);

    final alias = document.models.whereType<AliasModel>().single;
    expect(alias.model, isA<AnyModel>());
    expect(alias.name, 'AnyValue');
    expect(alias.nameOverride, 'JsonValue');
    expect(alias.description, 'Any JSON value.');
    expect(alias.isDeprecated, isTrue);
    expect(alias.isReadOnly, isTrue);
    expect(alias.isNullable, isTrue);
    expect(alias.defaultValue, 7);
    expect(map.valueModel, same(alias));
    expect(
      (holder.additionalPropertiesPolicy as AllowedAdditionalProperties)
          .valueModel,
      same(alias),
    );
    expect(cookie.model, same(alias));
  });

  test(
    'keeps explicit additionalProperties constraints on all-Any aliases',
    () {
      final policy = AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
      );
      final open = AllOfModel(
        name: 'Open',
        models: [AnyModel(context: context)],
        additionalPropertiesPolicy: policy,
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final closed = AllOfModel(
        name: 'Closed',
        models: [AnyModel(context: context)],
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      document.models = {open, closed};

      normalizer.apply(document);

      final openAlias = document.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Open',
      );
      final closedAlias = document.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Closed',
      );
      expect((openAlias.model as MapModel).valueModel, same(policy.valueModel));
      expect((closedAlias.model as MapModel).valueModel, isA<NeverModel>());
    },
  );

  test('accepts immutable oneOf and anyOf member lists', () {
    final oneOf = OneOfModel(
      name: 'Choice',
      models: const [],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    final anyOf = AnyOfModel(
      name: 'Alternatives',
      models: const [],
      context: context,
      isDeprecated: false,
      examples: const [],
    );
    document.models = {oneOf, anyOf};

    normalizer.apply(document);

    expect(document.models, {oneOf, anyOf});
    expect(oneOf.models, isEmpty);
    expect(anyOf.models, isEmpty);
  });

  test(
    'retains recursive additional-property references across repeated runs',
    () {
      final recursive = AllOfModel(
        name: 'Recursive',
        models: [AnyModel(context: context)],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      recursive.additionalPropertiesPolicy = AllowedAdditionalProperties(
        valueModel: recursive,
      );
      document.models = {recursive};

      normalizer.apply(document);

      expect(document.models.single, same(recursive));
      final map = recursive.models.single as MapModel;
      expect(map.valueModel, same(recursive));

      normalizer.apply(document);

      expect(document.models.single, same(recursive));
      expect(recursive.models.single, same(map));
      expect(map.valueModel, same(recursive));
    },
  );
}
