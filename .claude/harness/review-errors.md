# Error & Failure Handling Checklist

Reference checklist for auditing error handling in code produced by the Generator agent. Find silent failures, inadequate error handling, and operations that can fail without anyone knowing.

## Review Process

Systematically enumerate every error handling location in the diff, then scrutinize each one.

### 1. Find All Error Handling Code

Locate in the changed files:
- Every `try-catch` block
- Every `?.` or `!` operator usage
- Every fallback/default value used on failure
- Every place where exceptions are caught but execution continues
- Every `throw` statement
- Every `assert` statement
- Every place where a parser encounters unexpected input

### 2. For Each Error Handler, Ask:

**Does the caller know what happened?**
- Is the error wrapped with context (e.g., `throw FormatException('parsing X: $details')`)?
- Does the caller get enough information to decide what to do?
- Or is the error swallowed, logged-and-forgotten, or replaced with a generic message?

**Can this operation silently fail?**
- If a map lookup returns null, is it handled?
- If a list is empty when expected non-empty, is it caught?
- If a `$ref` fails to resolve, does the parser signal this clearly?
- If generated code encounters invalid input at runtime, does it fail clearly?

**Is this error handling too broad?**
- Does the catch block catch more than it should (e.g., catching `Exception` when only `FormatException` is expected)?
- Could this hide an unrelated error?
- Should this be multiple handlers for different exception types?

### 3. For Generated Code, Ask:

**Does the generated code handle errors correctly?**
- Does generated deserialization code handle null/missing fields properly?
- Does generated serialization code handle edge cases (empty lists, null values)?
- Are encoding exceptions thrown with enough context to debug?
- Does the generated code match what `tonik_util` runtime helpers expect?

## Output Format

For each finding:
```
[SEVERITY: CRITICAL/HIGH/MEDIUM] [file:line]
  What: Description of the error handling issue
  Risk: What can go wrong at parse time or in generated code
  Fix: Specific change needed
```

**CRITICAL**: Silent failure that will cause incorrect code generation or runtime crashes
**HIGH**: Inadequate error handling that will make debugging difficult
**MEDIUM**: Missing context or overly broad handling that could hide issues

Only report findings you are confident about. If no issues exist, say so.
