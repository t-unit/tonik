// The integration scripts require the POSIX shell tools used on macOS/Linux.
@TestOn('linux || mac-os')
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory sourceRoot;
  late Directory temporary;
  late Directory checkout;
  late File eventLog;
  late List<String> expectedPackages;

  setUpAll(() async {
    final source = await Isolate.resolvePackageUri(
      Uri.parse('package:tonik/src/config/cli_config.dart'),
    );
    sourceRoot = File.fromUri(source!).parent;
    while (!File(
      path.join(sourceRoot.path, 'scripts', 'integration_package_utils.sh'),
    ).existsSync()) {
      final parent = sourceRoot.parent;
      if (parent.path == sourceRoot.path) {
        throw StateError('Cannot locate the integration scripts.');
      }
      sourceRoot = parent;
    }
  });

  setUp(() async {
    temporary = Directory.systemTemp.createTempSync('tonik_analysis_test_');
    checkout = Directory(path.join(temporary.path, 'checkout with spaces'))
      ..createSync();
    final scripts = Directory(path.join(checkout.path, 'scripts'))
      ..createSync();
    for (final name in [
      'integration_package_utils.sh',
      'analyze_integration_packages.sh',
      'test_current_integration.sh',
    ]) {
      File(path.join(sourceRoot.path, 'scripts', name))
          .copySync(path.join(scripts.path, name));
    }
    expectedPackages = [];
    for (var index = 0; index < 44; index++) {
      final fixture = 'fixture_${index.toString().padLeft(2, '0')}';
      for (final suffix in ['api', if (index < 40) 'test']) {
        final name = '${fixture}_$suffix';
        expectedPackages.add(name);
        Directory(path.join(checkout.path, 'integration_test', fixture, name))
            .createSync(recursive: true);
      }
    }
    expectedPackages.add('test_helpers');
    Directory(path.join(checkout.path, 'integration_test', 'test_helpers'))
        .createSync();
    eventLog = File(path.join(temporary.path, 'events'))..createSync();
    final bin = Directory(path.join(temporary.path, 'bin'))..createSync();
    final dart = File(path.join(bin.path, 'dart'))
      ..writeAsStringSync(_fakeDart.trimLeft());
    final chmod = await Process.run('chmod', ['+x', dart.path]);
    expect(chmod.exitCode, 0);
  });

  tearDown(() {
    temporary.deleteSync(recursive: true);
  });

  Future<ProcessResult> runScript({
    String script = 'test_current_integration.sh',
    List<String> arguments = const [],
    Map<String, String> environment = const {},
  }) {
    final inherited = Map<String, String>.of(Platform.environment)
      ..remove('INTEGRATION_ANALYSIS_JOBS');
    return Process.run(
      'bash',
      [path.join(checkout.path, 'scripts', script), ...arguments],
      workingDirectory: checkout.path,
      includeParentEnvironment: false,
      environment: {
        ...inherited,
        'PATH': '${path.join(temporary.path, 'bin')}:${inherited['PATH']}',
        'TONIK_TEST_EVENTS': eventLog.path,
        'TONIK_TEST_STATE': temporary.path,
        ...environment,
      },
    );
  }

  List<_Event> events() => eventLog.readAsLinesSync().map((line) {
    final fields = line.split('\t');
    return (event: fields[0], phase: fields[1], package: fields[2]);
  }).toList();

  void expectCompleteAnalysis(List<_Event> recorded, {required int workers}) {
    final started = recorded.where(
      (e) => e.event == 'start' && e.phase == 'analyze',
    );
    expect(started.map((e) => e.package), unorderedEquals(expectedPackages));
    var active = 0;
    var peak = 0;
    for (final event in recorded.where((e) => e.phase == 'analyze')) {
      active += event.event == 'start' ? 1 : -1;
      if (active > peak) peak = active;
      expect(active, inInclusiveRange(0, workers));
    }
    expect(active, 0);
    expect(peak, workers == 1 ? 1 : greaterThan(1));
    for (final package in expectedPackages) {
      final resolved = recorded.indexWhere(
        (e) => e.package == package && e.phase == 'pub' && e.event == 'end',
      );
      final analyzed = recorded.indexWhere(
        (e) =>
            e.package == package && e.phase == 'analyze' && e.event == 'start',
      );
      expect(resolved, greaterThanOrEqualTo(0));
      expect(analyzed, greaterThan(resolved));
    }
  }

  test(
    'local runner uses a rolling pool and waits for all 85 packages',
    () async {
      final result = await runScript(
        environment: {'TONIK_TEST_BLOCK_FIRST': '1'},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('packages=85 workers=4'));
      final recorded = events();
      expectCompleteAnalysis(recorded, workers: 4);
      final tests = recorded.where(
        (e) => e.phase == 'test' && e.event == 'start',
      );
      expect(
        tests.map((e) => e.package),
        unorderedEquals(
          expectedPackages.where((name) => name.endsWith('_test')),
        ),
      );
      expect(
        recorded.indexWhere((e) => e.phase == 'test'),
        greaterThan(recorded.lastIndexWhere((e) => e.phase == 'analyze')),
      );
    },
  );

  test('local runner honors the analysis worker override', () async {
    final result = await runScript(
      environment: {'INTEGRATION_ANALYSIS_JOBS': '2'},
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('packages=85 workers=2'));
    expectCompleteAnalysis(events(), workers: 2);
  });

  for (final backend in ['dio', 'http']) {
    test('CI analysis uses four workers by default for $backend', () async {
      final result = await runScript(
        script: 'analyze_integration_packages.sh',
        arguments: [backend],
        environment: {'TONIK_TEST_BLOCK_FIRST': '1'},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('backend=$backend packages=85 workers=4'));
      final recorded = events();
      expectCompleteAnalysis(recorded, workers: 4);
      expect(recorded.where((e) => e.phase == 'test'), isEmpty);
    });
  }

  test('CI analysis honors a single-worker override', () async {
    final result = await runScript(
      script: 'analyze_integration_packages.sh',
      arguments: ['http'],
      environment: {'INTEGRATION_ANALYSIS_JOBS': '1'},
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('backend=http packages=85 workers=1'));
    final recorded = events();
    expectCompleteAnalysis(recorded, workers: 1);
    expect(recorded.where((e) => e.phase == 'test'), isEmpty);
  });

  test(
    'all failures are reported after draining the complete package queue',
    () async {
      final result = await runScript(
        environment: {
          'TONIK_TEST_FAIL_PUB': 'fixture_00_test',
          'TONIK_TEST_FAIL_ANALYZE': 'test_helpers',
          'TONIK_TEST_EXIT_255': 'fixture_00_api',
        },
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('diagnostic:pub:fixture_00_test'));
      expect(result.stderr, contains('diagnostic:analyze:fixture_00_api'));
      expect(result.stderr, contains('diagnostic:analyze:test_helpers'));
      expect(result.stderr, contains('3/85 packages'));
      final recorded = events();
      expect(
        recorded.where((e) => e.phase == 'pub' && e.event == 'end').length,
        85,
      );
      expect(
        recorded
            .where((e) => e.phase == 'analyze' && e.event == 'end')
            .map((e) => e.package),
        unorderedEquals(
          expectedPackages.where((name) => name != 'fixture_00_test'),
        ),
      );
      expect(recorded.where((e) => e.phase == 'test'), isEmpty);
    },
  );

  for (final value in ['', '0', '-1', '1.5', 'many']) {
    test(
      'rejects invalid worker count "$value" before invoking Dart',
      () async {
        final result = await runScript(
          environment: {'INTEGRATION_ANALYSIS_JOBS': value},
        );
        expect(result.exitCode, 64);
        expect(result.stderr, contains('must be a positive integer'));
        expect(events(), isEmpty);
      },
    );
  }

  test(
    'a missing generated package still fails inventory validation',
    () async {
      Directory(
        path.join(
          checkout.path,
          'integration_test',
          'fixture_00',
          'fixture_00_api',
        ),
      ).deleteSync();
      final result = await runScript();
      expect(result.exitCode, 1);
      expect(
        result.stderr,
        contains('expected 44 generated and 40 test packages'),
      );
      expect(events(), isEmpty);
    },
  );

  test('a missing helper package fails before analysis or tests', () async {
    Directory(path.join(checkout.path, 'integration_test', 'test_helpers'))
        .deleteSync();
    final result = await runScript();
    expect(result.exitCode, 1);
    expect(
      result.stderr,
      contains('integration test helper package is missing'),
    );
    expect(events(), isEmpty);
  });
}

typedef _Event = ({String event, String phase, String package});

const _fakeDart = r'''
#!/usr/bin/env bash
set -euo pipefail
package="${PWD##*/}"
phase="$1"
case "$*" in
  'pub get'|'analyze --fatal-infos --fatal-warnings'|'test') ;;
  *) echo "Unexpected Dart command: $*" >&2; exit 99 ;;
esac
printf 'start\t%s\t%s\n' "$phase" "$package" >> "$TONIK_TEST_EVENTS"
if [ "$phase" = analyze ]; then
  : > "$TONIK_TEST_STATE/entered-$package"
  if [ "${TONIK_TEST_BLOCK_FIRST:-}" = 1 ] && [ "$package" = fixture_00_api ]; then
    # A batch scheduler cannot start package five while package one is blocked.
    attempts=0
    while [ ! -f "$TONIK_TEST_STATE/entered-fixture_04_api" ]; do
      attempts=$((attempts + 1))
      if [ "$attempts" -gt 400 ]; then
        echo 'The worker pool did not schedule the next package.' >&2
        exit 98
      fi
      sleep 0.01
    done
  fi
  # Only the initial jobs need a delay to expose overlapping workers.
  case "$package" in
    fixture_0[0-7]_api) sleep 0.02 ;;
  esac
fi
printf 'end\t%s\t%s\n' "$phase" "$package" >> "$TONIK_TEST_EVENTS"
echo "diagnostic:$phase:$package"
if [ "$phase" = pub ] && [ "$package" = "${TONIK_TEST_FAIL_PUB:-}" ]; then
  exit 7
fi
if [ "$phase" = analyze ] && [ "$package" = "${TONIK_TEST_FAIL_ANALYZE:-}" ]; then
  exit 3
fi
if [ "$phase" = analyze ] && [ "$package" = "${TONIK_TEST_EXIT_255:-}" ]; then
  exit 255
fi
''';
