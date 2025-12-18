import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/contact_importer.dart';
import 'package:tonik_parse/src/external_documentation_importer.dart';
import 'package:tonik_parse/src/license_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/operation_importer.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/src/request_parameter_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';
import 'package:tonik_parse/src/response_importer.dart';
import 'package:tonik_parse/src/security_scheme_importer.dart';
import 'package:tonik_parse/src/server_importer.dart';

class Importer {
  Importer({this.contentTypes = const {}});

  /// Maps media type strings to ContentType for parsing request/response bodies.
  /// Default includes 'application/json' only. Add custom JSON-like media types
  /// (e.g., 'application/hal+json': ContentType.json) via configuration.
  final Map<String, core.ContentType> contentTypes;

  core.ApiDocument import(Map<String, dynamic> fileContent) {
    final openApiObject = OpenApiObject.fromJson(fileContent);

    final modelImporter = ModelImporter(openApiObject);
    final securitySchemeImporter = SecuritySchemeImporter(openApiObject);
    final responseHeaderImporter = ResponseHeaderImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
    );
    final responseImporter = ResponseImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
      headerImporter: responseHeaderImporter,
      contentTypes: contentTypes,
    );
    final parameterImporter = RequestParameterImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
    );
    final requestBodyImporter = RequestBodyImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
      contentTypes: contentTypes,
    );
    final operationImporter = OperationImporter(
      openApiObject: openApiObject,
      parameterImporter: parameterImporter,
      responseImporter: responseImporter,
      requestBodyImporter: requestBodyImporter,
      securitySchemeImporter: securitySchemeImporter,
    );

    modelImporter.import();
    responseHeaderImporter.import();
    responseImporter.import();
    parameterImporter.import();
    requestBodyImporter.import();
    securitySchemeImporter.import();
    operationImporter.import();

    return core.ApiDocument(
      title: openApiObject.info.title,
      version: openApiObject.info.version,
      description: openApiObject.info.description,
      contact: ContactImporter(openApiObject: openApiObject).import(),
      license: LicenseImporter(openApiObject: openApiObject).import(),
      termsOfService: openApiObject.info.termsOfService,
      externalDocs: ExternalDocumentationImporter(
        openApiObject: openApiObject,
      ).import(),
      models: modelImporter.models,
      responseHeaders: responseHeaderImporter.headers,
      servers: ServerImporter(openApiObject: openApiObject).import(),
      operations: operationImporter.operations,
      responses: responseImporter.responses,
      requestHeaders: parameterImporter.headers,
      queryParameters: parameterImporter.queryParameters,
      pathParameters: parameterImporter.pathParameters,
      requestBodies: requestBodyImporter.requestBodies,
    );
  }
}
