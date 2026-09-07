import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

void main() {
  test(
    'normalizes unconstrained allOf members before generating models',
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'unconstrained_allof_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final context = Context.initial();
      final anyValue = AllOfModel(
        name: 'AnyValue',
        models: [
          AnyModel(context: context),
          AnyModel(context: context),
        ],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final count = AllOfModel(
        name: 'Count',
        models: [
          IntegerModel(context: context),
          AnyModel(context: context),
        ],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final document = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {anyValue, count},
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

      await const Generator().generate(
        apiDocument: document,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final anyCode = File(
        path.join(tempDir.path, 'test_package/lib/src/model/any_value.dart'),
      ).readAsStringSync();
      final countCode = File(
        path.join(tempDir.path, 'test_package/lib/src/model/count.dart'),
      ).readAsStringSync();

      expect(anyCode, contains('typedef AnyValue = _i1.Object?;'));
      expect(countCode, contains('class Count'));
      expect(countCode, isNot(contains('final _i3.Object? object;')));
      expect(countCode, isNot(contains('object.currentEncodingShape')));
    },
  );
}
