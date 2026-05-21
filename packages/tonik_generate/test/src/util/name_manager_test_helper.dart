import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Builds a fresh [NameManager] suitable for tests that exercise expression
/// builders without going through the full prime/import flow. Production
/// code paths must construct their own [NameManager] via the parser; this
/// helper lives in the test tree only.
NameManager testNameManager() => NameManager(
  generator: NameGenerator(),
  stableModelSorter: StableModelSorter(),
);
