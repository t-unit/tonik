# Code Review Checklist

Reference checklist for reviewing code produced by the Generator agent. Focus on real bugs, CLAUDE.md violations, and architectural issues. Quality over quantity — only report findings you are confident about.

## Review Scope

Review the git diff and changed files. Focus only on changed/added code.

## What to Look For

**Architecture & Patterns:**
- Package boundary violations (e.g., `tonik_generate` importing from `tonik_parse`)
- Model changes in `tonik_core` that break downstream consumers
- Generator code using `Code.scope` (forbidden)
- `refer()` calls missing package URLs (even `dart:core` types need them)
- `DartEmitter` used inside generator methods (only allowed in main `generate` method)
- String interpolation mixed with `refer()` (incompatible — must use separate `Code` objects)
- Hand-written code where code_builder constructs should be used

**Bugs & Logic Errors:**
- Null dereference (`!` on nullable without prior check)
- Missing cases in switch/if-else chains
- Incorrect type mapping (e.g., wrong OpenAPI type → Dart type)
- Off-by-one errors in list/string operations
- Incorrect `$ref` resolution in parser code
- Generated code that would fail at runtime (invalid Dart syntax, missing imports)

**OpenAPI Spec Compliance (if touching parser code):**
- Schema parsing handles both 3.0 and 3.1 correctly
- Nullable handling correct for both `nullable: true` (3.0) and `type: ["string", "null"]` (3.1)
- Required vs optional fields handled correctly
- `$ref` resolution follows spec rules

**Testing Conventions (violations are CRITICAL — block PASS):**
- Tests MUST use full method body comparison, NEVER fragments (e.g., `contains('.lock')` or `contains('IList')` is a fragment — always compare the complete fromJson/toJson/equals method body)
- Tests MUST use `collapseWhitespace()` for generated code strings
- Tests MUST use `isTrue`/`isFalse`, not bare `true`/`false`
- No bare `contains()` without `collapseWhitespace()` for generated code
- Object introspection MUST be preferred over string testing where possible (e.g., check `field.type.symbol == 'IList'` instead of `contains('IList')` on an emitted string)
- Both expected and actual MUST be formatted with `DartFormatter` before comparison
- When a generator returns an Expression, it MUST be wrapped in a Method to produce a formattable body before comparing

## Confidence Scoring

Rate each finding 0-100. Only report findings scoring 80+:
- **90-100**: Will definitely cause a bug, analysis error, or invalid generated code
- **80-89**: Clear violation of project conventions with concrete impact

Do NOT report:
- Style preferences or nitpicks
- Pre-existing issues not introduced by this diff
- Potential issues that depend on specific inputs you cannot verify
- Suggestions that are "nice to have" but not wrong

## Output Format

For each finding:
```
[CONFIDENCE: N] [file:line] Brief description
  Why: Explanation of the concrete impact
  Fix: Specific change needed
```

Group by severity. If no high-confidence issues exist, say so explicitly.
