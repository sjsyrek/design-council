# design-council

A Claude Code plugin that convenes a **parallel team of 11 role-specialized agents** to debate a non-trivial technical decision in real time. The invoking Claude acts as **CEO** — convening, routing peer DMs, arbitrating deadlocks, and persisting a lean decision log.

Every teammate runs in its own context (not a subagent inheriting yours) and can DM peers directly via `SendMessage`. The debate is genuinely inter-agent, not hub-and-spoke.

## What it produces

A one-page decision log at:

```
~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md
```

Contents: opening prompt, binding constraints, roster, resolved disagreements, CEO arbitration decisions with rationale, deferred follow-ups, and an execution plan with file-ownership mapping. Lives outside any project repo by design.

## When to invoke

Trigger phrases:

- "convene the council"
- "design debate"
- "council review"
- "get the team together"
- "run a design review"
- "debate this design"

Also triggers proactively when a decision crosses multiple specialist domains (API shape + UX + security; infra + performance + product), or when the user is stuck between 2+ design options and wants structured input.

**Do not invoke** for simple bug fixes, decisions where one specialist is clearly sufficient, or pure research questions.

## Default roster (11 always-on seats)

principal-engineer · platform-engineer · integration-engineer · test-engineer · qa-engineer · security-engineer · performance-engineer · product-manager · ui-ux-designer · accessibility-specialist · technical-writer

## Opt-in seats (CEO adds based on decision shape)

devops-engineer · finops-engineer · legal-compliance · domain-expert · historian

## Installation

From the marketplace:

```
/plugin marketplace add sjsyrek/design-council
/plugin install design-council@design-council
```

Or install directly by URL:

```
claude plugin install https://github.com/sjsyrek/design-council
```

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
