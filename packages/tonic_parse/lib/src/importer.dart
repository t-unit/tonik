import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model_importer.dart';
import 'package:tonic_parse/src/operation_importer.dart';
import 'package:tonic_parse/src/request_parameter_importer.dart';
import 'package:tonic_parse/src/response_header_importer.dart';
import 'package:tonic_parse/src/response_importer.dart';
import 'package:tonic_parse/src/server_importer.dart';

class Importer {
  ApiDocument import(Map<String, dynamic> fileContent) {
    final openApiObject = OpenApiObject.fromJson(fileContent);

    final modelImporter = ModelImporter(openApiObject);
    final responseHeaderImporter = ResponseHeaderImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
    );
    final responseImporter = ResponseImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
      headerImporter: responseHeaderImporter,
    );
    final operationImporter = OperationImporter(openApiObject: openApiObject);
    final parameterImporter = RequestParameterImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
    );

    modelImporter.import();
    responseHeaderImporter.import();
    responseImporter.import();
    parameterImporter.import();

    operationImporter.import();

    return ApiDocument(
      title: openApiObject.info.title,
      version: openApiObject.info.version,
      description: openApiObject.info.description,
      models: modelImporter.models,
      responseHeaders: responseHeaderImporter.headers,
      servers: ServerImporter(openApiObject: openApiObject).import(),
      operations: operationImporter.operations,
      responses: responseImporter.responses,
      requestHeaders: parameterImporter.headers,
      queryParameters: parameterImporter.queryParameters,
    );
  }
}
