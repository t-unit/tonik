import 'package:tonic_core/src/model/operation.dart';

class TaggedOperations {
  TaggedOperations({
    required this.tagName,
    required this.tagDescription,
    required this.operations,
  });

  final String? tagName;
  final String? tagDescription;
  final Set<Operation> operations;
}
