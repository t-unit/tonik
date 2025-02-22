import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

@immutable
class Operation {
  const Operation({
    required this.operationId,
    required this.context,
    required this.tags,
  });

  final Set<Tag> tags;

  final String? operationId;
  final Context context;
}
