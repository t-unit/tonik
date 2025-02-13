import 'package:tonic_core/tonic_core.dart';

class Operation {
  Operation({required this.operationId, required this.context});

  final String? operationId;
  final Context context;
}
