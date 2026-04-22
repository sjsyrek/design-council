---
name: design-council
description: This skill should be used when the user asks to "convene the council", "design debate", "get the team together", "council review", "run a design review", "debate this design", or describes a non-trivial technical decision that benefits from multiple specialist perspectives — architecture choices, API shape, significant refactors, security review with stakes, cross-cutting performance work, or feature design where UX, engineering, and product all have standing. Also covers audit/review tasks (codebase-wide P0/P1 scans, security reviews with stakes, pre-1.0 hardening passes) via the Review mode variant. Convenes a parallel team of role-specialized agents, each with its own context, who debate in real time via inter-agent messaging while the invoking Claude serves as CEO — convening, routing, and arbitrating unresolved disagreements.
version: 0.1.4
---

# design-council

## Purpose

Convene a **parallel team of role-specialized agents** to debate an ambitious technical decision in real time, with the invoking Claude acting as **CEO**: convening, routing, arbitrating. Every teammate has its own context (not a subagent inheriting yours). Teammates can DM each other directly via `SendMessage` — the debate is genuinely inter-agent, not hub-and-spoke.

The output is a **lean decision log** (≤1 page) saved outside any project repo. No sequential-append artifact, no per-round transcripts — just the opening prompt, the roster, the resolved disagreements, the CEO's written arbitration for anything unresolved, and pointers to deferred follow-ups.

## When to invoke

Trigger on phrases like "convene the council", "design debate", "council review", "get the team together". Also trigger proactively when:

- The user describes a decision that clearly crosses multiple specialist domains (API shape + UX + security; infra + performance + product).
- The user is stuck between 2+ design options and wants structured input.
- The user asks for "a review" on a non-trivial piece of work and the scope is broad.

Do NOT invoke for:
- Simple bug fixes or one-line changes.
- Decisions where one specialist seat is clearly sufficient (use the corresponding solo agent).
- Pure research questions (use `Explore` instead).

## Default roster (11 always-on seats)

| # | Name (slug) | Owns |
|---|-------------|------|
| 1 | `principal-engineer` | Architecture, module boundaries, simplicity. Opens the debate. |
| 2 | `platform-engineer` | Systems, infra, data shape, operational cost, observability |
| 3 | `integration-engineer` | Downstream / API consumers, third-party developers, backwards compat |
| 4 | `test-engineer` | TDD, mutation ritual, coverage strategy, assertion hygiene |
| 5 | `qa-engineer` | User flows ↔ spec alignment, regression surface, manual test plan |
| 6 | `security-engineer` | Input validation, secrets, path safety, error sanitization |
| 7 | `performance-engineer` | Batching, memory, concurrency, measurement-before-optimization |
| 8 | `product-manager` | UX alignment, product coherence, best-practice conformance |
| 9 | `ui-ux-designer` | Ergonomics, visual consistency, interaction design |
| 10 | `accessibility-specialist` | a11y, keyboard nav, screen reader, contrast |
| 11 | `technical-writer` | Docs, in-app help, man pages, CHANGELOG, API reference |

## Opt-in seats

Add these when the decision's shape calls for them:

- `devops-engineer` — deploy risk, CI/CD, rollback, feature flags
- `finops-engineer` — cloud/API cost, per-request economics, quota
- `legal-compliance` — privacy, licensing, regulated-industry constraints
- `domain-expert` — subject-matter specialist for the product area
- `historian` — codebase precedent blocker (only for mature codebases)

The CEO decides opt-ins in the **Brief** phase based on cues (UI stakes, compliance-heavy, deploy risk, long-lived codebase).

## Review mode variant

The default protocol is **debate-oriented**: seats post verdicts on a single proposal, peer-DM to resolve disagreements, CEO arbitrates what's left. That shape fits decisions (OAuth vs API keys, monolith vs split, migrate now vs later).

For **audit / review** tasks — "review this repo for P0/P1 issues", "security audit of the auth flow", "pre-1.0 hardening pass" — that shape misfits. Seats work disjoint sub-areas, peer-DMs are rare, and cross-talk rounds 2–3 add no value. Signal: the user asks for a "review" over a broad scope and expects many findings back, not one decision.

When running in review mode, apply these protocol adjustments:

1. **Phase 1 Brief:** use `references/opening-prompt-template.md` Review mode section (strict finding format, priority filter, evidence rules). Partition the codebase/scope across seats in the opening prompt so findings don't duplicate.
2. **Phase 2 Convene:** same parallel fan-out. Still run Phase 2.5 handshake verification (see Universal spawn rules below).
3. **Phase 3 Cross-talk:** **SKIP by default.** Review seats rarely need to DM each other. Only run Phase 3 if the CEO sees ≥2 overlapping findings that need deduplication via the seats themselves (rare — the CEO usually dedupes at Phase 4).
4. **Phase 4 Arbitration:** repurposed to **deduplicate overlapping findings** across seats and decide whether merged findings file as one or many tracker items. Verdict tags (APPROVE/CONCERNS/BLOCK) are not used; findings have a priority tag (P0/P1/etc.) instead.
5. **Phase 5 Decision log:** the primary artifact is the **file-ownership execution map** of the filed tracker items, not arbitration rationale. The "Opening verdicts" and "Resolved disagreements" sections are typically empty; drop them or replace with "Per-seat finding counts." Bulk-file tracker items (see tracker integration below) before the teardown step.

Review mode still requires the Universal spawn prompt rules below — especially the handshake. Silent-spawn failures are more common at large rosters, and a seat that never actually started silently reduces review coverage.

## Universal spawn prompt rules (include in every Agent prompt)

Every spawned teammate must be told these rules explicitly in its prompt. The role brief's "Debate protocol" section assumes them but does not spell them out, and seats regularly fail the contract without them:

1. **`SendMessage` is the only channel to the CEO.** Plain-text output is NOT visible to the CEO — it is discarded at idle. Findings, positions, objections, questions, and status updates MUST be sent via `SendMessage(to: "<ceo-name>", message: "...")`.
2. **Handshake within the first reasoning turn.** Before starting substantive work, the seat must send a 1-line handshake: `SendMessage(to: "<ceo-name>", summary: "started", message: "Started work on <area>.")`. This tells the CEO the agent spawned correctly and parsed the prompt. Seats that skip the handshake are indistinguishable from silent-spawn failures.
3. **Final work delivered via SendMessage, even if going idle immediately after.** The failure mode is: agent completes its analysis, outputs findings as plain text, transitions to idle, sends no message. The CEO sees the idle notification but no content. The agent's work is lost.
4. **Idle notifications carry only an optional `summary` field, not full content.** Do not put substantive findings in the summary and expect the CEO to read them — use a real SendMessage with the full content.

The CEO does NOT assume these rules are inherited — they are explicitly inlined in every spawn prompt. See `protocol.md` Phase 2 for the prompt-assembly template.

## Protocol (5 phases)

### Phase 1 — Brief

CEO does all of this **before spawning anyone**:

1. **Name the decision.** One paragraph stating the question explicitly. Vague prompts produce vague debates.
2. **Gather binding constraints.** Read:
   - `CLAUDE.md` in the invoking project's cwd (if present)
   - Any plan/spec file the user referenced
   - The project's memory system if it has one (e.g., `bd memories` for beads-using projects, `~/.claude/projects/<hash>/memory/` for auto-memory projects)
3. **Decide opt-in seats.** UI stakes → keep `accessibility-specialist`. Compliance cue → add `legal-compliance`. Deploy risk → add `devops-engineer`. Spend-sensitive → add `finops-engineer`. Mature codebase / precedent-heavy → add `historian`.
4. **Draft the opening prompt.** Use `references/opening-prompt-template.md`. Sections: Decision question; Binding constraints (verbatim); Non-goals; Success criterion.

### Phase 2 — Convene (parallel fan-out)

**In a single multi-tool-call message**, call `TeamCreate` and then spawn every teammate in parallel:

```
TeamCreate(team_name: "council-<yyyy-mm-dd>-<slug>", description: "Debate: <one-line>")
Agent(team_name: "council-...", name: "principal-engineer",      subagent_type: "general-purpose", run_in_background: true, prompt: <role brief> + <binding constraints> + <opening prompt> + <debate protocol instructions>)
Agent(team_name: "council-...", name: "platform-engineer",       subagent_type: "general-purpose", run_in_background: true, prompt: ...)
Agent(team_name: "council-...", name: "integration-engineer",    subagent_type: "general-purpose", run_in_background: true, prompt: ...)
... × 11 mandatory + opt-ins
```

Each agent's prompt assembles from:
- Its role brief: `${CLAUDE_PLUGIN_ROOT}/skills/design-council/references/roles/<slug>.md`
- Binding constraints gathered in Phase 1 (verbatim)
- The opening prompt
- Debate protocol instructions (included inline in each role brief)

The `name` parameter makes each teammate addressable via `SendMessage`. `run_in_background: true` keeps them alive for multiple rounds of debate.

### Phase 2.5 — Handshake verification

**Do NOT proceed to cross-talk without confirming each seat actually spawned.** The `Agent` tool can return `[Tool result missing due to internal error]` and still register the teammate in team config — the slot is reserved, but no process started. Observed in one session: 3 of 13 seats silently failed this way, invisible until the user pointed at the empty tmux panes.

Verification steps, bounded to ~60s:

1. **Wait for handshake messages.** The Universal spawn rules require every seat's first SendMessage to be a handshake (`Started work on <area>.`). Count incoming handshakes against the roster.
2. **Check team config for empty `tmuxPaneId`.** Read `~/.claude/teams/<team_name>/config.json`. Any member with `"tmuxPaneId": ""` after ~30s has not actually spawned a pane — the Agent spawn failed silently.
3. **For each silent-spawn failure:** re-spawn the Agent once (same prompt), OR drop the seat from the roster and note the coverage gap in the decision log.

After verification, the CEO has a confirmed roster. Missing seats leave gaps in the review; the Phase 5 log must acknowledge which domains were not covered.

### Phase 3 — Cross-talk (peer DMs + CEO routing, bounded)

**Hard bound: 3 rounds.** A round starts when the CEO prompts the team and ends when replies settle (idle notifications stop arriving).

Each round:

1. CEO reviews opening positions + any peer-DM summaries (automatically surfaced via idle notifications).
2. CEO identifies the top 2–4 live disagreements.
3. For each disagreement, CEO chooses one of:
   - **Pair disagreers**: `SendMessage(to: <seat_A>, message: "You and <seat_B> disagree on <X>. DM them directly — try to converge or sharpen the disagreement.")` — peer DMs take over.
   - **Invite tiebreaker**: include a third seat whose domain bears on the dispute (e.g., `test-engineer` between `security-engineer` and `performance-engineer`).
   - **Narrowing question**: `SendMessage(to: <seat>, message: "What's the concrete scenario where <X> breaks? Cite file:line.")` — forces vagueness into specificity.
   - **Bridge converged tracks**: when parallel peer-DM exchanges each produce an internally-consistent position but the two tracks externally conflict, do NOT reopen the DMs. Send each track a narrowing question that pins vocabulary across tracks. In practice, two converged sub-groups often turn out to be using different words for the same structural position; a single "X or Y?" question resolves what looks like a technical disagreement.
4. CEO closes the round when responses settle. Marks each disagreement as:
   - `RESOLVED` — team converged.
   - `SHARPENED` — still disagree but on a crisper point.
   - `STUCK` — deadlocked.

Cross-talk ends when: all disagreements `RESOLVED`, OR 3 rounds elapsed, OR CEO declares further rounds unproductive.

**Review-mode exception:** skip this phase entirely unless the CEO sees ≥2 overlapping findings across seats that the seats themselves should dedupe. Review seats work disjoint sub-areas; cross-talk is almost always unproductive. See Review mode variant above.

### Phase 4 — CEO arbitration

For every disagreement not `RESOLVED`:

- CEO writes a **3–5 sentence decision**. Structure: best argument on each side; chosen side; rationale engaging with the loser's argument. Or: `DEFER` with an explicit revisit criterion.
- CEO escalates to the **human user** only for strategic or budget-adjacent calls: scope expansion, breaking-change consent, commercial/licensing tradeoffs, cross-team dependencies. Format: ≤150-word summary; `AskUserQuestion` when options are discrete, plain text otherwise.
- Routine technical disagreements (naming, internal layering, implementation tactics) are resolved by the CEO without escalation.

### Phase 5 — Decision log + teardown

CEO persists a lean decision log at:

```
~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md
```

Template: `references/decision-log-template.md`. Contents:

- Opening prompt + binding constraints
- Roster convened (and opt-ins)
- Opening positions — one-liner per seat + verdict
- Resolved disagreements — one line each
- CEO arbitration decisions with rationale
- Human-escalated items + outcomes
- Deferred items (expected-later, time- or signal-based) → follow-up tracker IDs
- Blocked items (hard-no, re-open gated on a structural change to the problem) — distinct from DEFER; prose-only handle, not auto-filed as tracker items
- **Execution plan** — ordered tasks with file-ownership mapping and a merge-conflict strategy (see `protocol.md` Phase 5)
- **Length cap: one page. Executive summary, not transcript.**

**Review-mode log variant:** the "Opening verdicts" and "Resolved disagreements" sections are typically empty. Replace with "Per-seat finding counts" and "CEO dedup decisions" (overlapping findings merged into one tracker item). The Execution plan becomes primarily a **file-ownership map of the filed tracker items** — which clusters share code and must be serialized. Bulk-file tracker items (review mode can produce dozens) before teardown; the log records their IDs but the tracker is the durable record.

Teardown:

1. `SendMessage(to: "*", message: {type: "shutdown_request", reason: "council concluded"})`
2. Wait for `shutdown_response` from each teammate.
3. `TeamDelete()` to remove team and shared task list.

## Key rules (non-negotiable)

- **Agents are peers with independent contexts.** Your conversation is not shared with any teammate. Everything they need is in their spawn prompt.
- **Peer-DM first, CEO-route second.** Teammates DM each other for domain-to-domain debate. CEO routes only for tiebreakers, stalls, or strategic calls.
- **CEO never takes a seat.** Convene, route, arbitrate, record. Never draft positions. Never critique. Never debate.
- **CEO never writes code or implements anything.** Orchestration, routing, arbitration, and record-keeping are the CEO role. Writing source code, writing implementation tests, running `bd update --claim`, or starting a TDD cycle is seat-work. Shipping happens via **fresh per-implementer agents with `isolation: "worktree"` and NO `team_name`** (see "Implementation handoff gotchas" below). Preserve seat identity in the spawn prompt ("You are the X seat of council-<slug>, re-briefed as implementer for lane Y") rather than via team membership — the semantic framing is what mattered in debate, and fresh isolated agents perform identically to warm team members on implementation work while avoiding file-system races. CEO cherry-picks their SHAs in the declared merge order from the execution plan. In all paths the CEO stays off the keyboard for application code.
- **Execution plan must address merge conflicts.** The Phase 5 log's execution plan partitions follow-up work so parallel implementers do not collide. Map each task to the files it will touch; serialize tasks that touch the same file; call out shared-surface hotspots (manifest files, lockfiles, shared types) and assign them to a single task. If the project has agent-teamwork guidelines (e.g., `CLAUDE.md` worktree rules), mirror them.
- **Opening prompt carries the constraints.** They are baked into every teammate's spawn prompt — cannot be forgotten mid-debate.
- **Round budget is hard.** 3 cross-talk rounds max.
- **Every CEO decision is written with rationale.** Silence as resolution is banned.
- **Decision log stays outside any repo.** Default `~/.claude/councils/`.
- **Shutdown is protocol.** Use `shutdown_request` — do not leak teammates.
- **Scope discipline.** Unrelated issues surfaced in debate → new tracker item, never a side-diff.

## Tracker integration (optional, auto-detected)

This skill composes with external issue trackers when present. Detection is explicit and fails-safe — **the skill's core protocol runs identically with or without a tracker.** Most users do not have a tracker configured; that is the default path, not the exceptional one.

**Directly supported today: beads** (https://github.com/gastownhall/beads) — because it exposes a CLI (`bd`) and a memory system that compose cleanly with Claude's tool surface. Other trackers (GitHub Issues via `gh`, GitLab via `glab`, Linear, Jira, etc.) can be wired by following the same detection + command-mapping pattern; the skill does not ship bindings for them.

**Detection (beads):** `.beads/` directory at the invoking project's git root, OR `bd` binary on `$PATH`. Concretely: `test -d .beads || command -v bd`.

**When beads is detected, the skill automatically:**

- **Phase 1 brief:** runs `bd memories`, `bd ready`, and `bd show <id>` for any bead ID the user references. Output is included verbatim in the opening prompt.
- **Phase 4 arbitration:** every `DEFER` decision is translated into a `bd create --title=... --description=... --type=task --priority=N` command, executed before Phase 5 teardown. The filed bead ID is recorded in the decision log as the action handle.
- **Phase 5 teardown:** if a primary bead was under debate, `bd close <id>` runs before `TeamDelete`. Use `--force` if beads flags a known epic-dependency-inversion — that's a beads behavior, not a skill bug. The CEO verifies every DEFER has a filed bead ID before declaring teardown complete.

**When no tracker is detected (the common case):** deferred items remain prose entries in the decision log. The CEO does not invent commands for a tracker that isn't there. Users with other trackers can port the same pattern manually (`gh issue create`, `glab issue create`, etc.) based on their workflow — the skill's contract is the decision log's `## Deferred items` list; the tracker integration is a convenience layer on top.

**Two-list discipline (when a persistent tracker is present):** `TeamCreate` creates `~/.claude/tasks/<team>/` for session-scoped coordination between teammates during the debate. Persistent work (existing issues, follow-ups, epics) lives in the tracker. Never duplicate. Never file session-scoped coordination items as persistent tracker items.

## Failure modes this skill guards against

1. **Sequential-thinking regression** — Parallel spawn is the default; multi-tool-call template is shown explicitly in Phase 2.
2. **Runaway debate** — 3-round cap; CEO forces closure.
3. **Silent CEO** — Every unresolved item requires a written decision.
4. **Constraint re-discovery** — Constraints are in spawn prompts, not passed mid-debate.
5. **Leaked decision logs** — Default path is outside any repo.
6. **Zombie teammates** — Teardown protocol is mandatory.
7. **Role collapse** — Fewer than 6 seats triggers a warning; CEO confirms or adds seats.
8. **CEO seat-creep into implementation** — Shipping happens via fresh isolated agents (see "Implementation handoff gotchas"), with seat identity preserved in the prompt, not via team membership. The CEO orchestrates and cherry-picks; never types application code.
9. **Collision-blind execution plans** — Follow-up tasks that touch the same files without a sequencing note produce rebase churn. The execution plan maps tasks to files and serializes overlaps.
10. **Team-membership / worktree-isolation collision** — `team_name` silently overrides `isolation: "worktree"` on the Agent tool. Team members inherit the team's `cwd` (the main repo) and race on the working tree, index, and commit hooks. Use team membership ONLY for debate (read-only on the code); for implementation spawn fresh agents with `isolation: "worktree"` and no `team_name`.
11. **Silent spawn failure** — An Agent tool call may return `[Tool result missing due to internal error]` and still register the teammate in team config with `"tmuxPaneId": ""`. The slot is reserved but no process runs. CEO catches this via Phase 2.5 handshake verification; without it, the domain sits silently uncovered. Observed at a 3/13 rate in one session.
12. **Plain-text findings lost to floor** — Agent completes analysis, outputs findings as plain text, transitions to idle, sends no `SendMessage`. The CEO sees the idle notification but no content; the agent's work is invisible. Distinct from the silent-acceptance pattern in `protocol.md` (which assumes a prior position was posted and silence indicates concurrence) — here, NO position was ever posted. The Universal spawn prompt rules' handshake + explicit "deliver via SendMessage" contract catches this at Phase 2.5 before time is wasted.
13. **Tracker state-file pollution** — Trackers that export their state on commit (beads' `issues.jsonl`, sqlite-mirror dumps, schema-generators) auto-stage into every implementer's commit during handoff. CEO must strip on cherry-pick. See "Implementation handoff gotchas" §4 for the fix.
14. **Worktree-base drift** — Agent sandboxes with `isolation: "worktree"` may branch off the default branch, not the CEO's working branch. Implementer commits land on a stale base and either conflict at cherry-pick or — worse — silently adapt to the missing context. Spawn prompts MUST include a base-fix instruction. See gotcha §5.
15. **Per-lane CHANGELOG conflicts** — Parallel worktrees editing `CHANGELOG.md` under shared headings produce manual cherry-pick conflicts regardless of per-lane coordination rules. Always assign `CHANGELOG.md` to a CEO-owned normalizer pass at the end. See gotcha §6.

## Implementation handoff gotchas

The debate protocol (Phases 1–5) produces a plan. Executing the plan in parallel adds new failure modes not present during debate, because implementers write to the filesystem and git. Named concretely:

### 1. `team_name` overrides `isolation: "worktree"`

When both are set on an Agent call, the member inherits the team's `cwd` (typically the invoking project root) and the worktree isolation is silently ignored. Two members spawned this way both work in the same checkout, racing on:

- The working tree (unstaged file edits)
- The index (partial staged state)
- Commit hooks (pre-commit `git add -A` style hooks sweep other agents' unstaged work when one commits)
- `HEAD` (direct commits on the user's branch, bypassing CEO cherry-pick review)

**Fix:** for implementation, spawn Agents with `isolation: "worktree"` and NO `team_name`. Each gets a sandbox at `.claude/worktrees/agent-<id>/`. Semantic identity preserved via prompt: *"You are the X seat of council-<slug>, re-briefed as implementer for lane Y."* CEO cherry-picks their reported SHAs in the declared merge order.

### 2. Worktree-agent cwd leaks into parent Bash after completion

After a worktree agent completes, the parent orchestrator's next `Bash` call may report `pwd` from inside the agent's worktree (`.claude/worktrees/agent-<id>/`) instead of the main repo. `git branch --show-current` then returns the agent's worktree branch, and `git cherry-pick` lands on that branch instead of the target branch. You may not notice — cherry-pick onto the worktree's own branch is typically a no-op because the commit is already there.

**Fix:** every CEO-side Bash command that runs git operations should start with `cd /absolute/path/to/project/root &&` and verify with `git branch --show-current` before `cherry-pick`. Observed this quirk 4+ times in a single session that executed ~10 cherry-picks; verifying cwd is cheap, missing it is lossy.

### 3. Commit hooks race between parallel agents

Even when two agents touch disjoint source files, a pre-commit hook that runs across the whole tree (`git add -A`, `lint-staged .`, schema-generate-all) will sweep one agent's unstaged edits into the other's commit. The first agent's work silently ships under the wrong commit message, author, or CHANGELOG entry. The receiving agent may not notice — their commit appears successful. Recovery requires the victim to detect the sweep (by noticing files changed that they didn't expect) and do a `reset --mixed` + re-split + rebuild of both commits preserving author/message.

**Fix:** same as gotcha #1 — isolate each implementer in a worktree. Disjoint files alone are not enough when hooks run across the tree. If isolation truly isn't possible (rare), serialize those implementers rather than parallelize.

### 4. Tracker-managed state files pollute every agent's commit

If the host project uses a tracker that exports its state on commit (e.g., beads' `issues.jsonl`, sqlite-backed task trackers that write to a tracked path, schema-generators that stage generated artifacts), the export lands in every agent's sandbox on every commit. Each cherry-pick then either (a) re-applies a stale snapshot of the tracker state, (b) conflicts against the host's concurrent state, or (c) leaks private tracker metadata into a downstream merge. Observed concretely with `.beads/issues.jsonl` (~400 lines) and `issues.jsonl` (repo-root mirror) auto-staged by the beads pre-commit hook across 6+ lanes in a single council execution.

**Fix (preferred):** instruct each implementer spawn prompt to run `git reset HEAD <state-file> && rm -f <state-file>` after staging and before committing. If the hook auto-stages on *every* `git commit`, the agent may need `git commit --amend -n` once to strip the file; this is the one acceptable use of `--no-verify` during handoff.

**Fix (CEO-side):** `git cherry-pick -n <sha>` then unstage + delete the state file before `git commit`. Every cherry-pick. Cheap; skipping it leaks stale state into the target branch.

**Fix (project-side):** gitignore the state file if feasible, or configure the hook to skip inside `.claude/worktrees/`. Both are one-time fixes that eliminate this gotcha for all future councils.

### 5. Worktree sandbox may branch from default branch, not current HEAD

The `isolation: "worktree"` agent-tool default frequently creates the sandbox off `main` (or the configured default branch), not off the branch the CEO is actually working on (`feat/my-branch`, `fix/xyz`). Implementers working off stale bases produce commits that can't cleanly cherry-pick onto the target branch — the agent's diff references functions/files/constants that don't exist in their sandbox but do exist on the CEO's branch. In the worst case the agent *silently adapts* (substitutes a stand-in symbol) and the cherry-pick succeeds with a semantically-wrong test.

**Fix:** include an explicit base-fix instruction in every implementer spawn prompt:

> *Before you touch any code: run `git branch --show-current` (expect `worktree-agent-*`), then `git log --oneline -3` and confirm the target branch's HEAD commit SHA is reachable. If NOT, `git checkout -B <local-branch> <target-branch>` to put yourself on the right base. Do not silently adapt to the stale base — the CEO cherry-picks your commits onto the target, and silent adaptations produce semantically-wrong merges.*

Agents that self-recover this way produce clean, conflict-free cherry-picks. Agents that don't either ship wrong-base commits or waste time rebasing post-hoc.

### 6. Per-lane CHANGELOG coordination is brittle; prefer a CEO normalizer pass

Multiple parallel worktrees editing `CHANGELOG.md` under overlapping headings produce manual cherry-pick conflicts even when file-level coordination is explicit. Instructing Lane A "edit under the first `### Fixed` heading" and Lane B "coalesce both `### Fixed` headings" fails if Lane B lands first — now there's no "first" heading for Lane A to target, and the diff context lines drift. The conflict is small but manual.

**Fix:** tell every implementer to skip `CHANGELOG.md` entirely. The CEO runs a single normalizer pass at the end, accumulating all `Added` / `Changed` / `Fixed` / `Deprecated` / `Removed` / `Security` entries across lanes into the `Unreleased` section in one commit. One pass, zero conflicts, consistent formatting. Agents report their intended CHANGELOG line in their completion summary; the CEO aggregates.

**Corollary:** the decision log's "Shared-surface callouts" should list `CHANGELOG.md` as CEO-owned when the epic has ≥2 parallel implementation lanes. Per-lane coordination is only robust when exactly one lane writes to the file.

## References

Load on demand:

- `references/protocol.md` — deeper version of the 5-phase protocol; consult if the debate gets messy.
- `references/opening-prompt-template.md` — paste-ready scaffold for Phase 1.
- `references/decision-log-template.md` — paste-ready scaffold for Phase 5.
- `references/roles/<slug>.md` — one role brief per seat. Load the relevant ones when assembling spawn prompts.

## Related skills

- `using-agent-skills` — meta-skill for skill discovery.
- `beads:beads` — issue tracker commonly used for deferred follow-ups in projects that use it.
- `spec-driven-development` — often runs BEFORE a council debate, to produce the spec the council is debating.
- `planning-and-task-breakdown` — often runs AFTER a council debate, to decompose the decision into implementable tasks.
