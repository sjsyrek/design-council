---
name: design-council
description: Use when the user says "convene the council", "design debate", "council review", "get the team together", "run a design review", or "debate this design"; OR describes a cross-domain decision or review with real stakes — architecture pivot, API surface, pre-release hardening, codebase-wide audit. Convenes parallel role-specialized agent-team teammates (Opus on synthesis seats, Sonnet on analytical seats) who debate in real time via inter-agent messaging while the invoking Claude serves as CEO. Do NOT invoke for single-specialist questions, bug fixes, or quick library picks.
argument-hint: [decision-or-focus]
version: 0.4.1
---

# design-council

Convene a **parallel team of role-specialized agents** to debate a non-trivial technical decision (or audit a codebase in Review mode) in real time. The invoking Claude is **CEO**: convenes, routes peer-DMs, arbitrates deadlocks, writes a one-page decision log. Every teammate has its own context — not a subagent inheriting yours — so disagreement is structural, not simulated.

## What the user sees

1. **Plan card.** Before any seat spawns, the CEO shows a one-screen card: mode, roster, per-seat model and effort, rough token/wall-clock budget, drafted opening question. You reply `go`, `swap X for Y`, `drop X`, `add X`, or `abort`.
2. **Handshake status.** After spawn, the CEO emits one line — e.g. `HANDSHAKE: 8/8 ok | verdict=PROCEED` — so you know every seat actually started.
3. **Cross-talk.** Seats post opening verdicts, DM each other to debate, CEO routes deadlocks. Bounded: 3 rounds max.
4. **Log preview.** Before saving, the CEO posts the draft decision log to chat. Reply `save`, `amend <note>`, or `discard`.
5. **Output.** One-page decision log at `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md` (outside any repo).
6. **Stop early.** Say "stop the council" at any phase — CEO sends each seat a shutdown request, saves a `status: halted` partial log.

Invocation: `/design-council:design-council [decision-or-focus]` or any of the trigger phrases below. If invoked with no decision or focus, ask the user for one, then start at Phase 0 — the plan card is never skipped just because the invocation was explicit.

## Requirements

Agent teams must be enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (Claude Code 2.1.178+). Check with `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` before Phase 0. If it is unset, tell the user — seats spawned without it are ordinary subagents that cannot DM each other — and stop; enabling it is a user settings change, not something to do on their behalf.

Also confirm `SendMessage` is among your tools; a host or permission setup can withhold it even with teams on. Without it, seats can't handshake, debate, or answer a shutdown request — tell the user, and run only with their consent as independent position papers with no cross-talk.

Each session has exactly one implicit team. There is no team-creation or team-deletion step: an `Agent` call with a `name` adds that seat as a teammate; the CEO is `team-lead`.

## When to invoke

Both conditions must hold: (a) decision or review crosses **≥2 specialist domains**, and (b) output must **survive handoff** — a decision log, tracker items, or an execution plan.

Do **not** invoke for: bug fixes, single-specialist questions, library/tool picks, pure exploration (→ `Explore`), one-turn sanity checks.

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

**Opt-ins:** `devops-engineer` (deploy risk, CI/CD, rollback), `sre-engineer` (production reliability, SLOs, blast radius, rollback validation; pair with `devops-engineer` when production stakes are high), `finops-engineer` (cloud/API cost, unit economics, resource lifecycle), `legal-compliance` (privacy, licensing), `domain-expert` (subject-matter SME), `historian` (codebase precedent on mature repos).

**Dynamic sizing is the default.** No runtime UI → drop ui-ux + a11y. No user input / no infra → drop security + platform. Internal-tooling decisions can be 4–6 seats. The full 11 plus opt-ins only when every role-lens applies. The CEO decides at Phase 0 and surfaces the roster in the plan card.

## Model and effort (state them, don't default quietly)

Teammates run on the CEO's model unless the spawn names one, so set `model` on every seat explicitly. Default: `model: "opus"` for synthesis-heavy seats (principal-engineer, product-manager, technical-writer, historian) and `model: "sonnet"` for analytical seats (test, performance, platform, qa). On a high-quality-bar framing, all Opus. Set `effort` per seat too when it should differ from the model's default (e.g. `high` for principal-engineer on a contentious architecture call). The plan card shows both; users can adjust before spawn.

## Variants

- **Debate mode** (default) — single decision, verdict tags (APPROVE / CONCERNS / BLOCK), peer DMs resolve disagreements, CEO arbitrates what's left.
- **Review mode** — codebase audit, P0/P1 findings, cross-talk skipped, CEO dedupes and files tracker items. See `references/review-mode.md`.

## Protocol (six phases)

| Phase | Name | CEO does |
|-------|------|----------|
| 0 | **Plan card** | Draft roster + models + effort + budget + opening question; show to user; wait for `go` |
| 1 | **Brief** | Gather binding constraints verbatim (CLAUDE.md, spec, memory, tracker); **self-audit** — grep auto-memory + prior decision logs for entries about the council skill; flag any memory-vs-skill contradiction and follow memory; write everything to `~/.claude/councils/<slug>/brief.md` once; draft opening prompt |
| 2 | **Convene** | One `Agent(name: <seat>, model: …, prompt: …)` call per seat, all in one message; every spawn prompt points to `brief.md` |
| 2.5 | **Handshake verify** | Count `HANDSHAKE` messages; re-spawn or drop seats that never started; emit `HANDSHAKE: N/N ok`; then tell every seat that peer DMs are open |
| 3 | **Cross-talk** | Route peer DMs, ask narrowing questions, bridge converged tracks; **3-round hard cap**. Skipped by default in Review mode. |
| 4 | **Arbitrate** | Write decision + rationale for every unresolved disagreement. Escalate strategic/legal/budget to user. Every `DEFER` needs a revisit criterion + filed tracker item (if a tracker is detected). |
| 5 | **Log + teardown** | Post draft log to chat; on user `save`, persist to `~/.claude/councils/`. Send `shutdown_request` to each seat by name and wait for the responses. |

Full protocol: `references/protocol.md`. Opening-prompt scaffold: `references/opening-prompt-template.md`. Decision-log scaffold: `references/decision-log-template.md`. Role briefs: `references/roles/<slug>.md`.

## Protocol contract for every spawned seat

Each spawn prompt inlines these delivery rules, because a seat cannot infer them from its role brief:

1. Reach the CEO with `SendMessage(to: "team-lead")`. The CEO only sees a seat's last turn text in an idle notice, and peers see nothing a seat doesn't message to them.
2. First action: a handshake whose message starts with `HANDSHAKE <seat>:`. Without it the seat is indistinguishable from a spawn that never started.
3. Positions and findings go out via `SendMessage`. Answer a `shutdown_request` with the structured `shutdown_response` (echo the `request_id`), not prose.
4. Don't DM peers until the CEO says peer DMs are open — a seat still starting up can miss a DM.

Canonical wording with peer-DM addressing: `references/protocol.md` Phase 2.

## Rules

- **Agents are peers with independent contexts.** Your conversation is not shared.
- **Peer-DM first, CEO-route second.** Seats DM each other; CEO routes only tiebreakers, stalls, escalations.
- **CEO never takes a seat and never writes application code.** Orchestration, routing, arbitration, record-keeping only. Shipping uses fresh isolated agents (see `references/implementation-handoff.md`).
- **The opening prompt carries the constraints** — baked into `brief.md` and every spawn prompt, so they can't be forgotten mid-debate.
- **Round budget is hard.** 3 cross-talk rounds max.
- **Every CEO decision is written with rationale.** Silence is not a resolution.
- **Decision log lives outside any repo.** Default `~/.claude/councils/`.
- **Scope discipline.** Unrelated issues surfaced in debate → new tracker item, never a side-diff.
- **Memory beats stale skill text.** If a memory entry contradicts a prescription in this file or `references/protocol.md`, follow memory — it was written after a real failure. Flag the contradiction in `brief.md` and record the drift in the decision log's emergent-insights appendix.

## Failure modes this skill guards against

| # | Mode | Guard |
|---|------|-------|
| 1 | Runaway debate | 3-round cross-talk cap |
| 2 | Silent CEO | Every unresolved item requires a written decision |
| 3 | Constraint re-discovery mid-debate | `brief.md` is pre-written |
| 4 | Leaked decision logs | Default path is outside any repo |
| 5 | Lingering teammates | Teardown sends `shutdown_request` to every seat |
| 6 | Silent spawn failure | Phase 2.5 handshake verification |
| 7 | Findings left in a seat's own transcript | Contract rule 3 in every spawn prompt |
| 8 | Silent-promise DEFERs | Phase 5 tracker-ID-or-demote gate |

Harness gotchas (worktree isolation vs. named teammates, worktree cwd leaks, commit-hook races, tracker-state pollution, mixed-base merges, CHANGELOG conflicts) live in `references/implementation-handoff.md` — loaded only when the CEO reaches the shipping sub-step.

## Integrations

- **Tracker integration** (auto-detected, beads first-class): `references/tracker-integration.md`.
- **Split-pane observability** (tmux / iTerm2 via the `teammateMode` setting): optional Claude Code harness feature, not a plugin requirement.
