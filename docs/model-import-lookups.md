# Model importer lookup optimization

## Scope and lookup semantics

The importer retains its insertion-ordered `Set<Model>`. All 21 repeated
name-search sites now use an importer-owned `Map<String, Set<Model>>`. Each
bucket follows the corresponding models' insertion order. Adding an already
registered object does not move it; removing and re-registering an object moves
it to the end, just as it does in the original model set.

The key intentionally remains the original schema name. The previous predicates
compared only `NamedModel.name`, including when called from component references,
`$defs` resolution, and inline contexts. They did not compare context or
`nameOverride`. Names themselves are immutable. A context-qualified key would
change existing resolution behavior; a single last-write-wins value would change
which duplicate is found.

`_registerModel` and `_removeModel` update both structures only when the model
set changes. Every importer registration and removal uses these helpers,
including temporary multi-type shell removal, `$ref` sibling replacements,
late imports through the public entry points, and finalized placeholders.
`import()` clears the index when it replaces the model set. Unresolved
placeholders remain outside both structures, as before. Shell population still
updates the same objects; the existing replacement paths and reference identities
are unchanged. Anonymous lookup returns before accessing the index.

### Existing reference-resolution issue (unchanged)

A component named `Value` takes precedence over a referenced `$defs/Value`.
Likewise, two different nested `$defs` paths ending in the same name can reuse
the first imported model. This is an existing context/name collision issue,
not a resolution change introduced or fixed by this optimization. Regression tests characterize them explicitly.
The existing `$defs` alias-shell path can leave earlier references holding an
updated shell while the set contains a distinct alias with the same target;
that identity behavior is also preserved.

## Verification

The focused suite contains 12 regression tests, all passing against both the
saved baseline importer and the candidate. It covers forward/repeated/recursive
references, shell identity and ordering, multi-type removal/restoration,
structural `$ref` replacement, `$defs` alias replacement, overlapping names,
bare-cycle duplicate placeholders, resolved recursive-map placeholders, old
shell re-registration, anonymous schemas, collection aliases, repeated imports,
late importer entry points, and missing/unsupported references.

Package validation:

| Package | Passing unit tests | Static analysis |
|---|---:|---|
| tonik_util | 1,555 | Clean |
| tonik_core | 319 | Clean |
| tonik_parse | 738 | Clean |
| tonik_generate | 3,223 | Clean |
| tonik | 97 | Clean |
| **Total** | **5,932** | **All five packages clean** |

The four repository commit-hook tests also pass. Analysis uses both
`--fatal-infos` and `--fatal-warnings`. The focused tests pass on both the
baseline and candidate, including the two cases added after the first package
suite run; the final parser suite was rerun with all 12 cases.

Dio generated-output comparison: all 67,269 files across 44 API packages are
byte-identical, with no added or removed paths. Baseline regeneration completed
for both Dio and HTTP. The candidate `melos run test-integration-all` run was
stopped during Dio generated-package analysis at the user's request to open the
PR immediately. Full integration validation and the candidate HTTP output
comparison are not complete. The standalone scaling benchmark is provided for
reproduction; its measurement run was stopped at the same request.

## Performance methodology

Baseline revision: `806a9d87300a5df6f73628123743e79dc5bc1fd6`.
Both variants use Dart 3.12.0 (Flutter 3.44.0's bundled SDK), macOS arm64, the same
resolved dependency lockfile, fixtures, and AOT executable build mode.
The baseline parser sources were saved before editing; separate package configs
allow baseline compilation without reverting the candidate worktree.

Cloudflare fixture SHA-256:
`7e3914c359649349b571eafd3579f1f0480115afc579464393343fa2ddd32bbe`.

The standalone `packages/tonik_parse/benchmark/import_benchmark.dart` accepts a
schema count or an OpenAPI JSON path. It excludes input construction/JSON file
decoding from the import timer, includes the complete `Importer.import` call,
and prints elapsed microseconds and the resulting model count. Logging is disabled
for this standalone benchmark. Synthetic inputs
contain N named classes, each with eight references and eight anonymous objects
containing anonymous string properties, producing 9N models. Compile once and
run fresh processes; timing thresholds are not part of unit tests.

Example:

```sh
dart compile exe packages/tonik_parse/benchmark/import_benchmark.dart -o /tmp/import-benchmark
/tmp/import-benchmark 1000
/tmp/import-benchmark integration_test/cloudflare/openapi.json
```

Complete-generation timing uses identical temporary CLI stopwatch instrumentation
around `Importer.import` and the entire CLI invocation body (load, import,
normalization, configuration, and generated file writes). It excludes AOT
compilation, dependency resolution, analysis, and test execution. The CLI keeps
its normal warning logging, uses the Dio backend, and has 16 generation workers. All integration fixture
regeneration, including the generation benchmark, goes through
`scripts/setup_integration_tests.sh`. A temporary executable wrapper alternates
saved baseline and candidate executables for Cloudflare in a scratch workspace,
without changing the fixtures being analyzed by the integration run. One pair
is a warm-up; the next three pairs provide the reported medians. Each invocation
is a fresh process, and both variants overwrite the same warmed output directory.
Run order alternates to reduce drift on the shared workstation, where other
analysis jobs are active. These wall-clock samples are workload measurements,
not isolated-hardware guarantees. Counter-instrumented
executables are separate and are never used for reported performance timings.
No instrumentation remains in production code.

### Full-set scan instrumentation

All 21 baseline named-search predicates were instrumented to count each examined
model. The candidate's shared lookup counts calls and immediate anonymous returns.
The only remaining direct model-set mutations are in the bookkeeping helpers and
the import reset; no full-set named-search predicates remain.

| Input | Models | Baseline name predicate evaluations | Of which anonymous | Candidate lookups | Immediate anonymous returns | Candidate full-set name scans |
|---|---:|---:|---:|---:|---:|---:|
| Synthetic N=1,000 | 9,000 | 85,004,000 | 80,000,000 | 26,000 | 16,000 | 0 |
| Cloudflare | 26,935 | 911,145,825 | 815,423,207 | 85,115 | 53,361 | 0 |

### Cloudflare complete generation (Dio)

Medians of three measured runs per variant, after one warm-up pair:

| Phase | Baseline median | Candidate median | Time reduction |
|---|---:|---:|---:|
| Import inside CLI | 14.311 s | 0.510 s | 96.44% |
| Complete generation | 76.134 s | 70.683 s | 7.16% |

Raw measured samples in seconds (rounds 1, 2, 3):

| Variant | Import samples | Complete-generation samples |
|---|---|---|
| baseline | 14.251863, 14.311473, 15.758488 | 78.342361, 75.442466, 76.134430 |
| candidate | 0.456655, 0.509875, 0.579690 | 72.332249, 65.343854, 70.683124 |

These measurements replace, rather than extrapolate from, the earlier
41-second import / 76-second generation observation. No analysis or test
execution speedup is claimed.
