import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/path_generator.dart';

void main() {
  group('PathGenerator.generatePathMethod', () {
    late PathGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

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
        requestBody: null,
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        requestBody: null,
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'users',
            simpleEncoder.encode(ids, explode: false, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          const labelEncoder = LabelEncoder();
          return [
            r'users',
            labelEncoder.encode(ids, explode: false, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required List<String> ids}) {
          const matrixEncoder = MatrixEncoder();
          return [
            r'users',
            matrixEncoder.encode(ids, explode: false, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        model: ClassModel(context: context, properties: const []),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required Anonymous filter}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'users',
            simpleEncoder.encode(filter.toJson(), explode: true, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        model: ClassModel(context: context, properties: const []),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required Anonymous filter}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'users',
            simpleEncoder.encode(filter.toJson(), explode: true, allowEmpty: true),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({
          required String userId,
          required String type,
          required List<String> roles,
        }) {
          const simpleEncoder = SimpleEncoder();
          const labelEncoder = LabelEncoder();
          const matrixEncoder = MatrixEncoder();
          return [
            r'users',
            simpleEncoder.encode(userId, explode: false, allowEmpty: false),
            labelEncoder.encode(type, explode: false, allowEmpty: false),
            matrixEncoder.encode(roles, explode: false, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes different model types with appropriate encoders', () {
      final enumModel = EnumModel(
        context: context,
        values: const {'admin', 'user', 'guest'},
        isNullable: false,
      );

      final classModel = ClassModel(context: context, properties: const []);

      final oneOfModel = OneOfModel(
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({
          required Anonymous role,
          required AnonymousModel filter,
          required OneOfValue id,
        }) {
          const simpleEncoder = SimpleEncoder();
          const matrixEncoder = MatrixEncoder();
          const labelEncoder = LabelEncoder();
          return [
            r'users',
            simpleEncoder.encode(role.toJson(), explode: false, allowEmpty: false),
            r'filter',
            matrixEncoder.encode(filter.toJson(), explode: true, allowEmpty: false),
            r'id',
            labelEncoder.encode(id.toJson(), explode: false, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required String animalId, required String id}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'images',
            simpleEncoder.encode(id, explode: false, allowEmpty: false),
            r'animals',
            simpleEncoder.encode(animalId, explode: false, allowEmpty: false),
            r'thumbs',
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required String user}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'users',
            simpleEncoder.encode(user, explode: false, allowEmpty: false),
            r'permissions',
            simpleEncoder.encode(user, explode: false, allowEmpty: false),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles simple list of enums', () {
      final enumModel = EnumModel(
        context: context,
        values: const {'RED', 'GREEN', 'BLUE'},
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required List<Anonymous> colors}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'data',
            simpleEncoder.encode(
              colors.map((e) => e.toJson()).toList(),
              explode: true,
              allowEmpty: false,
            ),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles nested list of class models', () {
      final innerModel = ClassModel(context: context, properties: const []);
      final innerListModel = ListModel(context: context, content: innerModel);
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
        requestBody: null,
      );

      const expectedMethod = '''
        List<String> _path({required List<List<Anonymous>> matrix}) {
          const simpleEncoder = SimpleEncoder();
          return [
            r'data',
            simpleEncoder.encode(
              matrix.map((e) => e.map((e) => e.toJson()).toList()).toList(),
              explode: true,
              allowEmpty: false,
            ),
          ];
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
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });
  });
}
