import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

import 'operation_execution_test_support.dart';

void main() {
  late Directory packageRoot;

  setUpAll(() async {
    packageRoot = await prepareRuntimePackage(
      package: dioRuntimePackage,
      backend: TransportBackend.dio,
      probeAsset: path.join(
        operationTestDirectory,
        'support/dio_runtime_probe.dart.txt',
      ),
    );
  });
  tearDownAll(() => packageRoot.parent.deleteSync(recursive: true));

  for (final scenario in const [
    'encoding',
    'uri-encoding',
    'pre-cancel',
    'accessor',
    'in-flight-cancel',
    'cancel-response',
    'transport',
    'synchronous-cancel',
    'synchronous-transport',
    'future-error-stack',
    'unexpected-transport',
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
      'Dio runtime $scenario',
      () => expectRuntimeProbe(packageRoot, scenario),
    );
  }
}
