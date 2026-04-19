# Design Council

> A Claude Code plugin that convenes 11 role-specialized peer agents to debate a non-trivial technical decision in real time. The invoking Claude acts as CEO — convening, routing peer DMs, arbitrating deadlocks, and persisting a one-page decision log.

## What problem it solves

A single context, no matter how capable, evaluates a cross-cutting design decision from one vantage point. "Should this API paginate cursor-style or offset-style?" touches integration, performance, security, docs, and product — and the answer you get depends on which hat you happened to be wearing when asked. Iterating with the same context doesn't fix this: each turn inherits the prior framing.

Design Council spawns each seat as an **independent Claude agent with its own context**. They don't inherit yours. The `security-engineer` has no cached rationale for the principal-engineer's architecture; the `accessibility-specialist` doesn't share the `performance-engineer`'s priors about batching. Disagreement is structural, not simulated. The CEO's job is to route the disagreement productively and write the decision down.

## How it works

1. **Brief (single context, yours).** You describe the decision. The CEO gathers binding constraints from `CLAUDE.md`, referenced specs, and the project's memory system (including beads, if detected — see Integrations below). It drafts an opening prompt and picks which opt-in seats to add.
2. **Convene (parallel fan-out).** In one multi-tool-call message, the CEO spawns every seat via `TeamCreate` + `Agent(... run_in_background: true, team_name: ...)`. Each seat receives its role brief, the binding constraints, and the opening prompt — then runs in its own context.
3. **Cross-talk (peer DMs, bounded).** Seats post opening verdicts (`APPROVE` / `CONCERNS` / `BLOCK`), then DM each other directly via `SendMessage` to argue the live disagreements. The CEO observes via idle notifications and routes: pairs disagreers, invites tiebreakers, forces narrowing questions. Hard cap of 3 rounds.
4. **Arbitrate (CEO writes).** For every disagreement cross-talk didn't resolve, the CEO writes a 3–5 sentence decision with rationale engaging the loser's argument. Strategic / budget / legal / cross-team calls escalate to the user.
5. **Log + teardown.** One-page decision log at `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md` (outside any project repo). Includes opening prompt, roster, resolved disagreements, arbitration decisions, deferred items with tracker IDs, and an execution plan with file-ownership mapping for parallel implementers. Team shuts down via `shutdown_request`; `TeamDelete` removes the shared task list.

## Benefits

- **Genuine parallelism.** 11 independent contexts reasoning concurrently, not 11 sequential turns. Wall-clock cost ≈ slowest seat, not sum of seats.
- **Structurally independent perspectives.** Each seat is a separate Claude with its own context — no priming bleeds across roles.
- **Direct peer debate.** `SendMessage` lets seats argue with each other without round-tripping through the CEO, which is how real cross-discipline reviews work.
- **Real-time observability.** In Claude Code, the running team is visible in built-in monitoring; tmux-based agent dashboards (if you run one) make each seat's pane watchable as the debate unfolds.
- **Durable artifact outside any repo.** The decision log is portable — it outlives branch pivots, repo renames, and migrations. `~/.claude/councils/` is per-user artifact space.
- **Merge-conflict-aware execution plan.** Phase 5 closes with file-ownership mapping so the same team (re-briefed as implementers) can ship the decision in parallel without collisions.

## Tradeoffs

- **Token cost.** 11+ parallel contexts, each receiving the role brief + full binding constraints + opening prompt, then 1–3 cross-talk rounds. Expect roughly **10–20×** the tokens of a single-context review. This is the reason for the explicit "do not invoke" list: small decisions don't earn the cost.
- **Orchestration latency.** Even parallel, each round ends only when the last-to-respond seat is in. Debates where one seat goes deep on research dominate wall-clock.
- **Warmup overhead.** Seats start cold — their first output is partly calibration ("who am I talking to, what's the constraint"). The 3-round budget includes this warmup.
- **Not a substitute for expertise.** Seats are strong generalists shaped by their role briefs, not replacements for a domain SME. For regulated-industry or narrowly technical calls, use the `domain-expert` opt-in or escalate to a human.
- **Silent-promise risk on DEFER.** A deferred decision with no tracker item decays to nothing. The skill guards against this via Phase 5 verification (see Integrations), but if neither beads nor another tracker is present, the prose entry in the log is the only handle.

## When to invoke

Trigger phrases:

- "convene the council"
- "design debate"
- "council review"
- "get the team together"
- "run a design review"
- "debate this design"

Also triggers proactively when a decision crosses multiple specialist domains (API shape + UX + security; infra + performance + product), or when the user is stuck between 2+ design options and wants structured input.

**Do not invoke** for simple bug fixes, decisions where one specialist is clearly sufficient, or pure research questions — the token cost isn't earned.

## Default roster (11 always-on seats)

principal-engineer · platform-engineer · integration-engineer · test-engineer · qa-engineer · security-engineer · performance-engineer · product-manager · ui-ux-designer · accessibility-specialist · technical-writer

## Opt-in seats (CEO adds based on decision shape)

devops-engineer · finops-engineer · legal-compliance · domain-expert · historian

## Integrations

### Beads

When the invoking project uses [beads](https://github.com/gastownhall/beads), this skill automatically:

- Includes `bd memories`, `bd ready`, and `bd show <id>` output in Phase 1 brief gathering.
- Translates Phase 4 `DEFER` decisions into `bd create` commands before Phase 5 teardown.
- Closes the primary bead under debate during teardown (with `--force` if beads flags a known dependency-inversion).
- Records filed bead IDs in the decision log frontmatter (`primary-tracker-id`, `linked-tracker-ids`).

Detection rule: `.beads/` at the invoking project's git root, OR `bd` on `$PATH`. Concretely: `test -d .beads || command -v bd`.

When no tracker is detected, deferred items remain prose in the decision log and no tracker commands are run. The protocol is strictly additive — beads is never required.

### Adding other trackers

Future support for Jira, Linear, GitHub Issues, and similar trackers follows the same pattern: detect, fetch in Phase 1, translate DEFER in Phase 4, close-and-verify in Phase 5. Contributions welcome.

## Installation

Add the personal marketplace, then install the plugin:

```
/plugin marketplace add sjsyrek/claude-plugins
/plugin install design-council@sjsyrek
```

The marketplace lives at [sjsyrek/claude-plugins](https://github.com/sjsyrek/claude-plugins) and points at this repo. If you need to pin a specific version, clone this repo at a tag (e.g., `v0.1.0`) and load it via `/plugin marketplace add <local-path>` pointing at a checkout that has its own `.claude-plugin/marketplace.json`.

## Runtime requirements

The skill assumes the following tools are reachable via the current session:

- `TeamCreate` / `TeamDelete` — team lifecycle + shared task list
- `Agent` with `name`, `run_in_background`, `team_name` — spawns each seat as a peer
- `SendMessage` — CEO-to-seat and seat-to-seat DMs, plus broadcast
- `TaskCreate` — shared task list

Some of these are deferred tools in Claude Code; they're resolved at spawn time.

## Decision log location

Logs land at `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md` — per-user artifact space, **not** plugin-owned. This path is intentional: decision logs outlive any single project checkout.

## License

MIT
