import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/class_generator.dart';
import 'package:tonic_generate/src/model/enum_generator.dart';
import 'package:tonic_generate/src/model/model_generator.dart';
import 'package:tonic_generate/src/model/one_of_generator.dart';
import 'package:tonic_generate/src/model/typedef_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

Future<void> generate({
  required ApiDocument apiDocument,
  required String outputDirectory,
  required String package,
}) async {
  final nameGenerator = NameGenerator();
  final nameManager = NameManager(generator: nameGenerator);

  final classGenerator = ClassGenerator(
    nameManager: nameManager,
    package: package,
  );
  final enumGenerator = EnumGenerator(
    nameManager: nameManager,
    package: package,
  );
  final oneOfGenerator = OneOfGenerator(
    nameManager: nameManager,
    package: package,
  );
  final typedefGenerator = TypedefGenerator(
    nameManager: nameManager,
    package: package,
  );

  final modelGenerator = ModelGenerator(
    classGenerator: classGenerator,
    enumGenerator: enumGenerator,
    oneOfGenerator: oneOfGenerator,
    typedefGenerator: typedefGenerator,
  );

  nameManager.prime(
    models: apiDocument.models,
    responses: apiDocument.responses,
    responseHeaders: apiDocument.responseHeaders,
    operations: apiDocument.operations,
    requestHeaders: apiDocument.requestHeaders,
    queryParameters: apiDocument.queryParameters,
    pathParameters: apiDocument.pathParameters,
    tags: apiDocument.operationsByTag.keys,
  );

  await modelGenerator.writeFiles(
    apiDocument: apiDocument,
    outputDirectory: outputDirectory,
  );
}
