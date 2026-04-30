---
name: gen-eval
description: Run the generator-evaluator harness on a GitHub issue or a user-provided description — a generator agent builds, four specialist reviewers fan out in parallel, a test runner verifies, and the orchestrator coordinates and merges findings
---

# Generator-Evaluator Harness

Inspired by [Anthropic's harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps). A Generator agent builds the feature, then **four specialist reviewer agents** fan out in parallel to scrutinise the diff — each with fresh context, narrow focus, and read-only tools. A Test Runner agent handles mechanical test execution alongside them. You (the orchestrator) coordinate the fan-out, merge findings, render the verdict, and decide PASS/FAIL. You do not implement code, and you do not perform the primary review yourself — that is the specialists' job.

## Invocation

Two modes:

- **Issue mode**: `/gen-eval <issue-number>` or `/gen-eval <issue-number> <max-iterations>`
- **Description mode**: `/gen-eval "<description>"` or `/gen-eval "<description>" <max-iterations>`

Default max iterations: 3.

**Mode detection:** If the first argument is a number, use issue mode. Otherwise, treat the entire first argument as a free-form task description (equivalent to a GitHub issue body).

## File Layout

### Agent definitions (`.claude/agents/`)

**Builder + test runner:**

| Agent | Purpose |
|-------|---------|
| `tonik-generator` | Implements the feature, then runs `/simplify` + `/security-review` as a Phase 5 cleanup pass before declaring done. Skills (`code-builder`, `testing`, `integration-tests`, `openapi-spec`) preloaded via frontmatter. |
| `tonik-test-runner` | Runs `fvm dart analyze`, all unit tests per package, integration tests, and patch coverage. Read-only + Bash. |

**Specialist reviewers (fan out in parallel — Step 4b):**

| Agent | Focus | Skills |
|-------|-------|--------|
| `tonik-code-reviewer` | Architecture, code_builder rules, OpenAPI parsing correctness, testing conventions | `code-builder`, `testing`, `openapi-spec` |
| `tonik-error-reviewer` | Silent failures, missing context, broad catches, `.toString()` fallbacks, AnyModel/Base64 encoding paths | `code-builder`, `openapi-spec` |
| `tonik-contract-verifier` | Mechanical PASS/FAIL per sprint contract criterion with file:line evidence | (none — purely structural) |
| `tonik-scope-reviewer` | Scope creep, infra changes bundled into feature PRs, cross-package stale references, missed callers | (none) |

All four reviewers are **read-only** (no `Edit` / `Write`), spawned **fresh every iteration** (no carryover context), and run **in parallel** with the test runner.

### Orchestrator reference file (`.claude/harness/`)

| File | Purpose |
|------|---------|
| `evaluator.md` | Verdict format, severity classification, regression-table format, passing threshold |

The previous `review-code.md` / `review-errors.md` checklists have been folded into the relevant specialist reviewer prompts.

**Why specialists in parallel, not orchestrator-as-reviewer:**
- **Fresh context every iteration** — the orchestrator's context fills with prompts, branch ops, prior iteration history; specialists see only their narrow concern + the diff.
- **Narrow focus catches more** — a single agent juggling architecture, error handling, contract criteria, and scope will flatten priorities; four specialists each go deep.
- **Defense in depth** — specialists overlap intentionally; the orchestrator dedupes. Better to double-flag than miss.
- **The orchestrator stays a coordinator** — composing prompts, merging findings, rendering verdicts, deciding loop control. That alone consumes meaningful context.

## Orchestration Steps

You (the orchestrator) execute these steps. Do NOT implement the feature yourself — you only coordinate. Do NOT perform the primary code review yourself — that is the specialists' job.

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
2. **Orchestrator reference**: Read `.claude/harness/evaluator.md` (verdict format, thresholds, regression-table format).
3. **CLAUDE.md**: For your own reference during merge / verdict rendering (the sub-agents have it loaded automatically by Claude Code).
4. **Existing code**: Identify what already exists for this feature so the generator knows its starting point.

**Note:** You no longer need to read skill files (code-builder, testing, integration-tests, openapi-spec) or any review checklist files. The generator and the four reviewer agents have their relevant skills and checklists preloaded via their `skills:` frontmatter and embedded prompts.

### Step 2: Create Sprint Contract
Based on the task's acceptance criteria, write a numbered list of **concrete, testable criteria**. Each criterion must be binary (pass/fail) and verifiable by reading code or running tests.

**CRITICAL: 1:1 mapping from acceptance criteria.** Every acceptance criterion in the task MUST map to at least one contract item. Do not paraphrase or summarize — parse each criterion literally.

- **Issue mode**: The issue body typically contains explicit acceptance criteria — parse them literally.
- **Description mode**: The description may be less structured. Extract testable criteria from the description, and fill in obvious implied criteria (e.g., tests, analysis). If the description is vague, ask the user to clarify acceptance criteria before proceeding.

**Checklist before presenting the contract:**
- [ ] Every acceptance criterion from the task has a corresponding contract item (no lossy summarization)
- [ ] Every test category the task mentions (unit per package, integration) is an explicit criterion
- [ ] Test criteria are specific about coverage scope (which cases, which error conditions, which scenarios)
- [ ] Test criteria are explicit about test layer (unit in package X, integration test in `integration_test/`)
- [ ] There is a criterion for analysis passing (`fvm dart analyze`)
- [ ] If generator changes are involved, there is a criterion for integration tests passing
- [ ] There is a criterion for patch coverage >= 90% (`bash scripts/coverage.sh --diff main`)
- [ ] Any criterion that produces emitted Dart code mentions explicitly that tests must be **full method body comparisons** with `collapseWhitespace()` + `DartFormatter` — not fragments

Present the sprint contract to the user for approval before proceeding.

### Step 3: Compose Prompts

All agents have skills and checklists preloaded — you only compose the **dynamic content** for each prompt. Do NOT modify the agent definition files; pass per-invocation values via the `prompt` argument.

#### Generator prompt (passed via Agent tool `prompt`)
Compose a prompt containing:
- Issue title + body (issue mode) or user-provided description (description mode) — labelled `## Task Description`
- The sprint contract from Step 2 — labelled `## Sprint Contract`
- Evaluator feedback: "This is the first iteration. No prior feedback." (or actual feedback on subsequent iterations) — labelled `## Evaluator Feedback`

CLAUDE.md and the four skills are loaded automatically by the agent's frontmatter — do NOT splice them into the prompt.

#### Reviewer prompt (shared base — passed to each of the four reviewers)
Compose a single base prompt containing:
- The sprint contract from Step 2
- Issue title + body (or user-provided description)
- **Prior-iteration findings** — on iteration 1, "First iteration; no prior findings." On iteration 2+, the merged feedback list from the previous iteration.

This same base prompt goes to **all four** reviewers (`tonik-code-reviewer`, `tonik-error-reviewer`, `tonik-contract-verifier`, `tonik-scope-reviewer`). Each agent's frontmatter and embedded checklist scope it to its specialty — you do NOT need to add specialty-specific instructions.

#### Test runner prompt (passed via Agent tool `prompt`)
Compose a prompt containing:
- Sprint contract
- Task acceptance criteria

The test runner does not need the full diff or skill content — it runs mechanical tests.

### Step 4: Generator-Review Loop

For each iteration (1 to max_iterations):

#### 4a. Spawn Generator
- `subagent_type: "tonik-generator"`
- `prompt`: The composed dynamic prompt from Step 3
- Do NOT use `isolation: "worktree"` — the generator works on the current branch
- Do NOT run in background — wait for completion

The generator's workflow includes a mandatory **Phase 5 cleanup pass** that runs `/simplify` and `/security-review` against the diff and applies fixes before declaring done. This shifts simplification and security work left so the four downstream reviewers see already-cleaned code. The generator's final report briefly summarises what each pass changed — read those bullets so the merge step can correlate findings.

#### 4b. Fan Out — Spawn All Reviewers + Test Runner in Parallel

**This is a single message containing 5 `Agent` tool calls in parallel** — four reviewers + the test runner. Do NOT spawn them sequentially. Parallelism is a hard requirement for two reasons:
1. Wall-clock — 5 agents serialised would multiply iteration time.
2. Independence — each reviewer must form its findings without seeing the others' output (avoids groupthink / shared blind spots).

For every reviewer, use:
- `subagent_type`: one of `tonik-code-reviewer`, `tonik-error-reviewer`, `tonik-contract-verifier`, `tonik-scope-reviewer`
- `prompt`: the **shared base reviewer prompt** from Step 3 (identical for all four — their frontmatter scopes them)
- `run_in_background: true`
- Do NOT use `isolation: "worktree"` — they read the current branch

For the test runner:
- `subagent_type: "tonik-test-runner"`
- `prompt`: the composed test runner prompt from Step 3
- `run_in_background: true`

After dispatching all 5, you wait. You do NOT read files, you do NOT run reviews yourself. Your context is reserved for the merge step.

#### 4c. Merge Findings (your job — coordinator, not reviewer)

When all 5 agents complete, you merge their outputs. You are NOT performing a primary review here — that's done. You are aggregating, deduping, and rendering.

1. **Collect every finding** from all four reviewers, grouped by reviewer.
2. **Dedupe overlaps** — when two reviewers flag the same issue (expected, by design), merge into one entry but note both reviewers detected it (signal of higher confidence). Example: a `.toString()` fallback might appear in both `tonik-error-reviewer` and `tonik-code-reviewer`. One entry, both reviewers cited.
3. **Reconcile conflicts** — if reviewers disagree on severity, take the higher. If they disagree on the fact ("is this a bug?"), keep both with the disagreement noted; the generator can decide.
4. **Read the contract verifier's table** — this is your source of truth for sprint contract status. Do NOT re-do the contract check yourself; trust the table or, if it looks suspicious, spot-check 2–3 entries by `Read` / `Grep`.
5. **Spot-check (optional, ≤ 3 entries)** — your skills + conversation history give you cross-pollination the specialists lack. If something obvious looks missed, flag it as an orchestrator finding. Do NOT do a full review — that's not your job here.
6. **Read the test runner's report** and merge analysis / unit-test / integration-test / patch-coverage status.

**Time budget guidance:** the merge step should be minutes, not hours. If you find yourself spending more time merging than the reviewers spent reviewing, you're doing too much yourself.

#### 4d. Render Verdict

Use the format from `.claude/harness/evaluator.md`:
- Severity classification (Critical / Important / Minor)
- Passing threshold: ALL contract criteria PASS, ALL tests PASS, patch coverage >= 90%, ZERO critical findings, ZERO important findings, ≤ 3 minor findings (each acknowledged)

The verdict report includes a **per-reviewer breakdown** (so the user can see which specialist caught what), the merged finding list, the contract verifier table, and the test runner summary.

If **PASS**: Break the loop. Proceed to Step 5.
If **FAIL**: Compose a numbered feedback list ordered by severity. This list becomes the "Prior-iteration findings" input for the next iteration's generator AND for all four reviewers. Continue to next iteration.

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
2. **Commit and create a draft PR automatically** — do not ask. Follow standard PR workflow (commit, push, `gh pr create --draft`). No Co-Authored-By trailer. No Claude Code branding in the PR body. No internal bug numbers or tracking refs.
3. **Run `/pr-review-toolkit:review-pr`** on the new PR. This launches specialized review agents (code-reviewer, silent-failure-hunter, test-analyzer, type-design-analyzer, comment-analyzer) that provide a second layer of scrutiny.
4. **If the PR review finds critical or important issues:**
   - Compose a numbered feedback list from the PR review findings (same format as evaluator feedback in Step 4).
   - Spawn the `tonik-generator` sub-agent with the feedback, the sprint contract, and the list of findings. The generator fixes the issues — you do NOT write code yourself.
   - Review the generator's fixes (read the diff, verify each finding is addressed).
   - Commit and push the fixes.
   - **Run `/pr-review-toolkit:review-pr` again — as a FRESH review.** Do NOT scope the re-review to "verify these fixes were applied." Each review iteration must be a complete, fresh-eyes review of the entire PR diff against main. The point of iterations is fresh perspective, not regression testing of known issues. If you prompt review agents with "check if these N fixes were applied," they will check boxes instead of reviewing code. Prompt them identically to the first round — the full diff, no prior context.
   - Repeat up to **4 times** (max 4 fix-and-review iterations). Each iteration is a fresh-eyes review that may surface issues prior rounds missed — this is expected and healthy, not a sign of failure. If issues remain after 4 iterations, report to the user.
5. **If the PR review passes** (zero critical, zero important): Mark the PR as ready (`gh pr ready`) and report the clean PR URL to the user.

## Important Notes

- **Never implement code yourself** — you are the orchestrator only. You coordinate, you don't code, you don't review. The generator writes all code. The four specialist reviewers do the review. You merge findings and decide. This applies everywhere — the gen-eval loop AND the PR review fix loop.
- **You COORDINATE — specialists review.** Do NOT do a primary code review yourself. The four reviewers run in parallel with fresh context per iteration; that depth and freshness is the point. Your job is to merge their outputs, dedupe overlaps, and render the verdict. You may add ≤ 3 spot-check findings if something obvious slipped through, but never replace the specialists' work.
- **Reviewers are spawned fresh every iteration** — never reuse a reviewer agent across iterations. Each iteration's generator output gets four new reviewer invocations with no carryover context. This is a hard requirement: it's how we get fresh-eyes review for free.
- **Reviewers run in parallel, not in series** — Step 4b dispatches 5 agents (4 reviewers + 1 test-runner) in a single message with parallel tool calls. Sequential dispatch defeats the purpose.
- **Every PR-review iteration is fresh** (Step 5) — never scope a re-review to "verify the fixes." A fix can be technically applied but incomplete. Only a full, unscoped review of the entire diff catches these gaps. "Was the fix applied?" is the wrong question. "Does the code work?" is the right one.
- **Agent types:**
  - `tonik-generator` (writes code; runs `/simplify` + `/security-review` in Phase 5)
  - `tonik-test-runner` (analysis + unit + integration + patch coverage)
  - 4 reviewers (`tonik-code-reviewer`, `tonik-error-reviewer`, `tonik-contract-verifier`, `tonik-scope-reviewer`) — all read-only
  - You write nothing. You review nothing primary. You coordinate, merge, decide.
- **Show the user the sprint contract** before starting the loop — they may want to adjust criteria.
- **Generator and reviewers all get fresh context** — this is intentional (context reset avoids stale assumptions and groupthink).
- All agents have project skills preloaded — you do NOT need to paste skill content into prompts.
- **Defense-in-depth duplication is intentional** — both within the gen-eval loop (reviewers may overlap) and across loops (`/pr-review-toolkit:review-pr` runs after the internal loop with different agents and targeting). Different vantage points catch different issues; do not optimise away the redundancy.

## Quality Over Speed — Hard Rules

**NEVER trade quality for speed.** The harness exists to produce production-quality code, not to ship fast. Every shortcut taken during the gen-eval loop (accepting fragment tests, skipping review steps, glossing over conventions) creates debt the user has to fix manually.

### Test Quality Is a Hard Gate

Test convention violations are **critical findings that block PASS** — not minor suggestions. The `tonik-code-reviewer` enforces this; the orchestrator must not downgrade these findings during the merge step. Specifically:

1. **Every new/modified test file is scrutinised in full by `tonik-code-reviewer`.**
2. **For each test assertion on generated code, the reviewer verifies:**
   - Does it test a **full method/function body** or just a fragment? Fragments → CRITICAL.
   - Does it use **object introspection** where possible (`.symbol`, `.type`, `.fields`)? String testing where introspection works → CRITICAL.
   - Does it use `collapseWhitespace()` for string comparisons? Bare `contains()` → CRITICAL.
   - Are both expected and actual formatted with `DartFormatter`? Unformatted comparison → CRITICAL.
   - Does it use `isTrue`/`isFalse`? Bare `true`/`false` → CRITICAL.
3. **A test that passes but violates conventions is worse than a failing test** — it gives false confidence and hides the convention violation behind a green checkmark.

If the generator produces tests with fragment assertions (`contains('.lock')`, `contains('IList')`), that is a **critical finding**. Do NOT accept it as "good enough." FAIL the iteration and demand full method body comparisons or object introspection.

### Integration Tests Find Bugs, Not Hide Them

When an integration test reveals a bug (compile error, type mismatch, runtime failure):
- **KEEP the failing test** — it is the most valuable test in the suite
- **ADD more adversarial cases** that probe similar weak spots
- **FIX the underlying generator bug** that causes the failure
- **NEVER remove a test case or simplify a schema to avoid a failure**
