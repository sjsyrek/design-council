# Implementation handoff

Everything the CEO needs once the decision log is saved and the team is winding down. Loaded on demand when the CEO enters Phase 5's shipping sub-step — **not** during debate.

The debate protocol (Phases 1–4) produces a plan. Executing the plan in parallel adds failure modes that are absent during debate, because implementers write to the filesystem and git. This reference catalogues them.

## Three ship paths (pick one)

1. **Warm-team ship (preferred when the roster fits).** The council team is already warm with the decision, binding constraints, and execution plan. Before running `TeamDelete`, re-brief each teammate with their task from the plan — file ownership, dependency edges, branch strategy, acceptance criteria. Roles translate: `test-engineer` writes tests, `principal-engineer` wires seams, `security-engineer` audits validation landing, `historian` verifies post-merge precedent.
2. **Fresh-crew ship.** If the original roster doesn't match the implementation shape, call `TeamDelete`, then `TeamCreate` a new `crew-<yyyy-mm-dd>-<slug>` with implementer-shaped agents. Each spawn prompt includes the decision log path so implementers read arbitrated decisions verbatim before claiming a task.
3. **Handoff to a separate session.** Long-running implementation or user wants to review the log first. Save, shut down, surface log path + handoff summary, stop. Next session picks up via `planning-and-task-breakdown` or `incremental-implementation`.

**Non-negotiable across all paths:** the CEO does not type source code, author implementation tests, or run TDD cycles. Orchestration, routing, arbitration, record-keeping. Filing tracker items for the council's own deferred items is record-keeping, not implementation.

### Path-selection signals

- **Warm-team**: debate was tight (≤2 cross-talk rounds), execution plan has ≥3 tasks with clean file partitions, roster skills cover implementation.
- **Fresh-crew**: roster mismatch or design was contentious enough that some seats' context should not carry forward.
- **Handoff**: user asks for a review gate, or expected implementation spans > 1 day.

## Gotchas observed in production

### 1. `team_name` silently overrides `isolation: "worktree"`

When both are set on an `Agent` call, the member inherits the team's `cwd` (the invoking project root) and worktree isolation is ignored. Two members spawned this way race on the working tree, the index, commit hooks (pre-commit `git add -A` sweeps other agents' unstaged work), and direct commits on the user's branch.

**Fix:** for implementation, spawn Agents with `isolation: "worktree"` and NO `team_name`. Each gets a sandbox at `.claude/worktrees/agent-<id>/`. Preserve seat identity via prompt: *"You are the X seat of council-<slug>, re-briefed as implementer for lane Y."* CEO imports their reported SHAs in the declared merge order.

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
| No handshakes after 60s | Silent `Agent` spawn failure (tmuxPaneId empty in team config) | Re-spawn once; drop if still silent, note uncovered domain in log |
| Handshake but no position paper | Seat outputting plain text then going idle | Send: "Deliver your position via SendMessage; plain text is invisible." |
| Cross-talk round stuck >5min | Two seats waiting for each other | Pair-and-narrow via CEO SendMessage; or declare STUCK and arbitrate |
| `cherry-pick` cascade-fails across lanes | Mixed-base worktrees | Switch to `checkout <SHA> -- <files>` + `commit --no-verify -C <SHA>` |
| Parent Bash pwd inside a worktree | Worktree cwd leak (§2) | Prefix every CEO git command with `cd /absolute/path &&` |
| Hook sweeps tracker-state files | §4 pollution | CEO-side: unstage + delete state file before each merge commit |
| User wants to stop mid-council | Protocol gap | Broadcast `shutdown_request`, save partial log with `status: halted`, `TeamDelete` |
