import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

import 'operation_execution_test_support.dart';

void main() {
  late Directory packageRoot;

  setUpAll(() async {
    packageRoot = await prepareRuntimePackage(
      package: httpRuntimePackage,
      backend: TransportBackend.http,
      probeAsset: path.join(
        operationTestDirectory,
        'support/http_runtime_probe.dart.txt',
      ),
    );
  });
  tearDownAll(() => packageRoot.parent.deleteSync(recursive: true));

  for (final scenario in const [
    'encoding',
    'uri-encoding',
    'pre-cancel',
    'accessor',
    'abort-cancelled',
    'abort-network',
    'client-exception',
    'timeout',
    'unexpected-send',
    'buffering',
    'decoding',
    'success',
    'void',
    'never',
    'nullable-never',
    'none',
    'multipart',
    'synchronous-forwarding',
  ]) {
    test(
      'HTTP runtime $scenario',
      () => expectRuntimeProbe(packageRoot, scenario),
    );
  }
}
