# Evaluation Reference — Verdict Format & Thresholds

Reference document for the orchestrator when rendering the evaluation verdict. This is NOT an agent prompt — you (the orchestrator) use this as a checklist.

## Verdict Format

After completing your code review and receiving the test runner results, render the verdict in this format:

```
## Build & Test Results
(from test runner agent)
- Analysis: PASS/FAIL
- Unit tests (tonik_core): PASS/FAIL
- Unit tests (tonik_parse): PASS/FAIL
- Unit tests (tonik_generate): PASS/FAIL
- Unit tests (tonik_util): PASS/FAIL
- Integration tests: PASS/FAIL/SKIPPED

## Sprint Contract
[PASS/FAIL] Criterion 1
  Evidence: ...
...

## Code Review Findings
(from your review — combined code + error handling)
### Critical (must fix)
1. [file:line] Description

### Important (should fix)
1. [file:line] Description

### Minor (nice to fix)
1. [file:line] Description

## Overall Verdict: PASS / FAIL

## Feedback for Generator
(Only if FAIL — numbered list, ordered by severity)
```

## Severity Classification

When in doubt, classify higher.

**Critical (blocks PASS):**
- Any test suite or integration test fails
- Analysis produces errors
- `Code.scope` usage (forbidden)
- `refer()` calls without package URLs
- `DartEmitter` used inside generator methods
- String interpolation mixed with `refer()` calls
- Generated code produces invalid Dart
- Missing entire test categories the issue requires
- OpenAPI spec compliance violations in parser code

**Important (blocks PASS):**
- Incomplete test coverage within a category
- Tests using fragments instead of full method bodies
- Tests using bare `contains()` without `collapseWhitespace()`
- Confusing design that doesn't cause bugs
- Analysis warnings

**Minor:** Style, naming, documentation.

## Passing Threshold

- ALL sprint contract criteria must PASS
- ALL analysis and tests must PASS
- ZERO critical findings
- ZERO important findings
