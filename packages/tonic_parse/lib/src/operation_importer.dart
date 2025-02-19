import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart' as core;
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model/operation.dart';

class OperationImporter {
  OperationImporter({required this.openApiObject});

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['paths']);

  final OpenApiObject openApiObject;
  final log = Logger('OperationImporter');

  late Set<core.TaggedOperations> _operations;

  Set<core.TaggedOperations> get taggedOperations =>
      _operations.where((to) => to.operations.isNotEmpty).toSet();

  void import() {
    _operations = {
      if (openApiObject.tags != null)
        ...openApiObject.tags!.map(
          (tag) => core.TaggedOperations(
            tagName: tag.name,
            tagDescription: tag.description,
            operations: {},
          ),
        ),
      core.TaggedOperations(
        tagName: null,
        tagDescription: null,
        operations: {},
      ),
    };

    for (final MapEntry(key: path, value: pathItem)
        in openApiObject.paths.entries) {
      final context = rootContext.push(path);

      if (pathItem.ref != null) {
        log.warning(
          'Ignoring reference to ${pathItem.ref} of path $path. '
          'Feature not supported.',
        );
      }

      if (pathItem.servers?.isNotEmpty ?? false) {
        log.warning('Ignoring servers of path $path. Feature not supported.');
      }

      _handleOperation(pathItem.get, context);
      _handleOperation(pathItem.put, context);
      _handleOperation(pathItem.post, context);
      _handleOperation(pathItem.delete, context);
      _handleOperation(pathItem.patch, context);
      _handleOperation(pathItem.head, context);
      _handleOperation(pathItem.options, context);
      _handleOperation(pathItem.trace, context);
    }
  }

  void _handleOperation(Operation? operation, core.Context context) {
    if (operation == null) return;

    final stringTags = operation.tags ?? [];
    final operationsToAdd = _operations
        .where((t) => stringTags.any((tag) => tag == t.tagName))
        .toList();

    if (operationsToAdd.isEmpty) {
      operationsToAdd.add(_operations.firstWhere((to) => to.tagName == null));
    }

    final coreOperation = core.Operation(
      operationId: operation.operationId,
      context: context,
    );

    for (final to in operationsToAdd) {
      to.operations.add(coreOperation);
    }
  }
}
