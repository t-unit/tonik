import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/path_generator.dart';

void main() {
  late PathGenerator generator;
  late Context context;
  late DartEmitter emitter;
  late NameManager nameManager;
  late NameGenerator nameGenerator;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = PathGenerator(
      nameManager: nameManager,
      package: 'api',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  test('returns path without parameters when no path parameters exist', () {
    final operation = Operation(
      operationId: 'getUsers',
      context: context,
      summary: 'Get users',
      description: 'Gets a list of users',
      tags: const {},
      isDeprecated: false,
      path: '/users',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      responses: const {},
      securitySchemes: const {},
    );

    const expectedMethod = '''
        List<String> _path() {
          return [r'users'];
        }
      ''';

    final method = generator.generatePathMethod(operation, []);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(method.requiredParameters, isEmpty);
    expect(method.optionalParameters, isEmpty);
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('adds parameters when path parameters exist', () {
    final pathParam = PathParameterObject(
      name: 'userId',
      rawName: 'userId',
      description: 'User ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUser',
      context: context,
      summary: 'Get user',
      description: 'Gets a user by ID',
      tags: const {},
      isDeprecated: false,
      path: '/users/{userId}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'userId', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(method.optionalParameters, hasLength(1));
    expect(method.optionalParameters.first.name, 'userId');
    expect(method.optionalParameters.first.type?.symbol, 'String');
    expect(method.optionalParameters.first.named, isTrue);
    expect(method.optionalParameters.first.required, isTrue);
  });

  test('encodes path parameters with simple style (default)', () {
    final pathParam = PathParameterObject(
      name: 'ids',
      rawName: 'ids',
      description: 'User IDs',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: ListModel(
        context: context,
        content: StringModel(context: context),
      ),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUsers',
      context: context,
      summary: 'Get users',
      description: 'Gets users by IDs',
      tags: const {},
      isDeprecated: false,
      path: '/users/{ids}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          return [r'users', ids.toSimple(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'ids', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('encodes path parameters with label style', () {
    final pathParam = PathParameterObject(
      name: 'ids',
      rawName: 'ids',
      description: 'User IDs',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: ListModel(
        context: context,
        content: StringModel(context: context),
      ),
      encoding: PathParameterEncoding.label,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUsers',
      context: context,
      summary: 'Get users',
      description: 'Gets users by IDs',
      tags: const {},
      isDeprecated: false,
      path: '/users{ids}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          return [r'users', ids.toLabel(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'ids', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('encodes path parameters with matrix style', () {
    final pathParam = PathParameterObject(
      name: 'ids',
      rawName: 'ids',
      description: 'User IDs',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: ListModel(
        context: context,
        content: StringModel(context: context),
      ),
      encoding: PathParameterEncoding.matrix,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUsers',
      context: context,
      summary: 'Get users',
      description: 'Gets users by IDs',
      tags: const {},
      isDeprecated: false,
      path: '/users{ids}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          return [r'users', ids.toMatrix(r'ids', explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'ids', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test(
    'encodes matrix path parameter with nullable model using null check',
    () {
      final pathParam = PathParameterObject(
        name: 'status',
        rawName: 'status',
        description: 'Status filter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: AliasModel(
          name: 'NullableStatus',
          model: StringModel(context: context),
          context: context,
          isNullable: true,
        ),
        encoding: PathParameterEncoding.matrix,
        context: context,
      );

      final operation = Operation(
        operationId: 'getByStatus',
        context: context,
        summary: 'Get by status',
        description: 'Gets items by status',
        tags: const {},
        isDeprecated: false,
        path: '/items{status}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required NullableStatus status}) {
          return [r'items', status!.toMatrix(r'status', explode: false, allowEmpty: false, ), ];
        }
      ''';

      nameManager.prime(
        models: {pathParam.model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'status', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    },
  );

  test('encodes path parameters with explode=true', () {
    final pathParam = PathParameterObject(
      name: 'filter',
      rawName: 'filter',
      description: 'Filter object',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: true,
      model: ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      ),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getFilteredUsers',
      context: context,
      summary: 'Get filtered users',
      description: 'Gets users with filter',
      tags: const {},
      isDeprecated: false,
      path: '/users/{filter}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required AnonymousModel filter}) {
          return [r'users', filter.toSimple(explode: true, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'filter', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('encodes path parameters with allowEmpty and explode flags', () {
    final pathParam = PathParameterObject(
      name: 'filter',
      rawName: 'filter',
      description: 'Filter object',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: true,
      explode: true,
      model: ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      ),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getFilteredUsers',
      context: context,
      summary: 'Get filtered users',
      description: 'Gets users with filter',
      tags: const {},
      isDeprecated: false,
      path: '/users/{filter}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required AnonymousModel filter}) {
          return [r'users', filter.toSimple(explode: true, allowEmpty: true, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'filter', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('encodes multiple path parameters with different styles', () {
    final simpleParam = PathParameterObject(
      name: 'userId',
      rawName: 'userId',
      description: 'User ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final labelParam = PathParameterObject(
      name: 'type',
      rawName: 'type',
      description: 'User type',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.label,
      context: context,
    );

    final matrixParam = PathParameterObject(
      name: 'roles',
      rawName: 'roles',
      description: 'User roles',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: ListModel(
        context: context,
        content: StringModel(context: context),
      ),
      encoding: PathParameterEncoding.matrix,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUser',
      context: context,
      summary: 'Get user',
      description: 'Gets a user by ID, type and roles',
      tags: const {},
      isDeprecated: false,
      path: '/users/{userId}{type}{roles}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {simpleParam, labelParam, matrixParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String userId, required String type, required List<String> roles, }) {
          return [r'users', userId.toSimple(explode: false, allowEmpty: false, ), type.toLabel(explode: false, allowEmpty: false, ), roles.toMatrix(r'roles', explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'userId', parameter: simpleParam),
          (normalizedName: 'type', parameter: labelParam),
          (normalizedName: 'roles', parameter: matrixParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('encodes different model types with appropriate encoders', () {
    final enumModel = EnumModel(
      isDeprecated: false,
      context: context,
      values: {
        const EnumEntry(value: 'admin'),
        const EnumEntry(value: 'user'),
        const EnumEntry(value: 'guest'),
      },
      isNullable: false,
    );

    final classModel = ClassModel(
      isDeprecated: false,
      context: context,
      properties: const [],
    );

    final oneOfModel = OneOfModel(
      isDeprecated: false,
      context: context,
      models: {
        (discriminatorValue: 'string', model: StringModel(context: context)),
        (
          discriminatorValue: 'integer',
          model: IntegerModel(context: context),
        ),
      },
      name: 'OneOfValue',
      discriminator: 'type',
    );

    final enumParam = PathParameterObject(
      name: 'role',
      rawName: 'role',
      description: 'User role',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: enumModel,
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final classParam = PathParameterObject(
      name: 'filter',
      rawName: 'filter',
      description: 'Filter object',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: true,
      model: classModel,
      encoding: PathParameterEncoding.matrix,
      context: context,
    );

    final oneOfParam = PathParameterObject(
      name: 'id',
      rawName: 'id',
      description: 'User ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: oneOfModel,
      encoding: PathParameterEncoding.label,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUser',
      context: context,
      summary: 'Get user',
      description: 'Gets a user by complex parameters',
      tags: const {},
      isDeprecated: false,
      path: '/users/{role}/filter/{filter}/id/{id}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {enumParam, classParam, oneOfParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required AnonymousModel role, required AnonymousModel2 filter, required OneOfValue id, }) {
          return [r'users', role.toSimple(explode: false, allowEmpty: false, ), r'filter', filter.toMatrix(r'filter', explode: true, allowEmpty: false, ), r'id', id.toLabel(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'role', parameter: enumParam),
          (normalizedName: 'filter', parameter: classParam),
          (normalizedName: 'id', parameter: oneOfParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('encodes in correct order regardless of parameter order', () {
    final idParam = PathParameterObject(
      name: 'id',
      rawName: 'id',
      description: 'Image ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final animalIdParam = PathParameterObject(
      name: 'animal_id',
      rawName: 'animal_id',
      description: 'Animal ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getAnimalImage',
      context: context,
      summary: 'Get animal image',
      description: 'Gets a thumbnail of an animal image',
      tags: const {},
      isDeprecated: false,
      path: 'images/{id}/animals/{animal_id}/thumbs',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {animalIdParam, idParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String animalId, required String id, }) {
          return [r'images', id.toSimple(explode: false, allowEmpty: false, ), r'animals', animalId.toSimple(explode: false, allowEmpty: false, ), r'thumbs', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'animalId', parameter: animalIdParam),
          (normalizedName: 'id', parameter: idParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles repeated parameters in path correctly', () {
    final userParam = PathParameterObject(
      name: 'user',
      rawName: 'user',
      description: 'User ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUserPermissions',
      context: context,
      summary: 'Get user permissions',
      description: 'Gets permissions for a user',
      tags: const {},
      isDeprecated: false,
      path: 'users/{user}/permissions/{user}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {userParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String user}) {
          return [r'users', user.toSimple(explode: false, allowEmpty: false, ), r'permissions', user.toSimple(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'user', parameter: userParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles simple list of enums', () {
    final enumModel = EnumModel(
      isDeprecated: false,
      context: context,
      values: {
        const EnumEntry(value: 'RED'),
        const EnumEntry(value: 'GREEN'),
        const EnumEntry(value: 'BLUE'),
      },
      isNullable: false,
    );

    final listModel = ListModel(context: context, content: enumModel);

    final pathParam = PathParameterObject(
      name: 'colors',
      rawName: 'colors',
      description: 'List of colors',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: true,
      encoding: PathParameterEncoding.simple,
      model: listModel,
      context: context,
    );

    final operation = Operation(
      operationId: 'getByColors',
      context: context,
      summary: 'Get by colors',
      description: 'Gets data by colors',
      tags: const {},
      isDeprecated: false,
      path: '/data/{colors}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<AnonymousModel> colors}) {
          return [r'data', colors.map((e) => e.toSimple(explode: true, allowEmpty: false, )).toList().toSimple(explode: true, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'colors', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(method.optionalParameters.first.named, isTrue);
    expect(method.optionalParameters.first.required, isTrue);
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles nested list of class models', () {
    final innerModel = ClassModel(
      isDeprecated: false,
      context: context,
      properties: const [],
    );
    final innerListModel = ListModel(context: context, content: innerModel);
    final outerListModel = ListModel(context: context, content: innerListModel);

    final pathParam = PathParameterObject(
      name: 'matrix',
      rawName: 'matrix',
      description: 'Matrix of items',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: true,
      encoding: PathParameterEncoding.simple,
      model: outerListModel,
      context: context,
    );

    final operation = Operation(
      operationId: 'getMatrix',
      context: context,
      summary: 'Get matrix',
      description: 'Gets matrix data',
      tags: const {},
      isDeprecated: false,
      path: '/data/{matrix}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<List<AnonymousModel>> matrix}) {
          throw EncodingException('Simple encoding does not support lists with unsupported element types for path parameter matrix');
          return [r'data'];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'matrix', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(method.optionalParameters.first.named, isTrue);
    expect(method.optionalParameters.first.required, isTrue);
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles matrix encoding with list of strings', () {
    final listModel = ListModel(
      context: context,
      content: StringModel(context: context),
    );

    final pathParam = PathParameterObject(
      name: 'tags',
      rawName: 'tags',
      description: 'List of tags',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      encoding: PathParameterEncoding.matrix,
      model: listModel,
      context: context,
    );

    final operation = Operation(
      operationId: 'getByTags',
      context: context,
      summary: 'Get by tags',
      description: 'Gets data by tags',
      tags: const {},
      isDeprecated: false,
      path: '/data{tags}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<String> tags}) {
          return [r'data', tags.toMatrix(r'tags', explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'tags', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles matrix encoding with list of integers', () {
    final listModel = ListModel(
      context: context,
      content: IntegerModel(context: context),
    );

    final pathParam = PathParameterObject(
      name: 'ids',
      rawName: 'ids',
      description: 'List of IDs',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: true,
      encoding: PathParameterEncoding.matrix,
      model: listModel,
      context: context,
    );

    final operation = Operation(
      operationId: 'getByIds',
      context: context,
      summary: 'Get by IDs',
      description: 'Gets data by IDs',
      tags: const {},
      isDeprecated: false,
      path: '/data{ids}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<int> ids}) {
          return [r'data', ids.map<String>((e) => e.uriEncode(allowEmpty: false)).toList().toMatrix(r'ids', explode: true, allowEmpty: false, alreadyEncoded: true, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'ids', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles matrix encoding with list of enums', () {
    final enumModel = EnumModel(
      isDeprecated: false,
      context: context,
      values: {
        const EnumEntry(value: 'ACTIVE'),
        const EnumEntry(value: 'INACTIVE'),
        const EnumEntry(value: 'PENDING'),
      },
      isNullable: false,
    );

    final listModel = ListModel(context: context, content: enumModel);

    final pathParam = PathParameterObject(
      name: 'statuses',
      rawName: 'statuses',
      description: 'List of statuses',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: true,
      encoding: PathParameterEncoding.matrix,
      model: listModel,
      context: context,
    );

    final operation = Operation(
      operationId: 'getByStatuses',
      context: context,
      summary: 'Get by statuses',
      description: 'Gets data by statuses',
      tags: const {},
      isDeprecated: false,
      path: '/data{statuses}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<AnonymousModel> statuses}) {
          return [r'data', statuses.map<String>((e) => e.uriEncode(allowEmpty: false)).toList().toMatrix(r'statuses', explode: true, allowEmpty: false, alreadyEncoded: true, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'statuses', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test(
    'handles matrix encoding with list of class models throws at runtime',
    () {
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final listModel = ListModel(context: context, content: classModel);

      final pathParam = PathParameterObject(
        name: 'filters',
        rawName: 'filters',
        description: 'List of filters',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: PathParameterEncoding.matrix,
        model: listModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'getByFilters',
        context: context,
        summary: 'Get by filters',
        description: 'Gets data by filters',
        tags: const {},
        isDeprecated: false,
        path: '/data{filters}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required List<AnonymousModel> filters}) {
          return [r'data', throw EncodingException('Lists with complex content cannot be matrix-encoded'), ];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'filters', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expect(method, isA<Method>());
      expect(
        method.returns,
        TypeReference(
          (b) => b
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(refer('String', 'dart:core')),
        ),
      );
      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    },
  );

  test('handles matrix encoding with nested list throws at runtime', () {
    final innerListModel = ListModel(
      context: context,
      content: StringModel(context: context),
    );
    final outerListModel = ListModel(context: context, content: innerListModel);

    final pathParam = PathParameterObject(
      name: 'matrix',
      rawName: 'matrix',
      description: 'Nested list',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      encoding: PathParameterEncoding.matrix,
      model: outerListModel,
      context: context,
    );

    final operation = Operation(
      operationId: 'getByMatrix',
      context: context,
      summary: 'Get by matrix',
      description: 'Gets data by nested list',
      tags: const {},
      isDeprecated: false,
      path: '/data{matrix}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {pathParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required List<List<String>> matrix}) {
          throw EncodingException('Matrix encoding does not support arrays of objects or nested arrays for path parameter matrix');
          return [r'data'];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'matrix', parameter: pathParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('handles consecutive path parameters correctly', () {
    final param1 = PathParameterObject(
      name: 'integer',
      rawName: 'integer',
      description: 'Integer value',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: IntegerModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final param2 = PathParameterObject(
      name: 'string',
      rawName: 'string',
      description: 'String value',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final param3 = PathParameterObject(
      name: 'boolean',
      rawName: 'boolean',
      description: 'Boolean value',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: BooleanModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'testConsecutiveParams',
      context: context,
      summary: 'Test consecutive parameters',
      description: 'Tests path with consecutive parameters',
      tags: const {},
      isDeprecated: false,
      path: '/primitive/{integer}/{string}/{boolean}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {param1, param2, param3},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required int integer, required String string, required bool boolean, }) {
          return [r'primitive', integer.toSimple(explode: false, allowEmpty: false, ), string.toSimple(explode: false, allowEmpty: false, ), boolean.toSimple(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'integer', parameter: param1),
          (normalizedName: 'string', parameter: param2),
          (normalizedName: 'boolean', parameter: param3),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      method.returns,
      TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(refer('String', 'dart:core')),
      ),
    );
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('generates valid code when path segment contains single quote '
      'and no path parameters exist', () {
    final operation = Operation(
      operationId: 'getQuoted',
      context: context,
      summary: 'Get quoted',
      description: 'Path with single quote',
      tags: const {},
      isDeprecated: false,
      path: "/it's/here",
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: const {},
      cookieParameters: const {},
      responses: const {},
      securitySchemes: const {},
    );

    const expectedMethod = '''
        List<String> _path() {
          return [r"it's", r'here'];
        }
      ''';

    final method = generator.generatePathMethod(operation, []);

    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('concatenates literal suffix with simple parameter in same segment', () {
    final sidParam = PathParameterObject(
      name: 'Sid',
      rawName: 'Sid',
      description: 'Account SID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'fetchAccount',
      context: context,
      summary: 'Fetch account',
      description: 'Fetches an account by SID',
      tags: const {},
      isDeprecated: false,
      path: '/2010-04-01/Accounts/{Sid}.json',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {sidParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String sid}) {
          return [r'2010-04-01', r'Accounts', sid.toSimple(explode: false, allowEmpty: false, ) + r'.json', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'sid', parameter: sidParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('concatenates literal prefix with simple parameter in same segment', () {
    final idParam = PathParameterObject(
      name: 'id',
      rawName: 'id',
      description: 'Resource ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getResource',
      context: context,
      summary: 'Get resource',
      description: 'Gets a resource by prefixed ID',
      tags: const {},
      isDeprecated: false,
      path: '/resources/v1{id}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {idParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String id}) {
          return [r'resources', r'v1' + id.toSimple(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'id', parameter: idParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('concatenates literal prefix and suffix with simple parameter in same '
      'segment', () {
    final idParam = PathParameterObject(
      name: 'id',
      rawName: 'id',
      description: 'Resource ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getResource',
      context: context,
      summary: 'Get resource',
      description: 'Gets a resource with prefix and suffix',
      tags: const {},
      isDeprecated: false,
      path: '/resources/pre{id}suf',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {idParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String id}) {
          return [r'resources', r'pre' + id.toSimple(explode: false, allowEmpty: false, ) + r'suf', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'id', parameter: idParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test(
    'concatenates multiple simple parameters and literals in same segment',
    () {
      final aParam = PathParameterObject(
        name: 'a',
        rawName: 'a',
        description: 'First part',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final bParam = PathParameterObject(
        name: 'b',
        rawName: 'b',
        description: 'Second part',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getComposite',
        context: context,
        summary: 'Get composite',
        description: 'Gets a resource with multi-param mixed segment',
        tags: const {},
        isDeprecated: false,
        path: '/resources/{a}-{b}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {aParam, bParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required String a, required String b, }) {
          return [r'resources', a.toSimple(explode: false, allowEmpty: false, ) + r'-' + b.toSimple(explode: false, allowEmpty: false, ) + r'.json', ];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'a', parameter: aParam),
            (normalizedName: 'b', parameter: bParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    },
  );

  test('Twilio example: /2010-04-01/Accounts/{Sid}.json', () {
    final sidParam = PathParameterObject(
      name: 'Sid',
      rawName: 'Sid',
      description: 'Account SID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'fetchAccount',
      context: context,
      summary: 'Fetch account',
      description: 'Fetches an account by SID',
      tags: const {},
      isDeprecated: false,
      path: '/2010-04-01/Accounts/{Sid}.json',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {sidParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String sid}) {
          return [r'2010-04-01', r'Accounts', sid.toSimple(explode: false, allowEmpty: false, ) + r'.json', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'sid', parameter: sidParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('Shopify example: /admin/api/2020-10/products/{product_id}.json', () {
    final productIdParam = PathParameterObject(
      name: 'product_id',
      rawName: 'product_id',
      description: 'Product ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'deleteProduct',
      context: context,
      summary: 'Delete product',
      description: 'Deletes a product by ID',
      tags: const {},
      isDeprecated: false,
      path: '/admin/api/2020-10/products/{product_id}.json',
      method: HttpMethod.delete,
      headers: const {},
      queryParameters: const {},
      pathParameters: {productIdParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String productId}) {
          return [r'admin', r'api', r'2020-10', r'products', productId.toSimple(explode: false, allowEmpty: false, ) + r'.json', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'productId', parameter: productIdParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('label parameter with literal suffix emits separate list entries', () {
    final typeParam = PathParameterObject(
      name: 'type',
      rawName: 'type',
      description: 'Resource type',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.label,
      context: context,
    );

    final operation = Operation(
      operationId: 'getResource',
      context: context,
      summary: 'Get resource',
      description: 'Gets a resource by type',
      tags: const {},
      isDeprecated: false,
      path: '/resources/{type}.json',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {typeParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String type}) {
          return [r'resources', type.toLabel(explode: false, allowEmpty: false, ), r'.json', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'type', parameter: typeParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('matrix parameter with literal suffix emits separate list entries', () {
    final rolesParam = PathParameterObject(
      name: 'roles',
      rawName: 'roles',
      description: 'User roles',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.matrix,
      context: context,
    );

    final operation = Operation(
      operationId: 'getResource',
      context: context,
      summary: 'Get resource',
      description: 'Gets a resource by roles',
      tags: const {},
      isDeprecated: false,
      path: '/resources/{roles}.json',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {rolesParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String roles}) {
          return [r'resources', roles.toMatrix(r'roles', explode: false, allowEmpty: false, ), r'.json', ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'roles', parameter: rolesParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  test('pure literal segments are unchanged with parameters present', () {
    final idParam = PathParameterObject(
      name: 'id',
      rawName: 'id',
      description: 'User ID',
      isRequired: true,
      isDeprecated: false,
      allowEmptyValue: false,
      explode: false,
      model: StringModel(context: context),
      encoding: PathParameterEncoding.simple,
      context: context,
    );

    final operation = Operation(
      operationId: 'getUser',
      context: context,
      summary: 'Get user',
      description: 'Gets a user',
      tags: const {},
      isDeprecated: false,
      path: '/Accounts.json/users/{id}',
      method: HttpMethod.get,
      headers: const {},
      queryParameters: const {},
      pathParameters: {idParam},
      responses: const {},
      securitySchemes: const {},
      cookieParameters: const {},
    );

    const expectedMethod = '''
        List<String> _path({required String id}) {
          return [r'Accounts.json', r'users', id.toSimple(explode: false, allowEmpty: false, ), ];
        }
      ''';

    final pathParameters =
        <({String normalizedName, PathParameterObject parameter})>[
          (normalizedName: 'id', parameter: idParam),
        ];

    final method = generator.generatePathMethod(operation, pathParameters);

    expect(method, isA<Method>());
    expect(
      collapseWhitespace(method.accept(emitter).toString()),
      collapseWhitespace(expectedMethod),
    );
  });

  group('trailing slash preservation', () {
    test('preserves trailing slash for path without parameters '
        'by adding empty segment', () {
      final operation = Operation(
        operationId: 'listSpaces',
        context: context,
        summary: 'List spaces',
        description: 'Lists all spaces',
        tags: const {},
        isDeprecated: false,
        path: '/api/mobile/protected/spaces/',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = '''
          List<String> _path() {
            return [r'api', r'mobile', r'protected', r'spaces', r''];
          }
        ''';

      final method = generator.generatePathMethod(operation, []);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    });

    test('preserves trailing slash for path with parameters '
        'by adding empty segment after parameter', () {
      final pathParam = PathParameterObject(
        name: 'slug',
        rawName: 'slug',
        description: 'Keeper slug',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getKeeperBySlug',
        context: context,
        summary: 'Get keeper by slug',
        description: 'Gets a keeper by slug',
        tags: const {},
        isDeprecated: false,
        path: '/api/mobile/protected/spaces/keeper/{slug}/',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = '''
          List<String> _path({required String slug}) {
            return [r'api', r'mobile', r'protected', r'spaces', r'keeper', slug.toSimple(explode: false, allowEmpty: false, ), r'', ];
          }
        ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'slug', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    });

    test('does not add trailing segment for path without trailing slash '
        'and no parameters', () {
      final operation = Operation(
        operationId: 'getUsers',
        context: context,
        summary: 'Get users',
        description: 'Gets a list of users',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = '''
          List<String> _path() {
            return [r'users'];
          }
        ''';

      final method = generator.generatePathMethod(operation, []);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    });

    test('does not add trailing segment for path without trailing slash '
        'and with parameters', () {
      final pathParam = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getUser',
        context: context,
        summary: 'Get user',
        description: 'Gets a user by ID',
        tags: const {},
        isDeprecated: false,
        path: '/users/{userId}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = '''
          List<String> _path({required String userId}) {
            return [r'users', userId.toSimple(explode: false, allowEmpty: false, ), ];
          }
        ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'userId', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(method.accept(emitter).toString()),
        collapseWhitespace(expectedMethod),
      );
    });
  });

  group('throw-producing simple parameter with literal suffix', () {
    void expectMethodMatches(Method method, String expected) {
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    }

    test('MapModel with complex value type and literal suffix '
        'emits throw statement without concatenation', () {
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final mapModel = MapModel(
        context: context,
        valueModel: classModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map of complex values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Reproduces map+suffix bug',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, AnonymousModel> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with ListModel value type and literal suffix '
        'emits throw statement without concatenation', () {
      final listValueModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final mapModel = MapModel(
        context: context,
        valueModel: listValueModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map with list values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of list values with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, List<String>> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with OneOfModel value type and literal suffix '
        'emits throw statement (composite has mixed encoding shape)', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'StringOrInt',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              context: context,
              properties: const [],
            ),
          ),
        },
        context: context,
      );
      final mapModel = MapModel(
        context: context,
        valueModel: oneOfModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map with oneOf values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of oneOf values with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {pathParam.model, oneOfModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, StringOrInt> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with AllOfModel value type and literal suffix '
        'emits throw statement', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'CombinedObject',
        models: {
          ClassModel(
            isDeprecated: false,
            context: context,
            properties: const [],
          ),
        },
        context: context,
      );
      final mapModel = MapModel(
        context: context,
        valueModel: allOfModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map with allOf values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of allOf values with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {pathParam.model, allOfModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, CombinedObject> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with String value type and literal suffix '
        'still concatenates correctly (regression guard)', () {
      final mapModel = MapModel(
        context: context,
        valueModel: StringModel(context: context),
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map of string values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of strings with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/x/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, String> m}) {
          return [r'x', m.toSimple(explode: false, allowEmpty: false) + r'.json'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with AnyModel value type and literal suffix '
        'concatenates correctly (regression — AnyModel is supported)', () {
      final mapModel = MapModel(
        context: context,
        valueModel: AnyModel(context: context),
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map of any values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of any-typed values with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, Object?> m}) {
          return [
            r'r',
            m
                    .map(
                      (k, v) =>
                          MapEntry(k, encodeAnyValueToString(v, allowEmpty: false)),
                    )
                    .toSimple(explode: false, allowEmpty: false) +
                r'.json',
          ];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with OneOfModel of all-simple members and literal '
        'suffix emits throw (composite has shape simple but encoder rejects)',
        () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'StringOrIntSimple',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );
      final mapModel = MapModel(
        context: context,
        valueModel: oneOfModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map with all-simple oneOf values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of all-simple oneOf values with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {pathParam.model, oneOfModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, StringOrIntSimple> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with AllOfModel of all-simple members and literal '
        'suffix emits throw (composite has shape simple but encoder rejects)',
        () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'StringOnly',
        models: {
          StringModel(context: context),
        },
        context: context,
      );
      final mapModel = MapModel(
        context: context,
        valueModel: allOfModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map with all-simple allOf values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of all-simple allOf values with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {pathParam.model, allOfModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, StringOnly> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('AliasModel wrapping MapModel with complex value type and literal '
        'suffix emits throw statement without concatenation', () {
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final mapModel = MapModel(
        context: context,
        valueModel: classModel,
      );
      final aliasModel = AliasModel(
        name: 'MyMap',
        model: mapModel,
        context: context,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Aliased map of complex values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: aliasModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Aliased map with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {aliasModel, mapModel, classModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required MyMap m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('AliasModel wrapping ListModel of nested lists and literal '
        'suffix emits throw statement without concatenation', () {
      final innerListModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final listModel = ListModel(
        context: context,
        content: innerListModel,
      );
      final aliasModel = AliasModel(
        name: 'MyList',
        model: listModel,
        context: context,
      );

      final pathParam = PathParameterObject(
        name: 'l',
        rawName: 'l',
        description: 'Aliased list of nested lists',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: aliasModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Aliased list with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{l}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {aliasModel, listModel, innerListModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required MyList l}) {
          throw EncodingException('Simple encoding does not support lists with unsupported element types for path parameter l');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'l', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('matrix encoding nested arrays throw includes path parameter '
        'name', () {
      final innerListModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final outerListModel = ListModel(
        context: context,
        content: innerListModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Nested list',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: PathParameterEncoding.matrix,
        model: outerListModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Matrix nested list',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required List<List<String>> m}) {
          throw EncodingException('Matrix encoding does not support arrays of objects or nested arrays for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('matrix encoding with AliasModel-wrapped nested arrays uses '
        'rawName error message', () {
      final innerListModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final outerListModel = ListModel(
        context: context,
        content: innerListModel,
      );
      final aliasModel = AliasModel(
        name: 'NestedListAlias',
        model: outerListModel,
        context: context,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Alias-wrapped nested list',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: PathParameterEncoding.matrix,
        model: aliasModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Matrix alias-wrapped nested list',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required NestedListAlias m}) {
          throw EncodingException('Matrix encoding does not support arrays of objects or nested arrays for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('matrix encoding with alias-wrapped inner list still emits '
        'rawName error message', () {
      final innerListModel = ListModel(
        context: context,
        content: StringModel(context: context),
      );
      final innerAlias = AliasModel(
        name: 'InnerListAlias',
        model: innerListModel,
        context: context,
      );
      final outerListModel = ListModel(
        context: context,
        content: innerAlias,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'List with alias-wrapped inner list',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: PathParameterEncoding.matrix,
        model: outerListModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Matrix list with alias-wrapped inner list',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required List<InnerListAlias> m}) {
          throw EncodingException('Matrix encoding does not support arrays of objects or nested arrays for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('MapModel with complex value type without suffix '
        'also emits throw statement', () {
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final mapModel = MapModel(
        context: context,
        valueModel: classModel,
      );

      final pathParam = PathParameterObject(
        name: 'm',
        rawName: 'm',
        description: 'Map of complex values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Map of complex values without suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{m}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, AnonymousModel> m}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter m');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('NeverModel with literal suffix emits throw statement '
        'without concatenation', () {
      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'Never-typed path parameter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: NeverModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'NeverModel with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Never p}) {
          throw EncodingException('Simple encoding does not support never-typed values for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('BinaryModel with literal suffix emits throw statement '
        'without concatenation', () {
      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'Binary-typed path parameter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: BinaryModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'BinaryModel with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required TonikFile p}) {
          throw EncodingException('Simple encoding does not support binary values for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('ListModel<NeverModel> with literal suffix emits throw statement '
        'without concatenation', () {
      final listModel = ListModel(
        context: context,
        content: NeverModel(context: context),
      );

      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'List of never values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: listModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'List<NeverModel> with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required List<Never> p}) {
          throw EncodingException('Simple encoding does not support lists with unsupported element types for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('ListModel<BinaryModel> with literal suffix emits throw statement '
        'without concatenation', () {
      final listModel = ListModel(
        context: context,
        content: BinaryModel(context: context),
      );

      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'List of binary values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: listModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'List<BinaryModel> with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required List<TonikFile> p}) {
          throw EncodingException('Simple encoding does not support lists with unsupported element types for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('AliasModel(NeverModel) with literal suffix emits throw statement '
        'unwrapping at depth 1', () {
      final aliasModel = AliasModel(
        name: 'NeverAlias',
        model: NeverModel(context: context),
        context: context,
      );

      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'Aliased never value',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: aliasModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'AliasModel(NeverModel) with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {aliasModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required NeverAlias p}) {
          throw EncodingException('Simple encoding does not support never-typed values for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('AliasModel(AliasModel(NeverModel)) with literal suffix emits '
        'throw statement unwrapping at depth 2', () {
      final innerAlias = AliasModel(
        name: 'NeverInner',
        model: NeverModel(context: context),
        context: context,
      );
      final outerAlias = AliasModel(
        name: 'NeverOuter',
        model: innerAlias,
        context: context,
      );

      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'Doubly aliased never value',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: outerAlias,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'AliasModel(AliasModel(NeverModel)) with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {outerAlias, innerAlias},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required NeverOuter p}) {
          throw EncodingException('Simple encoding does not support never-typed values for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('AliasModel(AliasModel(MapModel(ClassModel))) with literal suffix '
        'emits throw statement unwrapping at depth 2', () {
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final mapModel = MapModel(
        context: context,
        valueModel: classModel,
      );
      final innerAlias = AliasModel(
        name: 'MapInner',
        model: mapModel,
        context: context,
      );
      final outerAlias = AliasModel(
        name: 'MapOuter',
        model: innerAlias,
        context: context,
      );

      final pathParam = PathParameterObject(
        name: 'p',
        rawName: 'p',
        description: 'Doubly aliased map of complex values',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: outerAlias,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'AliasModel(AliasModel(MapModel(ClassModel))) with suffix',
        tags: const {},
        isDeprecated: false,
        path: '/r/{p}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      nameManager.prime(
        models: {outerAlias, innerAlias, mapModel, classModel},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      const expectedMethod = '''
        List<String> _path({required MapOuter p}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter p');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'p', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('multi-parameter same-segment with valid prefix and throwing '
        'parameter emits throw without concatenation', () {
      final goodParam = PathParameterObject(
        name: 'good',
        rawName: 'good',
        description: 'Valid string parameter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final mapModel = MapModel(
        context: context,
        valueModel: classModel,
      );
      final badParam = PathParameterObject(
        name: 'badMap',
        rawName: 'badMap',
        description: 'Throw-producing map parameter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'Multi-parameter same-segment with throwing trailing',
        tags: const {},
        isDeprecated: false,
        path: '/r/{good}-{badMap}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {goodParam, badParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({
          required String good,
          required Map<String, AnonymousModel> badMap,
        }) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter badMap');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'good', parameter: goodParam),
            (normalizedName: 'badMap', parameter: badParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });

    test('rawName != name divergence uses rawName in error message', () {
      final classModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final mapModel = MapModel(
        context: context,
        valueModel: classModel,
      );

      final pathParam = PathParameterObject(
        name: 'mNorm',
        rawName: 'M-RAW',
        description: 'Map parameter with divergent rawName',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: mapModel,
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final operation = Operation(
        operationId: 'getR',
        context: context,
        summary: 'Get R',
        description: 'rawName divergence test',
        tags: const {},
        isDeprecated: false,
        path: '/r/{M-RAW}.json',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        responses: const {},
        securitySchemes: const {},
        cookieParameters: const {},
      );

      const expectedMethod = '''
        List<String> _path({required Map<String, AnonymousModel> mNorm}) {
          throw EncodingException('Simple encoding does not support map with complex value types for path parameter M-RAW');
          return [r'r'];
        }
      ''';

      final pathParameters =
          <({String normalizedName, PathParameterObject parameter})>[
            (normalizedName: 'mNorm', parameter: pathParam),
          ];

      final method = generator.generatePathMethod(operation, pathParameters);

      expectMethodMatches(method, expectedMethod);
    });
  });
}
