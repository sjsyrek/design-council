---
name: design-council
description: Use when the user says "convene the council", "design debate", "council review", "get the team together", "run a design review", or "debate this design"; OR describes a cross-domain decision or review with real stakes — architecture pivot, API surface, pre-release hardening, codebase-wide audit. Convenes parallel role-specialized agents (default Opus) who debate in real time via inter-agent messaging while the invoking Claude serves as CEO. Do NOT invoke for single-specialist questions, bug fixes, or quick library picks.
version: 0.2.0
---

# design-council

Convene a **parallel team of role-specialized agents** to debate a non-trivial technical decision (or audit a codebase in Review mode) in real time. The invoking Claude is **CEO**: convenes, routes peer-DMs, arbitrates deadlocks, writes a one-page decision log. Every teammate has its own context — not a subagent inheriting yours — so disagreement is structural, not simulated.

## What the user sees

1. **Plan card.** Before any seat spawns, the CEO shows a one-screen card: mode, roster, per-seat model, rough token/wall-clock budget, drafted opening question. You reply `go`, `swap X for Y`, `drop X`, `add X`, or `abort`.
2. **Handshake status.** After spawn, the CEO emits one line — e.g. `HANDSHAKE: 8/8 ok | verdict=PROCEED` — so you know every seat actually started.
3. **Cross-talk.** Seats post opening verdicts, DM each other to debate, CEO routes deadlocks. Bounded: 3 rounds max.
4. **Log preview.** Before saving, the CEO posts the draft decision log to chat. Reply `save`, `amend <note>`, or `discard`.
5. **Output.** One-page decision log at `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md` (outside any repo).
6. **Stop early.** Say "stop the council" at any phase — CEO broadcasts shutdown, saves a `status: halted` partial log, cleans up.

## When to invoke

Both conditions must hold: (a) decision or review crosses **≥2 specialist domains**, and (b) output must **survive handoff** — a decision log, tracker items, or an execution plan. Natural triggers: "convene the council", "design debate", "council review", "run a design review", "debate this design", "get the team together".

Do **NOT** invoke for: bug fixes, single-specialist questions, library/tool picks, pure exploration (→ `Explore`), one-turn sanity checks.

## Default roster (size matches decision shape)

| # | Slug | Owns |
|---|------|------|
| 1 | `principal-engineer` | Architecture, module boundaries, simplicity (opens the debate) |
| 2 | `platform-engineer` | Systems, infra, data shape, operational cost, observability |
| 3 | `integration-engineer` | Downstream consumers, third-party developers, backwards compat |
| 4 | `test-engineer` | TDD, mutation ritual, coverage, assertion hygiene |
| 5 | `qa-engineer` | User flows ↔ spec alignment, regression surface, manual test plan |
| 6 | `security-engineer` | Input validation, secrets, path safety, error sanitization |
| 7 | `performance-engineer` | Batching, memory, concurrency, measurement-before-optimization |
| 8 | `product-manager` | UX alignment, product coherence, best-practice conformance |
| 9 | `ui-ux-designer` | Ergonomics, visual consistency, interaction design |
| 10 | `accessibility-specialist` | a11y, keyboard nav, screen reader, contrast |
| 11 | `technical-writer` | Docs, in-app help, CHANGELOG, API reference |

**Opt-ins:** `devops-engineer` (deploy risk, CI/CD, rollback), `finops-engineer` (cloud/API cost), `legal-compliance` (privacy, licensing), `domain-expert` (subject-matter SME), `historian` (codebase precedent on mature repos).

**Dynamic sizing is the default, not an exception.** No runtime UI → drop ui-ux + a11y. No user input / no infra → drop security + platform. Internal-tooling defaults can be 4–6 seats. Full 11+opt-ins only when every role-lens applies. The CEO decides at Phase 0 and surfaces the roster in the plan card.

## Model choice (state it, don't default quietly)

Default: **Opus for synthesis-heavy seats** (principal-engineer, product-manager, technical-writer, historian) and **Sonnet for analytical seats** (test, performance, platform, qa). Override all → Opus on a high-quality-bar framing. The plan card shows which seats got which model; users can adjust before spawn.

## Variants

- **Debate mode** (default) — single decision, verdict tags (APPROVE / CONCERNS / BLOCK), peer DMs resolve disagreements, CEO arbitrates what's left.
- **Review mode** — codebase audit, P0/P1 findings, cross-talk skipped, CEO dedupes and files tracker items. See `references/review-mode.md`.

## Protocol (six phases)

| Phase | Name | CEO does |
|-------|------|----------|
| 0 | **Plan card** | Draft roster + models + budget + opening question; show to user; wait for `go` |
| 1 | **Brief** | Gather binding constraints verbatim (CLAUDE.md, spec, memory, tracker); **self-audit** — grep auto-memory + prior decision logs for entries about the council skill; flag any memory-vs-skill contradiction and follow memory; write everything to `~/.claude/councils/<slug>/brief.md` once; draft opening prompt |
| 2 | **Convene** | `TeamCreate` + parallel `Agent` spawns in **one multi-tool-call message**; every spawn prompt points to `brief.md` (prompt-cache hits across seats) |
| 2.5 | **Handshake verify** | Count incoming handshake DMs; inspect team config for empty `tmuxPaneId`; remediate or drop silent-spawn failures; emit `HANDSHAKE: N/N ok` line |
| 3 | **Cross-talk** | Route peer DMs, ask narrowing questions, bridge converged tracks; **3-round hard cap**. Skipped by default in Review mode. |
| 4 | **Arbitrate** | Write decision + rationale for every unresolved disagreement. Escalate strategic/legal/budget to user. Every `DEFER` needs a revisit criterion + filed tracker item (if a tracker is detected). |
| 5 | **Log + teardown** | Post draft log to chat; on user `save`, persist to `~/.claude/councils/`. Broadcast `shutdown_request`, wait for acks, `TeamDelete`. |

Full protocol: `references/protocol.md`. Opening-prompt scaffold: `references/opening-prompt-template.md`. Decision-log scaffold: `references/decision-log-template.md`. Role briefs: `references/roles/<slug>.md`.

## Protocol contract for every spawned seat

Every spawn prompt **must** inline these four delivery rules. Skipping them silently breaks the council:

1. `SendMessage(to: "team-lead")` is the ONLY channel to the CEO. Plain-text output is invisible.
2. Send a 1-line handshake as the first action. Without it, the seat is indistinguishable from a silent-spawn failure.
3. Final position/findings delivered via `SendMessage`. Writing as plain text then going idle drops work on the floor.
4. Idle-notification `summary` field is ≤200 chars — do not put substantive content there.

Canonical wording with peer-DM addressing: `references/protocol.md` Phase 2.

## Non-negotiable rules

- **Agents are peers with independent contexts.** Your conversation is not shared.
- **Peer-DM first, CEO-route second.** Seats DM each other; CEO routes only tiebreakers, stalls, escalations.
- **CEO never takes a seat, never types application code.** Orchestration, routing, arbitration, record-keeping only. Shipping uses fresh isolated agents (see `references/implementation-handoff.md`).
- **Opening prompt carries the constraints** — baked into `brief.md` and every spawn prompt. Cannot be forgotten mid-debate.
- **Round budget is hard.** 3 cross-talk rounds max.
- **Every CEO decision is written with rationale.** Silence as resolution is banned.
- **Decision log lives outside any repo.** Default `~/.claude/councils/`.
- **Scope discipline.** Unrelated issues surfaced in debate → new tracker item, never a side-diff.
- **Memory beats stale skill text.** If a memory entry contradicts a prescription in this file or `references/protocol.md`, memory wins — it was written after a real failure. Flag the contradiction in `brief.md`, follow memory, record the drift in the decision log's emergent-insights appendix.

## Failure modes this skill guards against

| # | Mode | Guard |
|---|------|-------|
| 1 | Sequential-thinking regression | Parallel-spawn template is mandatory (Phase 2) |
| 2 | Runaway debate | 3-round cross-talk cap |
| 3 | Silent CEO | Every unresolved item requires written decision |
| 4 | Constraint re-discovery mid-debate | `brief.md` is pre-written and cached |
| 5 | Leaked decision logs | Default path is outside any repo |
| 6 | Zombie teammates | Teardown is protocol-enforced |
| 7 | Silent spawn failure | Phase 2.5 handshake verification |
| 8 | Plain-text findings lost to floor | Universal rule #3 in every spawn prompt |
| 9 | Silent-promise DEFERs | Phase 5 tracker-ID-or-demote gate |

Harness gotchas (worktree cwd leaks, commit-hook races, tracker-state pollution, mixed-base merges, CHANGELOG conflicts) live in `references/implementation-handoff.md` — loaded only when the CEO reaches the shipping sub-step.

## Integrations

- **Tracker integration** (auto-detected, beads first-class): `references/tracker-integration.md`.
- **Split-pane observability** (tmux / iTerm2 via `teammateMode` setting): optional Claude Code harness feature, not a plugin requirement.

## Related skills

- `using-agent-skills` — meta-skill for skill discovery.
- `spec-driven-development` — often runs BEFORE a council, to produce the spec being debated.
- `planning-and-task-breakdown` — often runs AFTER a council, to decompose the decision into implementable tasks.
- `beads:beads` — tracker commonly used for deferred follow-ups.
