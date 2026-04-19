---
name: design-council
description: This skill should be used when the user asks to "convene the council", "design debate", "get the team together", "council review", "run a design review", "debate this design", or describes a non-trivial technical decision that benefits from multiple specialist perspectives — architecture choices, API shape, significant refactors, security review with stakes, cross-cutting performance work, or feature design where UX, engineering, and product all have standing. Convenes a parallel team of role-specialized agents, each with its own context, who debate in real time via inter-agent messaging while the invoking Claude serves as CEO — convening, routing, and arbitrating unresolved disagreements.
version: 0.1.0
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

### Phase 3 — Cross-talk (peer DMs + CEO routing, bounded)

**Hard bound: 3 rounds.** A round starts when the CEO prompts the team and ends when replies settle (idle notifications stop arriving).

Each round:

1. CEO reviews opening positions + any peer-DM summaries (automatically surfaced via idle notifications).
2. CEO identifies the top 2–4 live disagreements.
3. For each disagreement, CEO chooses one of:
   - **Pair disagreers**: `SendMessage(to: <seat_A>, message: "You and <seat_B> disagree on <X>. DM them directly — try to converge or sharpen the disagreement.")` — peer DMs take over.
   - **Invite tiebreaker**: include a third seat whose domain bears on the dispute (e.g., `test-engineer` between `security-engineer` and `performance-engineer`).
   - **Narrowing question**: `SendMessage(to: <seat>, message: "What's the concrete scenario where <X> breaks? Cite file:line.")` — forces vagueness into specificity.
4. CEO closes the round when responses settle. Marks each disagreement as:
   - `RESOLVED` — team converged.
   - `SHARPENED` — still disagree but on a crisper point.
   - `STUCK` — deadlocked.

Cross-talk ends when: all disagreements `RESOLVED`, OR 3 rounds elapsed, OR CEO declares further rounds unproductive.

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
- Deferred items → follow-up tracker IDs
- **Execution plan** — ordered tasks with file-ownership mapping and a merge-conflict strategy (see `protocol.md` Phase 5)
- **Length cap: one page. Executive summary, not transcript.**

Teardown:

1. `SendMessage(to: "*", message: {type: "shutdown_request", reason: "council concluded"})`
2. Wait for `shutdown_response` from each teammate.
3. `TeamDelete()` to remove team and shared task list.

## Key rules (non-negotiable)

- **Agents are peers with independent contexts.** Your conversation is not shared with any teammate. Everything they need is in their spawn prompt.
- **Peer-DM first, CEO-route second.** Teammates DM each other for domain-to-domain debate. CEO routes only for tiebreakers, stalls, or strategic calls.
- **CEO never takes a seat.** Convene, route, arbitrate, record. Never draft positions. Never critique. Never debate.
- **CEO never writes code or implements anything.** Orchestration, routing, arbitration, and record-keeping are the CEO role. Writing source code, writing implementation tests, running `bd update --claim`, or starting a TDD cycle is seat-work. Shipping can be done **by this same team, re-briefed as implementers per the execution plan** (preferred — the team is already warm with the decision and binding constraints), or by a freshly spawned "crew-<slug>" implementation team, or by a downstream session. In all three paths the CEO stays off the keyboard for application code.
- **Execution plan must address merge conflicts.** The Phase 5 log's execution plan partitions follow-up work so parallel implementers do not collide. Map each task to the files it will touch; serialize tasks that touch the same file; call out shared-surface hotspots (manifest files, lockfiles, shared types) and assign them to a single task. If the project has agent-teamwork guidelines (e.g., `CLAUDE.md` worktree rules), mirror them.
- **Opening prompt carries the constraints.** They are baked into every teammate's spawn prompt — cannot be forgotten mid-debate.
- **Round budget is hard.** 3 cross-talk rounds max.
- **Every CEO decision is written with rationale.** Silence as resolution is banned.
- **Decision log stays outside any repo.** Default `~/.claude/councils/`.
- **Shutdown is protocol.** Use `shutdown_request` — do not leak teammates.
- **Scope discipline.** Unrelated issues surfaced in debate → new tracker item, never a side-diff.

## Tracker integration (optional, auto-detected)

This skill composes with external issue trackers when present. Detection is explicit and fails-safe — the skill's core protocol runs identically with or without a tracker.

**Supported today: beads** (https://github.com/gastownhall/beads).

**Detection:** `.beads/` directory at the invoking project's git root, OR `bd` binary on `$PATH`. Concretely: `test -d .beads || command -v bd`.

**When beads is detected, the skill automatically:**

- **Phase 1 brief:** runs `bd memories`, `bd ready`, and `bd show <id>` for any bead ID the user references. Output is included verbatim in the opening prompt.
- **Phase 4 arbitration:** every `DEFER` decision is translated into a `bd create --title=... --description=... --type=task --priority=N` command, executed before Phase 5 teardown. The filed bead ID is recorded in the decision log as the action handle.
- **Phase 5 teardown:** if a primary bead was under debate, `bd close <id>` runs before `TeamDelete`. Use `--force` if beads flags a known epic-dependency-inversion — that's a beads behavior, not a skill bug. The CEO verifies every DEFER has a filed bead ID before declaring teardown complete.

**When no tracker is detected:** deferred items remain prose entries in the decision log. The CEO does not invent commands for a tracker that isn't there.

**Two-list discipline (when beads is present):** `TeamCreate` creates `~/.claude/tasks/<team>/` for session-scoped coordination between teammates during the debate. Persistent work (existing issues, follow-ups, epics) lives in beads. Never duplicate. Never file session-scoped coordination items as beads.

## Failure modes this skill guards against

1. **Sequential-thinking regression** — Parallel spawn is the default; multi-tool-call template is shown explicitly in Phase 2.
2. **Runaway debate** — 3-round cap; CEO forces closure.
3. **Silent CEO** — Every unresolved item requires a written decision.
4. **Constraint re-discovery** — Constraints are in spawn prompts, not passed mid-debate.
5. **Leaked decision logs** — Default path is outside any repo.
6. **Zombie teammates** — Teardown protocol is mandatory.
7. **Role collapse** — Fewer than 6 seats triggers a warning; CEO confirms or adds seats.
8. **CEO seat-creep into implementation** — Shipping can happen via the same team (re-briefed), a new implementation crew, or a handoff. In every case the CEO orchestrates; never types application code.
9. **Collision-blind execution plans** — Follow-up tasks that touch the same files without a sequencing note produce rebase churn. The execution plan maps tasks to files and serializes overlaps.

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
