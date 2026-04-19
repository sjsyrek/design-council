# design-council — Protocol (deeper dive)

This reference expands the 5-phase protocol from `SKILL.md`. Consult when the debate gets messy, when a teammate drifts, or when the CEO needs a reminder of the exact orchestration moves.

## Phase 1 — Brief (before any spawn)

### Assemble binding constraints

Pull from every available source and concatenate verbatim into the opening prompt. Do **not** paraphrase — paraphrasing is where subtle constraints get lost.

1. **`CLAUDE.md`** in the invoking project's cwd. If nested project CLAUDE.mds exist (monorepo), include all that apply.
2. **Plan / spec files** the user referenced. If the user said "debate this design" while pointing at a spec, the spec is part of the brief.
3. **Project memory systems**:
   - Beads (`bd memories`) — run `bd memories` and include anything relevant
   - Auto-memory (`~/.claude/projects/<hash>/memory/MEMORY.md`) — read and include
   - Custom memory files if the project has them
4. **Commit conventions**: peek at recent `git log --oneline | head -20` to infer the conventional-commit style; include it as a constraint if the decision may result in commits.
5. **Privacy context**: if the invoking repo has a public remote (`git remote -v`), flag this — it affects decisions about where artifacts live, what leaks to commit history, etc.

### Decide opt-in seats

Cues and corresponding additions:

| Cue | Add seat |
|-----|----------|
| "deploy", "ship", "release", "CI/CD", "rollback" | `devops-engineer` |
| "PII", "privacy", "GDPR", "license", "legal", "compliance" | `legal-compliance` |
| "cost", "spend", "quota", "budget", "API cost" | `finops-engineer` |
| Product-area jargon user expects agents to know | `domain-expert` |
| "mature codebase", "don't repeat past mistakes", codebase >2 years old | `historian` |
| UI stakes low (backend-only, CLI-only) | Drop `ui-ux-designer` and `accessibility-specialist` |

If the decision is narrowly scoped and ≤6 seats would apply, warn the user and confirm before proceeding — the council pattern is expensive for small decisions. Suggest a lighter tool.

### Draft the opening prompt

Use `opening-prompt-template.md`. Four sections, in order:

1. **Decision question** — one paragraph, specific, answerable.
2. **Binding constraints** — verbatim from sources above.
3. **Non-goals** — what is explicitly out of scope. Prevents scope creep in agent positions.
4. **Success criterion** — how the CEO will know the debate has converged. Usually "all seats APPROVE or CONCERNS with a named resolution path; no BLOCK outstanding."

## Phase 2 — Convene (parallel fan-out)

### The multi-tool-call template

```
TeamCreate(team_name: "council-2026-04-19-session-cache-ttl", description: "Debate: choosing a session-cache TTL policy")

Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "principal-engineer",      subagent_type: "general-purpose", run_in_background: true, prompt: "<principal-engineer role brief>\n\n<binding constraints>\n\n<opening prompt>\n\n<debate-protocol instructions>")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "platform-engineer",       subagent_type: "general-purpose", run_in_background: true, prompt: "<platform-engineer role brief>\n\n<binding constraints>\n\n<opening prompt>\n\n<debate-protocol instructions>")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "integration-engineer",    subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "test-engineer",           subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "qa-engineer",             subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "security-engineer",       subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "performance-engineer",    subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "product-manager",         subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "ui-ux-designer",          subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "accessibility-specialist",subagent_type: "general-purpose", run_in_background: true, prompt: "...")
Agent(team_name: "council-2026-04-19-session-cache-ttl", name: "technical-writer",        subagent_type: "general-purpose", run_in_background: true, prompt: "...")

# Plus any opt-ins from Phase 1
```

**All in one message.** If spawns are sequential, the parallel-first principle is violated.

### The spawn-prompt assembly

For each teammate, the prompt is four concatenated blocks:

```
<role brief: content of references/roles/<slug>.md verbatim>

---

BINDING CONSTRAINTS (these apply to your reasoning and any recommendations you make):

<verbatim content from Phase 1 constraint gathering>

---

DECISION TO DEBATE:

<verbatim opening prompt from Phase 1 draft>

---

DEBATE PROTOCOL:

1. Open by posting to the CEO (via SendMessage(to: "<ceo-name>")) a position paper: ≤300 words, verdict tagged exactly one of APPROVE / CONCERNS / BLOCK, concrete file:line refs when critiquing existing code.
2. During cross-talk, expect peer DMs from other seats about disagreements. Respond directly via SendMessage(to: "<peer-name>"). Do not always loop in the CEO — peer DMs are the primary mechanism.
3. BLOCK requires naming the concrete scenario that breaks. Abstract objections are CONCERNS, not BLOCK.
4. Use TaskCreate on the shared task list to record concrete action items that emerge from the debate (for CEO to triage later).
5. Go idle between turns — normal. The CEO will wake you with SendMessage when your input is needed.
6. On shutdown_request, respond with shutdown_response; approve: true when your work is complete.
```

The CEO's own `name` in the team is whatever TeamCreate sets as the team lead's slug. If the CEO is the invoking Claude (the default), use the spawn prompts to instruct each agent to DM the CEO — they may need to be told the CEO's name explicitly, e.g., "Send your opening position to the team lead via SendMessage(to: 'team-lead')". Read `~/.claude/teams/<team_name>/config.json` after `TeamCreate` to discover the lead's name.

## Phase 3 — Cross-talk (peer DMs + CEO routing)

### How idle notifications work

Every teammate goes idle after each turn. The system auto-delivers idle notifications to the CEO, including:
- The teammate's last message (if addressed to CEO)
- A short summary of peer DMs sent by that teammate

The CEO does NOT poll an inbox. Idle notifications arrive as conversation turns.

### Routing moves (pick one per disagreement, per round)

1. **Pair disagreers.** When two seats have named each other:
   ```
   SendMessage(to: "security-engineer", message: "You and performance-engineer disagree on the 24h cache TTL. DM them directly and try to converge or sharpen the disagreement. Report back when you've either agreed on a resolution or identified the crisp remaining split.")
   ```
2. **Invite tiebreaker.** When two seats are stuck but a third domain bears on it:
   ```
   SendMessage(to: "test-engineer", message: "security-engineer and performance-engineer disagree on caching TTL. Weigh in from the test/regression angle — what's the most testable cache policy? DM both of them.")
   ```
3. **Narrowing question.** When a seat's objection is vague:
   ```
   SendMessage(to: "security-engineer", message: "Your BLOCK on the cache policy cites 'potential PII leak' — name the specific code path and data shape where that happens. Cite file:line.")
   ```
4. **Broadcast (sparingly).** When a major pivot in the opening prompt is needed, or the CEO wants everyone to re-verdict:
   ```
   SendMessage(to: "*", message: "Decision scope has narrowed to 'cache only non-PII response fields'. Re-evaluate your verdict under this narrower scope; reply with your new verdict.")
   ```
   Broadcast is O(team-size) cost — reserve for genuinely all-seats moments.

### Round closure criteria

A round is "closed" when:
- All teammates who received a SendMessage this round have responded, AND
- No new peer-DM summaries have arrived for a reasonable wait.

CEO explicitly marks each live disagreement:
- `RESOLVED` — both parties agreed on a resolution.
- `SHARPENED` — still disagree, but the disagreement is now on a crisper point (progress).
- `STUCK` — no movement.

### When to end cross-talk early

- All disagreements RESOLVED → proceed to Phase 4 (which will be trivially empty) and then Phase 5.
- No progress in a round (all disagreements STUCK with same arguments as the prior round) → declare cross-talk over and proceed to Phase 4 (arbitration).
- Team has spent 3 rounds → hard stop. Arbitrate.

## Phase 4 — CEO arbitration

### Decision format

For each unresolved disagreement, write 3–5 sentences:

```
**Disagreement**: <one line summary of the split>
**Seats**: <seat-A> vs <seat-B> (+ any additional seats who weighed in)
**Best argument A**: <their strongest point>
**Best argument B**: <their strongest point>
**Decision**: <chosen side, or DEFER>
**Rationale**: <why, engaging specifically with the loser's argument — don't strawman>
```

A defer is a legitimate decision. It requires an explicit revisit criterion:

```
**Decision**: DEFER
**Revisit when**: <specific measurable criterion, e.g., "feature-X DAU exceeds 1000" or "first bug report hits the cache layer">
```

### When to escalate to the human

Escalate when the decision is:
- Strategic (product direction, major scope expansion)
- Budget-adjacent (cost tradeoffs the user hasn't authorized)
- Legally material (licensing, privacy, regulated industry — and `legal-compliance` flagged it)
- Cross-team (impacts teams or stakeholders outside the current user's scope)

Escalation format, ≤150 words:

```
Council hit a deadlock that needs human judgment:

Question: <one line>
Option A (<champion seats>): <best argument, 1–2 sentences>
Option B (<champion seats>): <best argument, 1–2 sentences>
My recommendation: <A or B, 1 sentence>
Tradeoff: <what we lose either way, 1 sentence>
```

Use `AskUserQuestion` when A/B/C are cleanly discrete. Plain text when the options branch.

### When NOT to escalate

Routine technical disagreements are the CEO's to resolve:
- Naming (flag names, method names, file locations)
- Internal layering (service boundaries, module decomposition)
- Implementation tactics (which data structure, which library idiom)
- Error message text
- Testing approach

## Phase 5 — Decision log + teardown

### Log path

```
~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md
```

Create the directory if it doesn't exist. `<slug>` is kebab-case, ≤40 chars, derived from the decision question.

### Log content — executive summary, not transcript

Use `decision-log-template.md`. Never include:
- Full agent opening positions (just one-liner + verdict per seat)
- Full cross-talk transcripts (just the RESOLVED/STUCK classification)
- Verbose narration

Target length: one page.

### Execution plan — merge-conflict discipline

The decision log must close with an **execution plan**, not a freeform follow-up list. The plan is how downstream implementers (another session, a planning skill, or parallel agents) avoid collisions.

Required contents:

1. **Ordered task list.** Each task is one atomic unit of work — typically the slice a single implementer takes to green. No "and" in task titles.
2. **File-ownership mapping.** For every task, name the files it will touch. If a file appears in more than one task, that is a collision signal — resolve it per (3).
3. **Collision resolution.** For any overlapping file:
   - **Serialize** — mark one task `depends-on` the other. The second task rebases after the first lands.
   - **Consolidate** — merge the overlapping tasks into one.
   - **Partition** — split the file (rarely the right move; only when the file genuinely has two independent responsibilities that the council exposed).
4. **Shared-surface callouts.** Identify files that are merge-conflict magnets: lockfiles (`package-lock.json`, `Cargo.lock`), manifests (`package.json`, `plugin.json`), shared type definitions, central registries. Assign each to exactly one task; forbid side-touches from other tasks.
5. **Parallelization advice.** Flag which tasks can run concurrently (no file overlap) versus which must serialize. If the project has agent-teamwork guidelines (e.g., `CLAUDE.md` specifying git worktrees for parallel agents), reference them.
6. **Branch and rebase discipline.** If more than one branch will be produced, state the merge order into the target branch and who rebases on top of what.

Example (tiny):

```
### Execution plan

1. **task-A** — Create `src/foo.ts`, `tests/unit/foo.test.ts`. No other task touches these. ✅ Parallel-safe.
2. **task-B** — Create `src/bar.ts`, `tests/unit/bar.test.ts`. No other task touches these. ✅ Parallel-safe.
3. **task-C** — Register foo and bar in `src/registry.ts`. Depends on A and B. Shared-surface callout: `src/registry.ts` is this task's exclusive territory. Serialize.
4. **task-D** — Update `docs/API.md`. Depends on C (documents the registered shape). Parallel-safe with A, B.
```

### Teardown sequence

1. Send shutdown to all:
   ```
   SendMessage(to: "*", message: {type: "shutdown_request", reason: "council concluded"})
   ```
2. Wait for each teammate to respond with `shutdown_response`. Approvals terminate their processes.
3. Once all have shut down, call `TeamDelete()`. Team directory and shared task list are removed.
4. Confirm `~/.claude/teams/<team_name>/` is gone; surface the log path to the user.

### Shipping the decision — three paths (CEO orchestrates, never implements)

The CEO's role as *design council lead* ends when the decision log is saved. Shipping is a separate phase that may be performed by the same team re-briefed, a fresh implementation crew, or a downstream session. Pick the path in this order of preference; in every path the CEO stays off the keyboard for application code and tests.

1. **Warm-team ship (preferred).** The design-council team is already warm with the decision, the binding constraints, and the execution plan. Before running `TeamDelete`, re-brief each teammate with their task from the plan — file ownership, dependency edges, branch strategy, acceptance criteria. The roles naturally translate: `test-engineer` writes the tests, `principal-engineer` wires the seams, `ui-ux-designer` reviews copy diffs, `security-engineer` audits validation landing, `historian` verifies post-merge that precedent held. Parallelism is the big payoff — independent file-partitioned tasks run concurrently, which is exactly what the execution plan's collision discipline enables. The CEO continues to orchestrate: assigns tasks, routes blockers, pairs seats for code review, arbitrates post-implementation disagreements. Teardown happens after ship, not between design and ship.
2. **Fresh-crew ship.** If the original roster doesn't match the implementation shape (e.g., the debate was mostly design seats but implementation needs 3× test-engineer parallelism, or the council included an opt-in `legal-compliance` seat that has no implementation role), call `TeamDelete`, then `TeamCreate` a new team named `crew-<yyyy-mm-dd>-<slug>` with implementer-shaped agents. Spawn prompts include the decision log path so each implementer reads the arbitrated decisions verbatim before claiming a task. The CEO role (orchestration) stays with the invoking Claude.
3. **Handoff to a separate session.** If implementation will be long-running, or if the user wants to review the log before shipping, save the log, shut the team down, surface the log path + a one-paragraph handoff summary, and stop. A new session picks up from the log via `planning-and-task-breakdown` or `incremental-implementation`.

**Non-negotiable across all three paths:** the CEO does not type source code, author implementation tests, claim tracker tickets on their own behalf, or run TDD cycles. Those are seat-work. The CEO assigns them, routes them, and arbitrates disagreements that emerge during implementation — that's it. Filing *tracker items* that record the council's own deferred items is record-keeping, not implementation, and remains in scope.

### Path selection signals

- **Warm-team ship**: debate was tight (≤2 cross-talk rounds), execution plan has ≥3 tasks with clean file partitions, original roster skills cover implementation.
- **Fresh-crew ship**: roster mismatch, or the design was contentious enough that some seats' context should not carry forward.
- **Handoff**: user asks for a review gate, or expected implementation spans > 1 day of work.

### What about deferred tasks?

If the CEO deferred anything with a revisit criterion, record the criterion in the log. If the project has a tracker (beads, Jira, GitHub issues), also file the deferred item there with a pointer back to the log. The log is the durable reference; the tracker item is the action handle.
