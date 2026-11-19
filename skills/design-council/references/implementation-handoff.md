# Implementation handoff

Everything the CEO needs once the decision log is saved and the team is winding down. Loaded on demand when the CEO enters Phase 5's shipping sub-step — **not** during debate.

The debate protocol (Phases 1–4) produces a plan. Executing the plan in parallel adds failure modes that are absent during debate, because implementers write to the filesystem and git. This reference catalogues them.

## Three ship paths (pick one)

1. **Warm-team ship (preferred when the roster fits).** The council seats are already warm with the decision, binding constraints, and execution plan. Before sending shutdown requests, re-brief each seat with its task using the implementer brief below — file ownership, dependency edges, branch strategy, acceptance criteria. Roles translate: `test-engineer` writes tests, `principal-engineer` wires seams, `security-engineer` audits validation landing, `historian` verifies post-merge precedent. Seats that will edit files in parallel still need worktree isolation — see gotcha §1.
2. **Fresh-crew ship.** If the original roster doesn't match the implementation shape, shut the seats down, then spawn implementer-shaped agents per §1. Each spawn prompt includes the decision log path so implementers read arbitrated decisions verbatim before starting.
3. **Handoff to a separate session.** Long-running implementation or user wants to review the log first. Save, shut down, surface log path + handoff summary, stop. Next session picks up via `planning-and-task-breakdown` or `incremental-implementation`.

**Non-negotiable across all paths:** the CEO does not type source code, author implementation tests, or run TDD cycles. Orchestration, routing, arbitration, record-keeping. Filing tracker items for the council's own deferred items is record-keeping, not implementation.

### Implementer briefs

The decision log keeps only a task row (title, files, dependency). Everything an implementer needs to do the task well goes into its brief, written at ship time, one per task — whether the brief is a re-brief message to a warm seat, a fresh-crew spawn prompt, or a section of the handoff summary:

```
TASK <n> of council-<slug>: <task title from the log>
Decision log: ~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md (read the rationale first)
Files you own: <files>. Do not touch: <shared surfaces owned by other tasks, CHANGELOG.md>.
Depends on: <task numbers, and the SHA/branch to base on once they land>
Requirements: <acceptance criteria, edge cases and constraints the seats raised for this task>
Tests: <what must be covered and how it's run>
Base check: <the gotcha §5 base-fix paragraph>
Report back: commit SHA(s), test result, and your one intended CHANGELOG line.
```

Pull the requirements from your debate notes and `brief.md`, not from memory of the log — the log deliberately omits them.

### Path-selection signals

- **Warm-team**: debate was tight (≤2 cross-talk rounds), execution plan has ≥3 tasks with clean file partitions, roster skills cover implementation.
- **Fresh-crew**: roster mismatch or design was contentious enough that some seats' context should not carry forward.
- **Handoff**: user asks for a review gate, or expected implementation spans > 1 day.

## Gotchas observed in production

### 1. Teammates don't get worktree isolation

Teammates run in the team's `cwd` (the invoking project root). Observed when spawns still took `team_name`: combined with `isolation: "worktree"`, the member inherited the team cwd and isolation was ignored. Today `team_name` is ignored and `name` is what makes a spawn a teammate, so treat `name` + `isolation` the same way. Two members sharing the checkout race on the working tree, the index, commit hooks (pre-commit `git add -A` sweeps other agents' unstaged work), and direct commits on the user's branch.

**Fix:** for implementation, spawn Agents with `isolation: "worktree"` and **no `name`**. Each gets a sandbox at `.claude/worktrees/agent-<id>/` and runs as a background subagent; message it by the agent ID from its spawn result. Preserve seat identity via prompt: *"You are the X seat of council-<slug>, re-briefed as implementer for lane Y."* CEO imports their reported SHAs in the declared merge order.

### 2. Worktree-agent cwd leaks into parent Bash

After a worktree agent completes, the parent orchestrator's next `Bash` call may report `pwd` from inside the agent's worktree instead of the main repo. `git branch --show-current` then returns the agent's worktree branch, and subsequent merge ops land on that branch.

**Fix:** every CEO-side Bash with git ops should start `cd /absolute/path/to/project/root &&` and verify with `git branch --show-current` before any merge/checkout/commit. Observed 4+ times in a single session that executed ~10 merges.

### 3. Commit hooks race between parallel agents

Two agents touching disjoint source files still collide through a pre-commit hook that runs across the whole tree (`git add -A`, `lint-staged .`, schema-generate-all) — the hook sweeps one agent's unstaged edits into the other's commit. The victim may not notice.

**Fix:** same as §1 — isolate each implementer in a worktree. Disjoint files aren't enough when hooks run tree-wide.

### 4. Tracker-managed state files pollute every agent's commit

If the host project uses a tracker that exports state on commit (beads' `issues.jsonl`, sqlite-backed trackers, schema-generators that stage artifacts), the export lands in every agent's commit.

**Fix (preferred):** instruct each implementer's spawn prompt to run `git reset HEAD <state-file> && rm -f <state-file>` after staging and before committing. **Fix (CEO-side):** after importing each SHA, unstage + delete the state file before the CEO's merge commit. **Fix (project-side):** gitignore the state file or configure the hook to skip inside `.claude/worktrees/` — a one-time project fix.

### 5. Worktree sandbox may branch from default branch, not current HEAD

The `isolation: "worktree"` default frequently creates the sandbox off `main`, not the CEO's working branch. Implementers working off stale bases produce commits that can't cleanly merge onto the target — or worse, *silently adapt* (substitute stand-in symbols) and the merge succeeds with semantically-wrong code.

**Fix:** include base-fix in every implementer spawn prompt:

> *Before you touch any code: run `git branch --show-current` (expect `worktree-agent-*`), then `git log --oneline -3` and confirm the target branch's HEAD SHA is reachable. If NOT, `git checkout -B <local-branch> <target-branch>` to put yourself on the right base. Do not silently adapt — the CEO merges your commits onto the target, and silent adaptations produce semantically-wrong merges.*

### 6. Per-lane CHANGELOG conflicts are brittle; use a CEO normalizer pass

Multiple parallel worktrees editing `CHANGELOG.md` under overlapping headings produce manual conflicts even when file-level coordination is explicit.

**Fix:** tell every implementer to skip `CHANGELOG.md`. The CEO runs one normalizer pass at the end, accumulating `Added` / `Changed` / `Fixed` / etc. entries. Agents report their intended CHANGELOG line in their completion summary; CEO aggregates.

## The merge primitive: prefer `checkout` over `cherry-pick`

For mixed-base worktree handoffs, **`git cherry-pick` fails** on diff-vs-parent mismatches when worktrees branched from different bases. Observed on `council-2026-04-23-docs-audit`: a batch `git cherry-pick --no-verify` failed on lane 1 because the implementer had edited from main's CHANGELOG base, not feat/sync's; `set -e` cascade-failed the remaining six lanes.

**Use instead:**

```bash
# Import the file contents the agent produced, preserving author + message
git checkout <agent-SHA> -- <files>
git commit --no-verify -C <agent-SHA>
```

`git checkout <SHA> -- <paths>` imports file content directly without replaying a diff against any parent. `-C <SHA>` copies the author/message/timestamp. `--no-verify` is defensible during handoff when the project's pre-commit hook force-stages known tracker state (see §4).

Always `cd /absolute/path/to/repo/root` before each git op (§2). If an agent's commit contained out-of-scope files, check `git diff --cached --name-only` between the `checkout` and the `commit`, then `git reset HEAD -- <unwanted>` + `rm -f <unwanted>`.

Proven on `council-2026-04-23-docs-audit`: 7 clean commits from 6 worktree agents across CHANGELOG + package.json + VERSION, README.md, docs/API.md, docs/SYNC.md, examples, CONTRIBUTING.md + LICENSE + SECURITY.md, docs/TROUBLESHOOTING.md. Lint + type-check + 5231/5231 tests green.

## Debug a broken council

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No handshakes after 60s | Agent teams not enabled, or silent spawn failure | Check `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`; otherwise re-spawn once, drop if still silent, note uncovered domain in log |
| Handshake but no position paper | Seat wrote its position as turn text (visible to the CEO only in the idle notice) | Send: "Deliver your position via SendMessage so the other seats can see it." |
| Cross-talk round stuck >5min | Two seats waiting for each other | Pair-and-narrow via CEO SendMessage; or declare STUCK and arbitrate |
| `cherry-pick` cascade-fails across lanes | Mixed-base worktrees | Switch to `checkout <SHA> -- <files>` + `commit --no-verify -C <SHA>` |
| Parent Bash pwd inside a worktree | Worktree cwd leak (§2) | Prefix every CEO git command with `cd /absolute/path &&` |
| Hook sweeps tracker-state files | §4 pollution | CEO-side: unstage + delete state file before each merge commit |
| User wants to stop mid-council | Protocol gap | Send `shutdown_request` to each seat by name, save partial log with `status: halted` |
