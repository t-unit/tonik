---
name: gen-eval
description: Run the generator-evaluator harness on a GitHub issue or a user-provided description — a generator agent builds, the orchestrator reviews directly, and a test runner verifies
---

# Generator-Evaluator Harness

Inspired by [Anthropic's harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps). A Generator agent builds the feature, then you (the orchestrator) review it directly — leveraging your full context, skill knowledge, and tool access. A Test Runner agent handles mechanical test execution in parallel.

## Invocation

Two modes:

- **Issue mode**: `/gen-eval <issue-number>` or `/gen-eval <issue-number> <max-iterations>`
- **Description mode**: `/gen-eval "<description>"` or `/gen-eval "<description>" <max-iterations>`

Default max iterations: 3.

**Mode detection:** If the first argument is a number, use issue mode. Otherwise, treat the entire first argument as a free-form task description (equivalent to a GitHub issue body).

## Harness Files

| File | Purpose |
|------|---------|
| `.claude/harness/generator.md` | Generator agent prompt template |
| `.claude/harness/evaluator.md` | Verdict format, severity classification, and passing threshold reference |
| `.claude/harness/review-code.md` | Code review checklist (bugs, architecture, spec parity) |
| `.claude/harness/review-errors.md` | Error handling checklist (silent failures, exception handling) |
| `.claude/harness/review-tests.md` | Test execution agent prompt (all tests, analysis, integration tests) |

**Why you review directly:** Your review is superior to sub-agents because you have full skill knowledge (code-builder, testing, openapi-spec, integration-tests), conversation history, and can read files on demand — not just the diff. Sub-agents start with fresh context and lose cross-pollination between code review and error review.

- **review-code.md**: Checklist you follow for bugs, architecture violations, and code_builder misuse
- **review-errors.md**: Checklist you follow for silent failures, unchecked operations, and exception handling
- **review-tests.md**: Agent prompt for the test runner — runs analysis, all unit tests, and integration tests

## Orchestration Steps

You (the orchestrator) execute these steps. Do NOT implement the feature yourself — you only coordinate.

### Step 0: Parse Arguments & Create Branch
- Detect mode (issue number vs. description)
- Extract max iterations (default 3)
- **Create the branch FIRST** — before reading any harness files:
  - **Issue mode:**
    ```sh
    git checkout main && git pull origin main
    git checkout -b <issue-number>-<short-description>
    ```
  - **Description mode:** Derive a short branch name by slugifying the first few words of the description (lowercase, hyphens, max ~40 chars):
    ```sh
    git checkout main && git pull origin main
    git checkout -b <slugified-description>
    ```
  This ensures all file reads below use the latest code from main.

### Step 1: Gather Context
Read all of the following in parallel:

1. **Task details**:
   - **Issue mode**: `gh issue view <number> --json title,body,labels`
   - **Description mode**: Use the provided description directly (no GitHub fetch needed)
2. **Prompt templates**: Read `.claude/harness/generator.md` and `.claude/harness/review-tests.md`
3. **Review checklists**: Read `.claude/harness/review-code.md`, `.claude/harness/review-errors.md`, `.claude/harness/evaluator.md`
4. **Project knowledge files** (to fill template placeholders):
   - `CLAUDE.md`
   - `.claude/skills/code-builder/SKILL.md`
   - `.claude/skills/testing/SKILL.md`
   - `.claude/skills/integration-tests/SKILL.md`
   - `.claude/skills/openapi-spec/SKILL.md`
5. **Existing code**: Identify what already exists for this feature so the generator knows its starting point.

### Step 2: Create Sprint Contract
Based on the task's acceptance criteria, write a numbered list of **concrete, testable criteria**. Each criterion must be binary (pass/fail) and verifiable by reading code or running tests.

**CRITICAL: 1:1 mapping from acceptance criteria.** Every acceptance criterion in the task MUST map to at least one contract item. Do not paraphrase or summarize — parse each criterion literally.

- **Issue mode**: The issue body typically contains explicit acceptance criteria — parse them literally.
- **Description mode**: The description may be less structured. Extract testable criteria from the description, and fill in obvious implied criteria (e.g., tests, analysis). If the description is vague, ask the user to clarify acceptance criteria before proceeding.

**Checklist before presenting the contract:**
- [ ] Every acceptance criterion from the task has a corresponding contract item (no lossy summarization)
- [ ] Every test category the task mentions (unit, integration) is an explicit criterion
- [ ] Test criteria are specific about coverage scope (which cases, which error conditions, which scenarios)
- [ ] There is a criterion for analysis passing (`fvm dart analyze`)
- [ ] If generator changes are involved, there is a criterion for integration tests passing
- [ ] There is a criterion for patch coverage >= 90% (`bash scripts/coverage.sh --diff main`)

Present the sprint contract to the user for approval before proceeding.

### Step 3: Compose Prompts
Fill the template placeholders in the generator prompt file:

| Placeholder | Source |
|---|---|
| `{{CLAUDE_MD}}` | Contents of `CLAUDE.md` |
| `{{SKILL_CODE_BUILDER}}` | Contents of code-builder `SKILL.md` (without frontmatter) |
| `{{SKILL_TESTING}}` | Contents of testing `SKILL.md` (without frontmatter) |
| `{{SKILL_INTEGRATION_TESTS}}` | Contents of integration-tests `SKILL.md` (without frontmatter) |
| `{{SKILL_OPENAPI_SPEC}}` | Contents of openapi-spec `SKILL.md` (without frontmatter) |
| `{{ISSUE_BODY}}` | Issue title + body from GitHub (issue mode) or user-provided description (description mode) |
| `{{SPRINT_CONTRACT}}` | The contract from Step 2 |
| `{{EVALUATOR_FEEDBACK}}` | "This is the first iteration. No prior feedback." (or actual feedback on subsequent iterations) |

Also compose the **test runner prompt** by reading `.claude/harness/review-tests.md` and replacing `{{REVIEW_CONTEXT}}` with: CLAUDE.md contents + sprint contract + task acceptance criteria (from issue or description). The test runner does not need the full diff or skill content — it runs mechanical tests.

### Step 4: Generator-Review Loop

For each iteration (1 to max_iterations):

#### 4a. Spawn Generator
- `subagent_type`: leave default (general-purpose)
- `prompt`: The composed generator prompt with all placeholders filled
- Do NOT use `isolation: "worktree"` — the generator works on the current branch
- Do NOT run in background — wait for completion

#### 4b. Spawn Test Runner in Background
Immediately after the generator finishes, spawn the test runner agent:
- `subagent_type`: leave default (general-purpose)
- `prompt`: The composed test runner prompt (review-tests.md with `{{REVIEW_CONTEXT}}` filled)
- `run_in_background: true` — this runs while you do the code review
- The test runner runs analysis, all unit tests, and integration tests (if applicable), and reports results.

#### 4c. You Review the Code (while tests run)
This is the most important step. You do this yourself — do NOT spawn sub-agents.

1. **Get the diff**: Run `git diff main` to see all changes. Note the list of changed files.
2. **Read changed files in full**: For each changed file, read it (not just the diff — you need surrounding context for judgment calls).
3. **Code review** — follow the checklist in `.claude/harness/review-code.md`:
   - Architecture & patterns (package boundaries, correct use of code_builder, refer() usage)
   - Bugs & logic errors (null handling, missing cases, incorrect parsing)
   - OpenAPI spec compliance (if touching parser code)
   - Testing conventions (full method bodies, collapseWhitespace, proper matchers)
4. **Error handling review** — follow the checklist in `.claude/harness/review-errors.md`:
   - Find every error handler in the diff, scrutinize each one
   - Check: does the caller know? Can it silently fail? Is it too broad?
5. **Sprint contract check** — for each contract criterion:
   - Verify by reading code (does the implementation satisfy it?)
   - Mark PASS or FAIL with specific evidence
   - Re-read the task acceptance criteria word by word — flag anything the contract missed
6. **Holistic review** — step back and think:
   - Design coherence: do the pieces make sense together?
   - Requirements completeness: does the implementation deliver everything the task asked for?
   - What would a senior reviewer send back?

#### 4d. Wait for Test Runner, Render Verdict
Wait for the test runner agent to complete. Combine your code review findings with the test results.

Use the verdict format from `.claude/harness/evaluator.md`:
- Severity classification (Critical / Important / Minor)
- Passing threshold: ALL contract criteria PASS, ALL tests PASS, ZERO critical findings, <= 3 important findings

If **PASS**: Break the loop. Proceed to Step 5.
If **FAIL**: Compose a numbered feedback list ordered by severity. Update `{{EVALUATOR_FEEDBACK}}` in the generator prompt. Continue to next iteration.

#### 4e. Report to User
After each iteration, show a brief summary:
```
Iteration N/M: [PASS/FAIL]
- Contract: X/Y criteria passed
- Critical findings: N
- Key issues: (brief list)
```

If max iterations reached without PASS, report to user with the remaining issues.

### Step 5: Finalize & PR Review Loop
On PASS from Step 4:

1. **Show the user a summary** of what was built (files created/modified, key design decisions).
2. **Commit and create a draft PR automatically** — do not ask. Follow standard PR workflow (commit, push, `gh pr create --draft`).
3. **Run `/pr-review-toolkit:review-pr`** on the new PR. This launches specialized review agents (code-reviewer, silent-failure-hunter, test-analyzer, type-design-analyzer, comment-analyzer) that provide a second layer of scrutiny.
4. **If the PR review finds critical or important issues:**
   - Compose a numbered feedback list from the PR review findings (same format as evaluator feedback in Step 4).
   - Spawn a generator agent with the feedback, the sprint contract, and the list of findings. The generator fixes the issues — you do NOT write code yourself.
   - Review the generator's fixes (read the diff, verify each finding is addressed).
   - Commit and push the fixes.
   - Run `/pr-review-toolkit:review-pr` again.
   - Repeat up to **2 times** (max 2 fix-and-review iterations). If issues remain after 2 iterations, report to the user.
5. **If the PR review passes** (zero critical, zero important): Mark the PR as ready (`gh pr ready`) and report the clean PR URL to the user.

## Important Notes

- **Never implement code yourself** — you are the orchestrator only. You coordinate and review, but the generator writes all code. This applies everywhere: the gen-eval loop AND the PR review fix loop.
- **You ARE the reviewer** — do not delegate code review to sub-agents. You have the best context (skills, conversation history, tool access). Use it.
- **Never skip the review** — even if the generator reports "all tests pass". Your code review catches design issues and convention violations that tests miss.
- **Two sub-agent types** — the generator (writes code) and the test runner (runs tests). Everything else (code review, error review, contract check, verdict) is your job. You never write code.
- **Show the user the sprint contract** before starting the loop — they may want to adjust criteria
- **Generator gets fresh context** — this is intentional (context reset avoids stale implementation assumptions)
- The generator prompt is large (includes all skill content) — this is the tradeoff for giving it full project knowledge

## Quality Over Speed — Hard Rules

**NEVER trade quality for speed.** The harness exists to produce production-quality code, not to ship fast. Every shortcut taken during the gen-eval loop (accepting fragment tests, skipping review steps, glossing over conventions) creates debt the user has to fix manually.

### Test Quality Is a Hard Gate

During your code review (Step 4c), you MUST verify every test file against the testing skill (`testing/SKILL.md`). Test convention violations are **critical findings that block PASS** — not minor suggestions. Specifically:

1. **Read every new/modified test file in full.** Do not skim.
2. **For each test assertion on generated code, verify:**
   - Does it test a **full method/function body** or just a fragment? Fragments → FAIL.
   - Does it use **object introspection** where possible (`.symbol`, `.type`, `.fields`)? String testing where introspection works → FAIL.
   - Does it use `collapseWhitespace()` for string comparisons? Bare `contains()` → FAIL.
   - Are both expected and actual formatted with `DartFormatter`? Unformatted comparison → FAIL.
   - Does it use `isTrue`/`isFalse`? Bare `true`/`false` → FAIL.
3. **A test that passes but violates conventions is worse than a failing test** — it gives false confidence and hides the convention violation behind a green checkmark.

If the generator produces tests with fragment assertions (`contains('.lock')`, `contains('IList')`), that is a **critical finding**. Do NOT accept it as "good enough." FAIL the iteration and demand full method body comparisons or object introspection.

### Integration Tests Find Bugs, Not Hide Them

When an integration test reveals a bug (compile error, type mismatch, runtime failure):
- **KEEP the failing test** — it is the most valuable test in the suite
- **ADD more adversarial cases** that probe similar weak spots
- **FIX the underlying generator bug** that causes the failure
- **NEVER remove a test case or simplify a schema to avoid a failure**
