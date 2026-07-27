import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';

TransportBackendGenerator transportBackendGeneratorFor(
  TransportBackend backend,
) => switch (backend) {
  TransportBackend.dio => const DioBackendGenerator(),
  TransportBackend.http => const HttpBackendGenerator(),
};
