# Evaluation Reference — Verdict Format & Thresholds

Reference document for the orchestrator when rendering the evaluation verdict after the four specialist reviewers + test runner complete (Step 4d). This is NOT an agent prompt — you (the orchestrator) use this as a checklist.

## Verdict Format

After merging findings from the four specialist reviewers and reading the test runner's report, render the verdict in this format:

```
## Build & Test Results
(from tonik-test-runner)
- Analysis (`fvm dart analyze`): PASS/FAIL
- Unit tests (tonik_core): PASS/FAIL (N passed, M failed)
- Unit tests (tonik_parse): PASS/FAIL
- Unit tests (tonik_generate): PASS/FAIL
- Unit tests (tonik_util): PASS/FAIL
- Unit tests (tonik): PASS/FAIL
- Integration tests: PASS/FAIL/SKIPPED
- Patch coverage: N% (files below 90% listed)

## Sprint Contract
(from tonik-contract-verifier — full table)
| # | Criterion | Layer | Status | Evidence | Notes |
|---|---|---|---|---|---|
| ... |
Contract: X / Y criteria PASS

## Per-Reviewer Findings
### tonik-code-reviewer
- Critical: N | Important: N | Minor: N
### tonik-error-reviewer
- Critical: N | Important: N | Minor: N
### tonik-scope-reviewer
- Critical: N | Important: N | Minor: N
(tonik-contract-verifier output is the table above)

## Merged Findings (deduped, severity-ordered)
### Critical (must fix)
1. [reviewer(s)] [file:line] Description
   Why: ...
   Fix: ...

### Important (must fix to PASS)
1. [reviewer(s)] [file:line] Description

### Minor (acknowledge, may defer)
1. [reviewer(s)] [file:line] Description

## Generator's Phase 5 Cleanup Summary
- `/simplify`: 1–3 bullets, or "no findings"
- `/security-review`: 1–3 bullets, or "no findings"

## Overall Verdict: PASS / FAIL

## Feedback for Next Iteration
(Only if FAIL — numbered list, ordered by severity. This becomes the "Prior-iteration findings" input for the next iteration's generator AND all four reviewers.)
```

## Severity Classification

When in doubt, classify higher. Reviewers report findings at confidence ≥ 80; do not downgrade these to nitpicks during the merge.

**Critical (blocks PASS):**
- Any test suite or integration test fails
- Analysis produces errors
- Patch coverage below 90%
- `Code.scope` usage (forbidden)
- `refer()` calls without package URLs
- `DartEmitter` used inside generator helper methods
- String interpolation mixed with `refer()` calls
- `.toString()` used for parameter encoding
- AnyModel encoding falls back instead of throwing
- Generated code produces invalid Dart
- Missing entire test categories the issue requires
- OpenAPI spec compliance violations in parser code
- Tests using fragments instead of full method bodies (e.g., `contains('.lock')`, `contains('IList')`)
- Tests using bare `contains()` without `collapseWhitespace()` for generated code
- Tests using string matching where object introspection should be used (e.g., `contains('IList')` on emitted type instead of `field.type.symbol == 'IList'`)
- Tests using bare `true` / `false` instead of `isTrue` / `isFalse`
- Tests with unformatted expected/actual (no `DartFormatter`)
- Infrastructure / script changes bundled into a feature PR (scope creep)
- Stale cross-package references (e.g., generator calling a removed parser helper)

**Important (blocks PASS):**
- Incomplete test coverage within a category
- Confusing design that doesn't cause bugs
- Analysis warnings
- Missing context in `EncodingException` / `FormatException` messages
- Unjustified out-of-scope file changes

**Minor:** Style, naming, documentation. ≤ 3 acknowledged minors are tolerable in a PASS verdict.

## Passing Threshold

ALL of the following must hold:
- ALL sprint contract criteria PASS (`tonik-contract-verifier` table reports `Y / Y`)
- Analysis passes with zero issues
- All unit test suites pass
- Integration tests PASS or SKIPPED (only SKIPPED if no generator/parser/model/util changes)
- Patch coverage >= 90%
- ZERO critical findings (after dedupe)
- ZERO important findings (after dedupe)
- ≤ 3 minor findings, each acknowledged

If any of these fails, the iteration is FAIL — compose feedback for the next iteration and continue the loop.

## Regression Table (iteration 2+)

Each reviewer emits its own regression table for findings in its scope. When merging:
- Roll the per-reviewer regression rows into a single merged table grouped by prior finding
- Mark the prior finding `Fixed` only if every reviewer that flagged it agrees it's fixed
- A `Partial` from any reviewer keeps the merged status as `Partial`

```
## Regression Table (iteration 2+)
| Prior finding | Status | Evidence | Reported by |
|---|---|---|---|
| brief recap | Fixed / Partial / Not addressed / N/A | file:line or rationale | reviewer name(s) |
```
