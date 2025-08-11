import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  group('Generator model files', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'generates files for class, enum, oneOf, anyOf, allOf, alias, list',
      () {
        final models = <Model>{
          ClassModel(name: 'User', properties: const [], context: ctx),
          EnumModel<String>(
            name: 'Status',
            values: const {'active'},
            isNullable: false,
            context: ctx,
          ),
          OneOfModel(
            name: 'Choice',
            models: {
              (discriminatorValue: null, model: StringModel(context: ctx)),
              (discriminatorValue: null, model: IntegerModel(context: ctx)),
            },
            discriminator: null,
            context: ctx,
          ),
          AnyOfModel(
            name: 'FlexibleModel',
            models: {
              (discriminatorValue: null, model: StringModel(context: ctx)),
              (discriminatorValue: null, model: IntegerModel(context: ctx)),
            },
            discriminator: null,
            context: ctx,
          ),
          AllOfModel(
            name: 'Many',
            models: {StringModel(context: ctx), IntegerModel(context: ctx)},
            context: ctx,
          ),
          AliasModel(
            name: 'UserId',
            model: StringModel(context: ctx),
            context: ctx,
          ),
          ListModel(
            name: 'UserList',
            content: ClassModel(
              name: 'User',
              properties: const [],
              context: ctx,
            ),
            context: ctx,
          ),
        };

        final apiDoc = ApiDocument(
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
          requestBodies: const {},
        );

        const packageName = 'test_package';
        const  Generator().generate(
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
  });
}
