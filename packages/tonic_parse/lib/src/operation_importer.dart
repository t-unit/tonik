import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart' as core;
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/operation.dart';
import 'package:tonic_parse/src/model/tag.dart';

class OperationImporter {
  OperationImporter({required this.openApiObject});

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['paths']);

  final OpenApiObject openApiObject;
  final log = Logger('OperationImporter');

  late Set<core.Operation> operations;
  late Set<core.Tag> validTags;

  void import() {
    validTags = {
      for (final tag in openApiObject.tags ?? <Tag>[])
        core.Tag(name: tag.name, description: tag.description),
    };

    operations = <core.Operation>{};

    for (final pathEntry in openApiObject.paths.entries) {
      final pathItem = pathEntry.value;
      final context = rootContext.push(pathEntry.key);

      _addOperation(pathItem.get, context, core.HttpMethod.get);
      _addOperation(pathItem.put, context, core.HttpMethod.put);
      _addOperation(pathItem.post, context, core.HttpMethod.post);
      _addOperation(pathItem.delete, context, core.HttpMethod.delete);
      _addOperation(pathItem.patch, context, core.HttpMethod.patch);
      _addOperation(pathItem.head, context, core.HttpMethod.head);
      _addOperation(pathItem.options, context, core.HttpMethod.options);
      _addOperation(pathItem.trace, context, core.HttpMethod.trace);
    }
  }

  void _addOperation(
    Operation? operation,
    core.Context context,
    core.HttpMethod httpMethod,
  ) {
    if (operation == null) return;

    final tags = operation.tags
        ?.map((name) => validTags.firstWhereOrNull((tag) => tag.name == name))
        .nonNulls
        .toSet();

    operations.add(
      core.Operation(
        method: httpMethod,
        operationId: operation.operationId,
        context: context.push(httpMethod.name),
        tags: tags ?? {},
        isDeprecated: operation.isDeprecated ?? false,
        summary: operation.summary,
        description: operation.description,
        headers: {},
        queryParameters: {},
        pathParameters: {},
      ),
    );
  }
}
