import 'package:code_builder/code_builder.dart';
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

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = PathGenerator(
      nameManager: nameManager,
      package: 'package:api/api.dart',
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
        (b) =>
            b
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          return [r'users', ids.toSimple(explode: false, allowEmpty: false), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          return [r'users', ids.toLabel(explode: false, allowEmpty: false), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          return [r'users', ids.toMatrix('ids', explode: false, allowEmpty: false, ), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required AnonymousModel filter}) {
          return [r'users', filter.toSimple(explode: true, allowEmpty: false), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required AnonymousModel filter}) {
          return [r'users', filter.toSimple(explode: true, allowEmpty: true), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required String userId, required String type, required List<String> roles, }) {
          return [r'users', userId.toSimple(explode: false, allowEmpty: false), type.toLabel(explode: false, allowEmpty: false), roles.toMatrix('roles', explode: false, allowEmpty: false, ), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required AnonymousModel role, required AnonymousModel2 filter, required OneOfValue id, }) {
          return [r'users', role.toSimple(explode: false, allowEmpty: false), r'filter', filter.toMatrix('filter', explode: true, allowEmpty: false, ), r'id', id.toLabel(explode: false, allowEmpty: false), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required String animalId, required String id, }) {
          return [r'images', id.toSimple(explode: false, allowEmpty: false), r'animals', animalId.toSimple(explode: false, allowEmpty: false), r'thumbs', ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required String user}) {
          return [r'users', user.toSimple(explode: false, allowEmpty: false), r'permissions', user.toSimple(explode: false, allowEmpty: false), ];
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
        (b) =>
            b
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

    final listModel = ListModel(
      context: context,
      content: enumModel,
    );

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
    );

    const expectedMethod = '''
        List<String> _path({required List<AnonymousModel> colors}) {
          return [r'data', colors.map((e) => e.toSimple(explode: true, allowEmpty: false)) .toList().toSimple(explode: true, allowEmpty: false), ];
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
        (b) =>
            b
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
    final innerListModel = ListModel(
      context: context,
      content: innerModel,
    );
    final outerListModel = ListModel(
      context: context,
      content: innerListModel,
    );

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
    );

    const expectedMethod = '''
        List<String> _path({required List<List<AnonymousModel>> matrix}) {
          throw EncodingException('Simple encoding does not support list with complex elements for path parameter matrix');
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required List<String> tags}) {
          return [r'data', tags.toMatrix('tags', explode: false, allowEmpty: false, ), ];
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required List<int> ids}) {
          return [r'data', ids.map((e) => e.uriEncode(allowEmpty: false)).toList().toMatrix('ids', explode: true, allowEmpty: false, alreadyEncoded: true, ), ];
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
        (b) =>
            b
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

    final listModel = ListModel(
      context: context,
      content: enumModel,
    );

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
    );

    const expectedMethod = '''
        List<String> _path({required List<AnonymousModel> statuses}) {
          return [r'data', statuses.map((e) => e.uriEncode(allowEmpty: false)).toList().toMatrix('statuses', explode: true, allowEmpty: false, alreadyEncoded: true, ), ];
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
        (b) =>
            b
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
      final listModel = ListModel(
        context: context,
        content: classModel,
      );

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
      );

      const expectedMethod = '''
        List<String> _path({required List<AnonymousModel> filters}) {
          return [r'data', filters.toMatrix('filters', explode: false, allowEmpty: false, ), ];
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
          (b) =>
              b
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
    final outerListModel = ListModel(
      context: context,
      content: innerListModel,
    );

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
    );

    const expectedMethod = '''
        List<String> _path({required List<List<String>> matrix}) {
          throw EncodingException('Matrix encoding does not support arrays of objects or nested arrays');
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
        (b) =>
            b
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
    );

    const expectedMethod = '''
        List<String> _path({required int integer, required String string, required bool boolean, }) {
          return [r'primitive', integer.toSimple(explode: false, allowEmpty: false), string.toSimple(explode: false, allowEmpty: false), boolean.toSimple(explode: false, allowEmpty: false), ];
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
        (b) =>
            b
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
}
