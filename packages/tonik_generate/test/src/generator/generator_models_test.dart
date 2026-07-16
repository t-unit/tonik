import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator model files', () {
    late Directory tempDir;
    late Context ctx;

    ApiDocument documentWithModels(Set<Model> models) => ApiDocument(
      title: 'Test',
      version: '0.0.1',
      description: 'Test',
      models: models,
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

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'generates files for class, enum, oneOf, anyOf, allOf, alias, list',
      () async {
        final models = <Model>{
          ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: ctx,
            examples: const [],
          ),
          EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {const EnumEntry(value: 'active')},
            isNullable: false,
            context: ctx,
            examples: const [],
          ),
          OneOfModel(
            isDeprecated: false,
            name: 'Choice',
            models: {
              (discriminatorValue: null, model: StringModel(context: ctx)),
              (discriminatorValue: null, model: IntegerModel(context: ctx)),
            },
            context: ctx,
            examples: const [],
          ),
          AnyOfModel(
            isDeprecated: false,
            name: 'FlexibleModel',
            models: {
              (discriminatorValue: null, model: StringModel(context: ctx)),
              (discriminatorValue: null, model: IntegerModel(context: ctx)),
            },
            context: ctx,
            examples: const [],
          ),
          AllOfModel(
            isDeprecated: false,
            name: 'Many',
            models: {
              StringModel(context: ctx),
              IntegerModel(context: ctx),
            },
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
          ListModel(
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
          ),
        };

        final apiDoc = documentWithModels(models);

        const packageName = 'test_package';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: packageName,
        );

        final modelDir = path.join(
          tempDir.path,
          packageName,
          'lib',
          'src',
          'model',
        );
        expect(Directory(modelDir).existsSync(), isTrue);
        final expected = [
          'user.dart',
          'status.dart',
          'choice.dart',
          'flexible_model.dart',
          'many.dart',
          'user_id.dart',
          'user_list.dart',
        ];
        for (final f in expected) {
          expect(File(path.join(modelDir, f)).existsSync(), isTrue);
        }
      },
    );

    test('generates a valid file for an empty enum', () async {
      final apiDoc = documentWithModels({
        EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {},
          isNullable: false,
          context: ctx.pushAll(['components', 'schemas', 'Color']),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
          examples: const [],
        ),
      });

      const packageName = 'test_package';
      await const Generator().generate(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: packageName,
      );

      final generatedFile = File(
        path.join(
          tempDir.path,
          packageName,
          'lib',
          'src',
          'model',
          'color.dart',
        ),
      );
      expect(generatedFile.existsSync(), isTrue);
    });

    test(
      r'generates distinct files and imports for $-only name differences',
      () async {
        final singleDollarUser = ClassModel(
          isDeprecated: false,
          name: r'$User',
          properties: const [],
          context: ctx.pushAll(['components', 'schemas', r'$User']),
          examples: const [],
        );
        final doubleDollarUser = ClassModel(
          isDeprecated: false,
          name: r'$$User',
          properties: const [],
          context: ctx.pushAll(['components', 'schemas', r'$$User']),
          examples: const [],
        );
        final holder = ClassModel(
          isDeprecated: false,
          name: 'Holder',
          properties: [
            Property(
              name: 'first',
              model: singleDollarUser,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'second',
              model: doubleDollarUser,
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: ctx.pushAll(['components', 'schemas', 'Holder']),
          examples: const [],
        );
        final apiDoc = documentWithModels({
          singleDollarUser,
          doubleDollarUser,
          holder,
        });

        const packageName = 'test_package';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: packageName,
        );

        final modelDir = path.join(
          tempDir.path,
          packageName,
          'lib',
          'src',
          'model',
        );
        final generatedFiles = Directory(
          modelDir,
        ).listSync().whereType<File>().toList();
        final singleDollarFile = generatedFiles.singleWhere(
          (file) => file.readAsStringSync().contains(r'class $User'),
        );
        final doubleDollarFile = generatedFiles.singleWhere(
          (file) => file.readAsStringSync().contains(r'class $$User'),
        );

        expect(singleDollarFile.path, isNot(doubleDollarFile.path));

        final holderCode = File(
          path.join(modelDir, 'holder.dart'),
        ).readAsStringSync();
        expect(
          holderCode,
          contains(
            'package:$packageName/src/model/'
            '${path.basename(singleDollarFile.path)}',
          ),
        );
        expect(
          holderCode,
          contains(
            'package:$packageName/src/model/'
            '${path.basename(doubleDollarFile.path)}',
          ),
        );
      },
    );
  });
}
