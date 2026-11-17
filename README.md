# Design Council

> Convene a parallel team of specialist Claude agents with independent contexts — they argue your call, partition the work, and ship it.

## What problem it solves

A single context, no matter how capable, evaluates a cross-cutting design decision from one vantage point. "Should this API paginate cursor-style or offset-style?" touches integration, performance, security, docs, and product — and the answer you get depends on which hat you happened to be wearing when asked. Iterating with the same context doesn't fix this: each turn inherits the prior framing.

Design Council spawns each seat as an **independent Claude agent with its own context**. They don't inherit yours. The `security-engineer` has no cached rationale for the principal-engineer's architecture; the `accessibility-specialist` doesn't share the `performance-engineer`'s priors about batching. Disagreement is structural, not simulated. The CEO's job is to route the disagreement productively and write the decision down.

## How it works

0. **Plan card (you confirm before anything spawns).** The CEO shows a one-screen card: mode (debate / review), roster with per-seat model, rough token/wall-clock budget, and the drafted opening question. You reply `go`, `swap X for Y`, `drop X`, `add X`, or `abort`.
1. **Brief (single context, yours).** The CEO gathers binding constraints from `CLAUDE.md`, referenced specs, and the project's memory system (including beads if detected). **Skill self-audit runs here too:** the CEO greps auto-memory and prior decision logs for entries about the council skill itself; any memory that contradicts the skill's own prescriptions wins (memory is written after real failures, so it's ground truth). Everything lands **once** in `~/.claude/councils/<slug>/brief.md` — every seat's spawn prompt points to that path instead of inlining the constraints.
2. **Convene (parallel fan-out).** In one message, the CEO spawns every seat as a teammate via `Agent(name: <seat>, model: ..., ...)` — the session's implicit agent team needs no setup step. Every spawn prompt inlines the delivery rules (handshake first, SendMessage for anything that matters, structured shutdown response, no peer DMs until the CEO opens them).
3. **Handshake verify (Phase 2.5).** The CEO counts incoming `HANDSHAKE` messages, re-spawns or drops seats that never started, emits a structured `HANDSHAKE: N/N ok | verdict=PROCEED` line, then opens peer DMs.
4. **Cross-talk (peer DMs, bounded).** Seats post opening verdicts (`APPROVE` / `CONCERNS` / `BLOCK`), then DM each other directly via `SendMessage` to argue the live disagreements. The CEO routes — pairs disagreers, invites tiebreakers, forces narrowing questions, bridges converged tracks. Hard cap of 3 rounds. Review mode skips cross-talk by default.
5. **Arbitrate (CEO writes).** For every disagreement cross-talk didn't resolve, the CEO writes a 3–5 sentence decision with rationale engaging the loser's argument. Strategic / budget / legal / cross-team calls escalate to the user.
6. **Log + teardown.** The CEO posts the draft decision log to chat for your `save` / `amend` / `discard`. On save: `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md` (outside any project repo). Includes opening prompt, roster, resolved disagreements, arbitration decisions, deferred items with tracker IDs, and an execution plan with file-ownership mapping. Each seat is shut down with a `shutdown_request`.

**Stop early** at any phase by saying "stop the council" — the CEO sends each seat a shutdown request and saves a partial log with `status: halted`.

## Benefits

- **Genuine parallelism.** Independent contexts reasoning concurrently, not sequential turns. Wall-clock cost ≈ slowest seat, not sum of seats.
- **Structurally independent perspectives.** Each seat is a separate Claude with its own context — no priming bleeds across roles.
- **Direct peer debate.** `SendMessage` lets seats argue with each other without round-tripping through the CEO, which is how real cross-discipline reviews work.
- **Constraints written once.** The shared `brief.md` pattern means the CEO writes binding constraints once rather than inlining them into every spawn prompt.
- **Durable artifact outside any repo.** Decision logs are portable — they outlive branch pivots, repo renames, and migrations. `~/.claude/councils/` is per-user artifact space.
- **Merge-conflict-aware execution plan.** Phase 5 closes with file-ownership mapping so parallel implementers — spawned as fresh agents with `isolation: "worktree"` after teardown — can ship the decision without colliding. See `references/implementation-handoff.md` for the full playbook (including why `git checkout <SHA> -- <files>` beats `cherry-pick` for mixed-base handoffs).

## Tradeoffs

- **Token cost.** 8+ parallel contexts, each receiving a role brief + opening prompt + `Read` of the shared brief, then 1–3 cross-talk rounds. Expect roughly **10–20×** the tokens of a single-context review. This is why the "Do not invoke" list is explicit: small decisions don't earn the cost.
- **Orchestration latency.** Even parallel, each round ends only when the last-to-respond seat is in. Debates where one seat goes deep on research dominate wall-clock.
- **Not a substitute for domain expertise.** Seats are strong generalists shaped by their role briefs, not replacements for a named SME. Use the `domain-expert` opt-in or escalate to a human for narrowly technical calls.
- **Silent-promise risk on DEFER.** A deferred decision without a tracker item decays to nothing. The Phase 5 silent-promise guard catches this when a tracker is detected; without one, the prose entry in the log is the only handle.

## When to invoke

Both conditions must hold:

- Decision or review crosses **≥2 specialist domains**, AND
- Output must **survive handoff** — a decision log, tracker items, or an execution plan.

Natural trigger phrases: "convene the council", "design debate", "council review", "get the team together", "run a design review", "debate this design".

**Do not invoke** for simple bug fixes, single-specialist questions, library/tool picks, or pure exploration (→ `Explore`). The token cost isn't earned.

## Default roster (size matches decision shape)

**Full 11 seats:** `principal-engineer` · `platform-engineer` · `integration-engineer` · `test-engineer` · `qa-engineer` · `security-engineer` · `performance-engineer` · `product-manager` · `ui-ux-designer` · `accessibility-specialist` · `technical-writer`

**Opt-ins** (CEO adds based on decision shape): `devops-engineer` · `sre-engineer` · `finops-engineer` · `legal-compliance` · `domain-expert` · `historian`

**Dynamic sizing is the default.** No runtime UI → drop `ui-ux-designer` + `accessibility-specialist`. No user input / no infra → drop `security-engineer` + `platform-engineer` too. Internal-tooling decisions often land on 4–6 seats. The plan card (Phase 0) shows the chosen roster; you can adjust before spawn.

## Model defaults (surfaced up-front)

Teammates run on the CEO's model unless the spawn names one, so the CEO sets a model (and, where it matters, an effort level) on every seat:

- **Opus** for synthesis-heavy seats (`principal-engineer`, `product-manager`, `technical-writer`, `historian`).
- **Sonnet** for analytical seats (`test-engineer`, `performance-engineer`, `platform-engineer`, `qa-engineer`).
- **All-Opus** when the user frames the task as "high quality bar" or "ship to production."

The plan card displays the chosen model and effort per seat so you never discover them mid-debate.

## Slash command

```
/design-council:design-council [decision-or-focus]
```

Optional argument: the decision or codebase area to debate (e.g. `/design-council:design-council should we extract the billing service into its own repo?`). Without the argument, the CEO asks for the focus before drafting the Phase 0 plan card. Trigger phrases ("convene the council", "design debate", etc.) also work for proactive invocation.

## Integrations

### Beads

When the invoking project uses [beads](https://github.com/gastownhall/beads), this skill automatically:

- Includes `bd memories`, `bd ready`, and `bd show <id>` output in the Phase 1 brief.
- Translates Phase 4 `DEFER` decisions into `bd create` commands before Phase 5 teardown.
- Closes the primary bead under debate during teardown (with `--force` if beads flags a known dependency-inversion).
- Records filed bead IDs in the decision log frontmatter (`primary-tracker-id`, `linked-tracker-ids`).

Detection: `.beads/` at the invoking project's git root, OR `bd` on `$PATH`. Concretely: `test -d .beads || command -v bd`.

When no tracker is detected, deferred items remain prose in the decision log and no tracker commands are run. The protocol is strictly additive — beads is never required. See `skills/design-council/references/tracker-integration.md` for the adapter contract used to wire new trackers.

### Split-pane observability

To watch seats debate in real time, run Claude Code inside **tmux** or **iTerm2** and set `"teammateMode": "tmux"` (or the default `"auto"`) in your Claude Code `settings.json`. Each seat renders in its own pane. Without a split-pane-capable terminal, seats still run — they just share the main pane and you cycle through them with Shift+Down.

This is a Claude Code harness setting, not a plugin requirement.

## Installation

```
/plugin marketplace add sjsyrek/claude-plugins
/plugin install design-council@sjsyrek
```

The marketplace lives at [sjsyrek/claude-plugins](https://github.com/sjsyrek/claude-plugins) and points at this repo. To pin a version, clone this repo at a tag (e.g., `v0.2.0`) and load via `/plugin marketplace add <local-path>` pointing at a checkout with its own `.claude-plugin/marketplace.json`.

## Runtime requirements

- Claude Code **2.1.178 or later**, with agent teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in your environment or the `env` block of `settings.json`. Each session then has one implicit team; there is no team setup step.
- `Agent` with `name`, `model`, and `effort` — spawns each seat as a teammate
- `SendMessage` — CEO-to-seat and seat-to-seat DMs, and the shutdown protocol

## Decision log location

`~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md` — per-user artifact space, **not** plugin-owned. The shared brief artifact lives alongside at `~/.claude/councils/<slug>/brief.md`.

## Version history

See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT
