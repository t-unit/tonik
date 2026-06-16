import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/model_file_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

const _package = 'pkg';

ModelFileGenerator _buildGenerator() {
  final nameGenerator = NameGenerator();
  final stableModelSorter = StableModelSorter();
  final nameManager = NameManager(
    generator: nameGenerator,
    stableModelSorter: stableModelSorter,
  );

  return ModelFileGenerator(
    classGenerator: ClassGenerator(
      nameManager: nameManager,
      package: _package,
    ),
    enumGenerator: EnumGenerator(nameManager: nameManager),
    anyOfGenerator: AnyOfGenerator(
      nameManager: nameManager,
      package: _package,
      stableModelSorter: stableModelSorter,
    ),
    oneOfGenerator: OneOfGenerator(
      nameManager: nameManager,
      package: _package,
      stableModelSorter: stableModelSorter,
    ),
    typedefGenerator: TypedefGenerator(
      nameManager: nameManager,
      package: _package,
    ),
    allOfGenerator: AllOfGenerator(
      nameManager: nameManager,
      package: _package,
      stableModelSorter: stableModelSorter,
    ),
  );
}

String _modelDir(String outputDirectory) =>
    path.joinAll([outputDirectory, _package, 'lib', 'src', 'model']);

void main() {
  group('ModelFileGenerator.writeOne', () {
    late Directory tempDir;
    late Context ctx;
    late ModelFileGenerator generator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('model_file_generator_');
      ctx = Context.initial();
      generator = _buildGenerator();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('writes ClassModel file with a class declaration', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'user.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class '));
    });

    test('writes EnumModel<int> file with an enum declaration', () {
      final model = EnumModel<int>(
        isDeprecated: false,
        name: 'Priority',
        values: {
          const EnumEntry(value: 1),
          const EnumEntry(value: 2),
        },
        isNullable: false,
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'priority.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('enum '));
    });

    test('writes EnumModel<String> file with an enum declaration', () {
      final model = EnumModel<String>(
        isDeprecated: false,
        name: 'Color',
        values: {
          const EnumEntry(value: 'red'),
          const EnumEntry(value: 'blue'),
        },
        isNullable: false,
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'color.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('enum '));
    });

    test('writes AnyOfModel file with a class declaration', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: ctx)),
          (discriminatorValue: null, model: IntegerModel(context: ctx)),
        },
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(
        path.join(_modelDir(tempDir.path), 'flexible_model.dart'),
      );
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class '));
    });

    test('writes OneOfModel file with a class declaration', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: null, model: StringModel(context: ctx)),
          (discriminatorValue: null, model: IntegerModel(context: ctx)),
        },
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'choice.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class '));
    });

    test('writes AllOfModel file with a class declaration', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: {
          StringModel(context: ctx),
          IntegerModel(context: ctx),
        },
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'combined.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('class '));
    });

    test('writes AliasModel file with a typedef declaration', () {
      final model = AliasModel(
        name: 'UserId',
        model: StringModel(context: ctx),
        context: ctx,
        examples: const [],
        defaultValue: null,
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'user_id.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('typedef '));
    });

    test('writes ListModel file with a typedef declaration', () {
      final model = ListModel(
        name: 'UserList',
        content: ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          examples: const [],
        ),
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'user_list.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('typedef '));
    });

    test('writes MapModel file with a typedef declaration', () {
      final model = MapModel(
        name: 'UserMap',
        valueModel: ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: ctx,
          examples: const [],
        ),
        context: ctx,
        examples: const [],
      );

      generator.writeOne(
        model,
        outputDirectory: tempDir.path,
        package: _package,
      );

      final file = File(path.join(_modelDir(tempDir.path), 'user_map.dart'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('typedef '));
    });

    test('skips unsupported model subtype without writing any file', () {
      generator.writeOne(
        StringModel(context: ctx),
        outputDirectory: tempDir.path,
        package: _package,
      );

      final dir = Directory(_modelDir(tempDir.path));
      expect(
        dir.existsSync() ? dir.listSync() : const <FileSystemEntity>[],
        isEmpty,
      );
    });
  });

  group('ModelFileGenerator.writeFiles', () {
    late Directory tempDir;
    late Context ctx;
    late ModelFileGenerator generator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('model_file_generator_');
      ctx = Context.initial();
      generator = _buildGenerator();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('writes one file per dispatched model in apiDocument', () {
      final apiDoc = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        description: 'Test',
        models: <Model>{
          ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: ctx,
            examples: const [],
          ),
          AliasModel(
            name: 'UserId',
            model: StringModel(context: ctx),
            context: ctx,
            examples: const [],
            defaultValue: null,
          ),
        },
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: _package,
      );

      expect(
        File(path.join(_modelDir(tempDir.path), 'user.dart')).existsSync(),
        isTrue,
      );
      expect(
        File(path.join(_modelDir(tempDir.path), 'user_id.dart')).existsSync(),
        isTrue,
      );
    });
  });
}
