import 'dart:io';

import 'package:ruby_rails_api/ruby_rails_api.dart';
import 'package:tonik_util/tonik_util.dart';

CustomServer liveServer() {
  final ci = Platform.environment['CI']?.toLowerCase();
  if (ci == 'true' || ci == '1') {
    throw StateError('Live examples are on-demand only; CI is refused.');
  }
  final baseUrl = Platform.environment['TONIK_EXAMPLE_BASE_URL'];
  if (baseUrl == null || baseUrl.isEmpty) {
    throw StateError(
      'Use examples/run.sh or set TONIK_EXAMPLE_BASE_URL explicitly.',
    );
  }
  final uri = Uri.parse(baseUrl);
  if (uri.scheme != 'http' ||
      !{'127.0.0.1', 'localhost', '::1'}.contains(uri.host)) {
    throw StateError('The live example must use a local HTTP server.');
  }
  return CustomServer(baseUrl: baseUrl);
}

T success<T, R extends Object>(TonikResult<T, R> result) => switch (result) {
  TonikSuccess(:final value) => value,
  TonikError(:final error, :final type) => throw StateError('$type: $error'),
};
