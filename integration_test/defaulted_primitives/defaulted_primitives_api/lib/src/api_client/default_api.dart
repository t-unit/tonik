// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i3;

import 'package:defaulted_primitives_api/src/model/health_get200_body_model.dart'
    as _i5;
import 'package:defaulted_primitives_api/src/operation/health_check.dart'
    as _i2;
import 'package:defaulted_primitives_api/src/server/server.dart' as _i1;
import 'package:tonik_util/tonik_util.dart' as _i4;

class DefaultApi {
  DefaultApi(_i1.Server server) : _healthCheck = _i2.HealthCheck(server.dio);

  final _i2.HealthCheck _healthCheck;

  /// Health check
  _i3.Future<_i4.TonikResult<_i5.HealthGet200BodyModel>> healthCheck() async =>
      _healthCheck();
}
