# Project Instructions

## TDD Checkpoint Rule

**CRITICAL: When following a TDD workflow (as defined in plans), you MUST stop and wait for explicit user confirmation after writing tests and before writing any implementation code.** Do NOT proceed to implementation automatically. The workflow is:

1. Write tests.
2. Run tests to confirm they fail.
3. **STOP. Report results to the user and wait for their explicit go-ahead.**
4. Only after the user confirms, write the implementation.

This applies to every sub-plan checkpoint, every TDD cycle, and any plan step that says "wait for confirmation" or "checkpoint". Never skip this step, even if the tests are clearly ready and the implementation seems obvious.

## Tool Usage Preferences

### LSP-First Code Navigation

When the task is semantic (finding a class, tracing usages, getting a method signature), prefer LSP tools over text search:

- **Finding where a symbol is defined** → `LSP goToDefinition` instead of grep
- **Finding all usages** → `LSP findReferences` instead of grep
- **Getting type info / docs** → `LSP hover` instead of reading the file
- **Getting a file's structure** → `LSP documentSymbol` instead of scanning the file
- **Checking errors after an edit** → `mcp__ide__getDiagnostics` first; only run `fvm dart analyze` when you need package-wide or monorepo-wide results, or when the edited file may not be open in VS Code

Grep and Glob remain appropriate for: string/comment/pattern search, file-name patterns, YAML/Markdown files, or when LSP returns no results.
