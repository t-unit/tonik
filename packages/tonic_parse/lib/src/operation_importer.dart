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

      _addOperation('get', pathItem.get, context);
      _addOperation('put', pathItem.put, context);
      _addOperation('post', pathItem.post, context);
      _addOperation('delete', pathItem.delete, context);
      _addOperation('patch', pathItem.patch, context);
      _addOperation('head', pathItem.head, context);
      _addOperation('options', pathItem.options, context);
      _addOperation('trace', pathItem.trace, context);
    }
  }

  void _addOperation(
    String method,
    Operation? operation,
    core.Context context,
  ) {
    if (operation == null) return;

    final tags = operation.tags
        ?.map((name) => validTags.firstWhereOrNull((tag) => tag.name == name))
        .nonNulls
        .toSet();

    operations.add(
      core.Operation(
        operationId: operation.operationId,
        context: context.push(method),
        tags: tags ?? {},
      ),
    );
  }
}
