# design-council — Protocol (deeper dive)

This reference expands the phase skeleton from `SKILL.md`. Consult when the debate gets messy, when a teammate drifts, or when the CEO needs a reminder of the exact orchestration moves.

## Phase 0 — Plan card (before any spawn)

Before `TeamCreate`, the CEO shows the user a **plan card** and waits for confirmation:

```
About to convene design-council:

Mode:         <debate | review>
Roster:       <N> seats (<list of slugs>)
Models:       <per-seat — default Opus on synthesis seats, Sonnet on analytical>
Opt-ins:      <any added — devops / finops / legal-compliance / domain-expert / historian>
Rough budget: ~<est. tokens>, ~<est. wall-clock>
Opening question:
  <drafted from Phase 1 brief so far>

Reply `go` to proceed · `swap X for Y` / `drop X` / `add X` to adjust · `abort` to cancel.
```

This fixes recurring pain:

1. **Model-choice surprise** — seat-model defaults land silently otherwise; users discover them mid-debate.
2. **Cost anxiety** — 8-Opus councils are expensive; the user sees the ballpark before committing.
3. **Wrong mode** — review tasks are often framed as "debates" in natural language; the plan card surfaces mode choice and asks.
4. **Roster fit** — the default isn't always right; one-message adjustment is cheap.

Plan card is skippable only if the user has given explicit standing authorization ("auto-mode", durable instruction in CLAUDE.md). Otherwise: spawn requires `go`.

## Phase 1 — Brief (after plan card confirms)

### Assemble binding constraints

Pull from every available source and concatenate verbatim into the opening prompt. Do **not** paraphrase — paraphrasing is where subtle constraints get lost.

1. **`CLAUDE.md`** in the invoking project's cwd. If nested project CLAUDE.mds exist (monorepo), include all that apply. **If no CLAUDE.md exists,** say so explicitly in the brief and proceed — it's common, not a blocker.
2. **Plan / spec files** the user referenced. If the user said "debate this design" while pointing at a spec, the spec is part of the brief.
3. **Project memory systems**:
   - **Tracker detection (fails-safe).** Run `test -d .beads || command -v bd` from the invoking project's git root. If either succeeds, beads is this debate's tracker. If neither succeeds, skip — no tracker commands are invented. See `tracker-integration.md` for adapter contract.
   - **Beads (when detected):** fetch and inline `bd memories`, `bd ready`, `bd show <id>` for every bead ID the user named.
   - **Auto-memory** (`~/.claude/projects/<hash>/memory/MEMORY.md` + referenced files) — read and include.
4. **Skill self-audit (mandatory).** See next sub-section.
5. **Commit conventions** — `git log --oneline | head -20`.
6. **Privacy context** — `git remote -v`; public vs private affects artifact placement.

### Skill self-audit — the council reads its own memory

The council is an ideal instrument for discovering lessons about itself, but those lessons only compound if the next council actually reads them. Phase 1 includes a mandatory self-audit step that closes this loop **without** leaving the user's machine.

**What to read:**

```bash
# Entries in the invoking project's auto-memory that reference the council skill
grep -ril -E '(design-council|council-2[0-9]{3}-|handshake|spawn[[:space:]]|seat[[:space:]]|Phase [0-9])' \
  ~/.claude/projects/*/memory/ 2>/dev/null

# Emergent-insights sections from prior decision logs (any project, any user)
ls -1 ~/.claude/councils/*/log.md 2>/dev/null | while read f; do
  awk '/^## Appendix — Emergent insights/,/^## /' "$f" | grep -v '^## '
done
```

The first pattern surfaces cross-project feedback entries the user has recorded about how councils run — e.g., `feedback_council_model_choice_up_front.md`, `feedback_cherrypick_vs_checkout_implementation_handoff.md`. The second surfaces the "emergent insights" sections from every decision log on disk, which is where the council writes its own accumulated wisdom.

**Contradiction check (the important part):**

If any surfaced entry directly contradicts a prescription in the current `SKILL.md` or `references/protocol.md` (e.g., memory says "use X" and the skill says "use Y"), **memory is ground truth**. Memory is written after real sessions fail; the skill's text is written to prevent the next failure. When they disagree, the skill is stale.

The CEO's response to a detected contradiction:

1. Flag the contradiction in the shared `brief.md` so every seat sees it.
2. **Follow memory, not the skill's stale prescription.**
3. Record the contradiction in the decision log's `Appendix — Emergent insights` so it becomes a signal for the next skill-redesign council (or a surfaced item for the user to contribute upstream).

This is how the cherry-pick-vs-checkout drift that lived in SKILL.md through 0.1.4 would have been caught automatically in the first 0.1.5 council — the `feedback_cherrypick_vs_checkout_implementation_handoff.md` memory existed; nothing read it.

### Decide opt-in seats

| Cue | Add seat |
|-----|----------|
| "deploy", "ship", "release", "CI/CD", "rollback" | `devops-engineer` |
| "PII", "privacy", "GDPR", "license", "legal", "compliance" | `legal-compliance` |
| "cost", "spend", "quota", "budget", "API cost" | `finops-engineer` |
| Product-area jargon user expects agents to know | `domain-expert` |
| "mature codebase", "don't repeat past mistakes", >2-year-old codebase | `historian` |
| UI stakes low (backend-only, CLI-only) | Drop `ui-ux-designer` and `accessibility-specialist` |
| No runtime UI + no user input + no infra | Drop `security-engineer`, `platform-engineer` too — 4–6 seat debate is fine |

Dynamic roster sizing is a feature, not a warning: match seat count to domain count. The 8–11 range is typical; tighter is correct when the decision's surface is narrow.

### Write the shared brief artifact

The CEO writes the concatenated binding constraints to `~/.claude/councils/<slug>/brief.md` **once**. Every spawn prompt tells the seat to `Read` that path. Identical `Read` results hit the 5-minute prompt cache across parallel spawns — recovers ~7–12k tokens on 8-seat councils with constraint-heavy projects, at zero correctness cost.

### Draft the opening prompt

Use `opening-prompt-template.md`. Four sections:

1. **Decision question** — one paragraph, specific, answerable.
2. **Binding constraints** — pointer to `~/.claude/councils/<slug>/brief.md` (not inlined).
3. **Non-goals** — what is explicitly out of scope.
4. **Success criterion** — how the CEO knows the debate has converged.

## Phase 2 — Convene (parallel fan-out)

### The multi-tool-call template

```
TeamCreate(team_name: "council-2026-04-19-session-cache-ttl",
           description: "Debate: session-cache TTL policy",
           agent_type: "team-lead")

Agent(team_name: "...", name: "principal-engineer",   subagent_type: "general-purpose", model: "opus",    run_in_background: true, prompt: <spawn prompt>)
Agent(team_name: "...", name: "platform-engineer",    subagent_type: "general-purpose", model: "opus",    run_in_background: true, prompt: <spawn prompt>)
Agent(team_name: "...", name: "integration-engineer", subagent_type: "general-purpose", model: "opus",    run_in_background: true, prompt: <spawn prompt>)
... (remaining mandatory seats + opt-ins)
```

**All in one message.** Sequential spawns violate the parallel-first principle.

### The spawn-prompt assembly

For each teammate, the prompt is four concatenated blocks:

```
<role brief — read from references/roles/<slug>.md>

---

BINDING CONSTRAINTS: Read ~/.claude/councils/<slug>/brief.md before posting your opening. The CEO wrote it once for all seats.

---

DECISION TO DEBATE:

<verbatim opening prompt from Phase 1>

---

PROTOCOL CONTRACT (do not deviate):

1. SendMessage(to: "team-lead") is the ONLY channel to the CEO. Plain-text output is invisible and is discarded at idle.
2. FIRST thing: send a 1-line handshake via SendMessage(to: "team-lead", summary: "started", message: "Started on <area>."). Without this, you are indistinguishable from a silent-spawn failure.
3. Final position/findings MUST be delivered via SendMessage. Writing as plain text then going idle drops them on the floor.
4. Idle summaries are ≤200 chars. Do not put substantive content there.
5. Protocol responses (shutdown_response, plan_approval_response) MUST use their structured JSON form — never prose. A prose ack does not close the protocol state and will block teardown. Example shutdown: SendMessage(to: "team-lead", message: {type: "shutdown_response", request_id: "<id>", approve: true}).
6. Peer DMs are allowed — SendMessage(to: "<peer-name>", ...). Other seats active: <list>.
7. Debate protocol: open with ≤300-word position paper, verdict tag APPROVE | CONCERNS | BLOCK, concrete file:line refs when critiquing. BLOCK requires a concrete scenario. In Review mode: no verdict tags; emit findings per format in references/review-mode.md.
```

The universal protocol contract (the 4 delivery rules + peer-DM + debate vs review) is canonical **here**. SKILL.md references this section by path rather than duplicating it.

## Phase 2.5 — Handshake verification (do not skip)

The `Agent` tool can return `[Tool result missing due to internal error]` and still register the teammate with an empty `tmuxPaneId`. Slot reserved, no process started. Without verification, the CEO waits cross-talk rounds for seats that never existed. Observed at a 3/13 rate in one session.

Verification, bounded to ~60s total:

1. **Count handshakes** — incoming `SendMessage(summary: "started", ...)` against the roster.
2. **Inspect team config** — `~/.claude/teams/<team_name>/config.json`. Any member with `"tmuxPaneId": ""` after ~30s has not actually spawned.
3. **Remediate silent-spawn failures** — re-spawn once with the same prompt; if still failing, drop the seat and note the uncovered domain in the Phase 5 log.
4. **Verify late handshakes** — seats that spawned but haven't handshook in ~30s: send one `SendMessage(to: <seat>, message: "Acknowledge with a 1-line handshake per contract. No findings yet.")`. Still silent after 30s → drop.

The CEO emits a structured status line before proceeding:

```
HANDSHAKE: 8/8 ok | silent-spawn=[] | empty-pane=[] | verdict=PROCEED
```

Grep-able; telemetry-friendly; distinguishes this state from cross-talk silence.

### Silent-spawn failure vs silent-acceptance

Both look like an idle seat with no message. Distinguish:

- **Silent-spawn (Phase 2.5 concern):** the seat never started. No handshake ever arrived. Remediate: re-spawn or drop.
- **Silent-acceptance (Phase 3 concern, below):** seat posted an opening position and has now gone idle after a CEO narrowing question or resolution proposal. Remediate: treat silence as concurrence.

The handshake disambiguates: handshake missing = spawn failure; handshake present but follow-up missing = silent-acceptance.

## Phase 3 — Cross-talk (peer DMs + CEO routing)

### How idle notifications work

Every teammate goes idle after each turn. The system auto-delivers idle notifications to the CEO: last message, short summary of peer DMs sent by that teammate. The CEO does NOT poll an inbox — idle notifications arrive as conversation turns.

### Routing moves (pick one per disagreement per round)

1. **Pair disagreers.**
   ```
   SendMessage(to: "security-engineer", message: "You and performance-engineer disagree on 24h TTL. DM them directly. Report back when converged or sharpened.")
   ```
2. **Invite tiebreaker.** Third seat whose domain bears on the split.
3. **Narrowing question.** When a seat's objection is vague:
   ```
   SendMessage(to: "security-engineer", message: "Your BLOCK cites 'potential PII leak' — name the code path and data shape. file:line.")
   ```
   **Before arbitrating, check for terminology collapse.** Two seats often use different words for the same structural position. Watch: scope words (`MVP`, `Extended`), data-shape words (`parse`, `tokenize`, `segment`), outcome words (`preserve`, `round-trip`, `accept`).
4. **Bridge converged tracks.** Two peer-DM groups each converge internally but externally conflict:
   ```
   SendMessage(to: "<seat_in_track_A>", message: "Your track (with <B>) converged on X. A parallel track (<C>, <D>) converged on Y. These may be terminological. Does X mean <framing 1> or <framing 2>? One-sentence answer.")
   ```
   Do NOT reopen peer DMs; pin vocabulary across tracks.
5. **Broadcast (sparingly).** O(team-size) cost; reserve for genuine all-seats pivots.

### Round closure

Mark each live disagreement `RESOLVED` / `SHARPENED` / `STUCK`. End when all `RESOLVED`, or no progress in a round, or 3 rounds elapsed.

**Before declaring a round closed, verify no peer-DM exchange is still in-flight.** Check the last few idle notifications for `[to <seat>]` summary markers within the current round; a pair in mid-exchange may deliver a converged position within seconds of your "closed" call. Writing arbitration on incomplete cross-talk forces a rewrite when the late convergence arrives. If any pair is mid-exchange, wait one more idle cycle before moving to Phase 4.

### Silent acceptance

A seat that goes idle after a direct narrowing question *without posting a follow-up objection* has accepted by non-objection. One "confirm or object?" prompt if uncertain; still silent → log as `RESOLVED` with "silent acceptance" annotated.

### Review-mode exception

Skip Phase 3 entirely unless ≥2 overlapping findings need seats themselves to dedupe. Review seats work disjoint sub-areas; cross-talk is almost always unproductive. See `review-mode.md`.

## Phase 4 — CEO arbitration

### Decision format (debate mode)

```
**Disagreement**: <one line>
**Seats**: <A vs B (+ others who weighed in)>
**Best argument A**: <their strongest point>
**Best argument B**: <their strongest point>
**Decision**: <chosen side | DEFER | BLOCKED>
**Rationale**: <engages with the loser's argument; no strawmen>
```

### `DEFER` requires a revisit criterion + a filed tracker item

```
**Decision**: DEFER
**Revisit when**: <specific measurable criterion — "feature-X DAU exceeds 1000", "first bug report hits the cache layer">
```

A `DEFER` without a filed tracker item is a **silent promise**. When beads is detected, file the tracker item **before** writing the log:

```
bd create \
  --title="<summary from disagreement>" \
  --description="Deferred by council <slug>. Revisit when: <criterion>. Context: <loser's argument + why we deferred>." \
  --type=task --priority=<N>
```

ID becomes the `Tracker:` value in the decision log and frontmatter `linked-tracker-ids`. When no tracker is detected, the prose entry in the log is the only handle — user's responsibility to route.

### `BLOCKED` is distinct from `DEFER`

`DEFER` = time-or-signal-triggered revisit. `BLOCKED` = out-of-scope until a structural change to the problem (upstream library ships Y, separate council establishes X, audit changes the security model). BLOCKED decisions are NOT auto-filed as tracker items — there's nothing actionable yet. Prose entry in the log is the handle.

### When to escalate to the human

- Strategic (product direction, major scope expansion)
- Budget-adjacent (cost tradeoffs the user hasn't authorized)
- Legally material (`legal-compliance` flagged)
- Cross-team (affects stakeholders outside the current user's scope)

Escalation format, ≤150 words: question, Option A (champion seats) + best argument, Option B + best argument, CEO's recommendation, tradeoff. Use `AskUserQuestion` for discrete A/B/C; plain text otherwise.

### When NOT to escalate

Naming, internal layering, implementation tactics, error message text, testing approach — CEO resolves.

### Review-mode arbitration

Dedupe overlapping findings. Decide whether merged findings file as one or many tracker items. Bulk-file before teardown. See `review-mode.md`.

## Phase 5 — Decision log + teardown

### Log preview before save

CEO posts the draft log to chat (**not** the file yet). User replies `save` / `amend <note>` / `discard`. Then persist:

```
~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md
```

Create the directory if it doesn't exist. `<slug>` is kebab-case, ≤40 chars, derived from the decision.

### Log content — executive summary, not transcript

Use `decision-log-template.md`. Target length: one page. Never include full opening positions (one-liner + verdict per seat), full cross-talk transcripts (just RESOLVED/STUCK classifications), or verbose narration.

### Execution plan — merge-conflict discipline

The log closes with an **execution plan**, not a freeform follow-up list. Required:

1. **Ordered task list** — each task one atomic unit of work; no "and" in titles.
2. **File-ownership mapping** — for every task, the files it touches. Overlap is a collision signal.
3. **Collision resolution** — serialize (depends-on), consolidate (merge tasks), or partition (rare).
4. **Shared-surface callouts** — lockfiles, manifests, shared registries/types. Each assigned to exactly one task; forbid side-touches.
5. **Parallelization advice** — flag which tasks can run concurrently. If the project has agent-teamwork guidelines (CLAUDE.md), reference them.
6. **Branch/rebase discipline** — merge order, who rebases on what.

### Teardown sequence

1. `SendMessage(to: "*", message: {type: "shutdown_request", reason: "council concluded"})`
2. Wait for each seat's `shutdown_response`.
3. **Silent-promise guard.** Grep the draft log: every DEFER entry must have a non-empty `Tracker:` ID (or a filed tracker command logged if no tracker present). Unfiled DEFERs: either file now or demote to prose note.
4. **Primary-bead close (beads projects).** `bd close <id>` before `TeamDelete`. `--force` if beads flags a known epic-dependency inversion — surface in the log's appendix so the user sees the workaround was intentional.
5. `TeamDelete()`. Team directory + shared task list removed.
6. Confirm `~/.claude/teams/<team_name>/` is gone; surface the log path to the user.

### Stopping early

User says "stop the council" or equivalent at any phase:

1. CEO broadcasts `shutdown_request` with reason.
2. Saves a partial log with `status: halted` in frontmatter, noting which phase the halt hit and what was in-flight.
3. `TeamDelete`.

Halted logs are durable: user may restart with a different roster/question referencing them.

### Shipping the decision

See `implementation-handoff.md` for the three ship paths (warm-team / fresh-crew / handoff), the 6 production gotchas, and the merge primitive (`git checkout <SHA> -- <files>` + `git commit --no-verify -C <SHA>` — not cherry-pick for mixed-base worktrees).
