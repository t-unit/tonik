import 'package:logging/logging.dart';
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
  Importer({this.contentTypes = const {}, this.contentMediaTypes = const {}});

  /// Maps media type strings to ContentType for parsing request/response bodies.
  /// Default includes 'application/json' only. Add custom JSON-like media types
  /// (e.g., 'application/hal+json': ContentType.json) via configuration.
  final Map<String, core.ContentType> contentTypes;

  /// Maps contentMediaType values to SchemaContentType for content-encoded
  /// string schemas. When a schema has contentEncoding set, this config
  /// determines whether it generates StringModel (text) or BinaryModel
  /// (binary).
  /// If no match found, defaults to BinaryModel.
  final Map<String, core.SchemaContentType> contentMediaTypes;

  static final _log = Logger('Importer');

  core.ApiDocument import(Map<String, dynamic> fileContent) {
    final openApiObject = OpenApiObject.fromJson(fileContent);

    // Detect and log OpenAPI version (permissive, no validation)
    _detectAndLogVersion(openApiObject.openapi);

    final modelImporter = ModelImporter(
      openApiObject,
      contentMediaTypes: contentMediaTypes,
    );
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
      summary: openApiObject.info.summary,
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
      cookieParameters: parameterImporter.cookieParameters,
      requestBodies: requestBodyImporter.requestBodies,
    );
  }

  static void _detectAndLogVersion(String version) {
    if (version.startsWith('3.0')) {
      _log.info('Parsing OpenAPI 3.0.x specification (version: $version)');
    } else if (version.startsWith('3.1')) {
      _log.info('Parsing OpenAPI 3.1.x specification (version: $version)');
    } else {
      _log.warning(
        'Unknown or unsupported OpenAPI version: $version - '
        'attempting to parse permissively',
      );
    }
  }
}
