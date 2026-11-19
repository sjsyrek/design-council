# design-council eval suite

Regression tests for the skill, run with Claude Code's `claude plugin eval` (2.1.326+). Each case runs a fresh headless Claude in a sandbox (its own workspace and `home/`), optionally twice: with the plugin and without it. The score difference (Δ) shows the plugin is doing the work.

| Case | Tier | Tag | Checks |
|---|---|---|---|
| `01-trigger-plan-card` | 1 | `teams-on` | "Convene the council…" invokes the skill; it stops at a plan card with mode, a sized roster, model **and effort** per seat, budget and opening question; no `Agent` spawn before `go`. |
| `02-teams-off` | 1 | `teams-off` | With agent teams off, the skill names `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, spawns nothing, and doesn't edit settings. See the caveat below. |
| `03-neg-quick-question` | 1 | `teams-on` | Should **not** fire on a one-file factual question. |
| `10-e2e-three-seats` | 2 | `teams-on` | Pre-approved 3-seat debate on the implicit team: named spawns, `HANDSHAKE: 3/3`, "peer DMs are open" sent per seat, no `TeamCreate`/`TeamDelete`/broadcast (and no `ToolSearch` lookup of the team tools, which is how an outdated skill shows up now that they no longer exist), `shutdown_request` per seat, and a decision log with verdict table, rationale and execution plan. |

Each case's `scaffold.sh` generates the same tiny CLI with a token-caching proposal to debate. The harness only accepts a scaffold path inside the case directory, so every case carries its own copy; keep them identical when you change one.

## Running

Agent teams must be on for the `teams-on` cases. Run one case per invocation (see Gotchas):

```sh
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude plugin eval . --case 01-trigger-plan-card --runs 1 \
  --ablation with-without --scaffold --trust-plugin --allow-tools Bash --no-publish --max-cost-usd 1.5

CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude plugin eval . --case 03-neg-quick-question --runs 1 \
  --ablation with-without --scaffold --trust-plugin --no-publish --max-cost-usd 1

# Tier 2: one real three-seat council (SendMessage must be granted, or no seat can talk)
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude plugin eval . --case 10-e2e-three-seats --runs 1 \
  --ablation none --scaffold --trust-plugin --allow-tools Bash Write SendMessage --no-publish --max-cost-usd 4
```

Results land in `evals/results/` (gitignored); add `--keep-temp` to keep each run's sandbox and `trace.jsonl`.

**`02-teams-off` caveat.** The CLI applies the `env` block of your `~/.claude/settings.json` to the sandboxed run, so if that sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, unsetting it in the shell has no effect and this case can't pass. Run it only on a setup where teams are enabled from the shell rather than settings:

```sh
env -u CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS claude plugin eval . --case 02-teams-off --runs 1 \
  --ablation none --scaffold --trust-plugin --allow-tools Bash Edit Write --no-publish --max-cost-usd 1
```

## Gotchas

- `--scaffold` runs the case's bash as you; only use it on case files you've read.
- `--case` takes a simple glob (`01-*`), not character classes. Repeated `--tag` flags may widen rather than narrow the selection — one `--case` per invocation is the safe way to keep the expensive Tier 2 case out of a Tier 1 run.
- Write flags out literally in zsh: a variable holding several flags is passed as a single argument.
- `case.yaml` can only set `EVAL_*` environment variables; anything else comes from the operator's shell (and from `settings.json`, as above).
- Grader regexes are JavaScript: no inline `(?i)`. Use a character class (`[Pp]eer`) or a regex grader's `flags: i`.
- A tool the case needs must be in both `allowed_tools` and `--allow-tools` when it's gated. The runner warns `cannot pass with the granted tools` — treat that as a broken run.
- On a Pro/Max subscription, `costUsd` is notional (API-price equivalent) but runs count against your plan's usage limits. The Tier 2 case measured about $1.10 notional and ~14 minutes.
