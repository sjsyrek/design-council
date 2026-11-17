# design-council — Protocol (deeper dive)

This reference expands the phase skeleton from `SKILL.md`. Consult when the debate gets messy, when a teammate drifts, or when the CEO needs a reminder of the exact orchestration moves.

## Phase 0 — Plan card (before any spawn)

Before any seat spawns, the CEO shows the user a **plan card** and waits for confirmation:

```
About to convene design-council:

Mode:         <debate | review>
Roster:       <N> seats (<list of slugs>)
Models:       <per-seat model + effort — default Opus on synthesis seats, Sonnet on analytical>
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

The CEO writes the concatenated binding constraints to `~/.claude/councils/<slug>/brief.md` **once**. Every spawn prompt tells the seat to `Read` that path. The saving is in the CEO's output: it writes the constraints once instead of inlining them into N spawn prompts. (The seats' prompts diverge at the role brief, so the `Read` itself is not shared through the prompt cache.)

### Draft the opening prompt

Use `opening-prompt-template.md`. Four sections:

1. **Decision question** — one paragraph, specific, answerable.
2. **Binding constraints** — pointer to `~/.claude/councils/<slug>/brief.md` (not inlined).
3. **Non-goals** — what is explicitly out of scope.
4. **Success criterion** — how the CEO knows the debate has converged.

## Phase 2 — Convene (parallel fan-out)

### The multi-tool-call template

```
Agent(name: "principal-engineer",   subagent_type: "general-purpose", model: "opus",   effort: "high", description: "Council seat: principal-engineer",   prompt: <spawn prompt>)
Agent(name: "platform-engineer",    subagent_type: "general-purpose", model: "sonnet",                 description: "Council seat: platform-engineer",    prompt: <spawn prompt>)
Agent(name: "integration-engineer", subagent_type: "general-purpose", model: "opus",                   description: "Council seat: integration-engineer", prompt: <spawn prompt>)
... (remaining seats + opt-ins)
```

There is no team-creation step: the session's implicit team exists whenever `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set, and `name` is what makes a spawn a teammate. Omit `team_name` (accepted but ignored) and `run_in_background` (no longer a parameter). Issue all spawns in one message so seats start together.

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

PROTOCOL CONTRACT:

1. Reach the CEO with SendMessage(to: "team-lead"). The CEO only sees your last turn's text in an idle notice, and other seats see nothing you don't message to them — so anything that matters goes through SendMessage.
2. First action: SendMessage(to: "team-lead", summary: "handshake", message: "HANDSHAKE <your-seat>: started on <area>."). Until it arrives, the CEO can't tell you from a spawn that never started.
3. Deliver your position or findings via SendMessage to team-lead. End with an "Action items" list if you have any.
4. Answer a shutdown_request with the structured form, echoing its request_id: SendMessage(to: "team-lead", message: {type: "shutdown_response", request_id: "<id>", approve: true}). A prose acknowledgement does not end your process.
5. Peer DMs: SendMessage(to: "<peer-name>", ...). Wait until the CEO says peer DMs are open — a seat that is still starting up can miss a DM. Other seats: <list>.
6. Debate protocol: open with a ≤300-word position paper, verdict tag APPROVE | CONCERNS | BLOCK, concrete file:line refs when critiquing. BLOCK requires a concrete scenario. In Review mode: no verdict tags; emit findings per the format in references/review-mode.md.
```

The protocol contract (delivery rules + peer-DM + debate vs review) is canonical **here**. SKILL.md summarizes it and points to this section.

## Phase 2.5 — Handshake verification (do not skip)

A spawn can be registered without its process ever starting (historically: an `Agent` result of `[Tool result missing due to internal error]` with the member still listed in the team config). Without verification, the CEO waits cross-talk rounds for seats that never existed.

Verification, bounded to ~60s total:

1. **Count handshakes** — incoming messages starting `HANDSHAKE <seat>:` against the roster. Any `Agent` call that returned an error is an immediate failure.
2. **Re-spawn once** — a seat with no handshake after ~30s gets one nudge (`SendMessage(to: <seat>, message: "Send your HANDSHAKE line per the contract. No findings yet.")`). Still silent after another ~30s → re-spawn once with the same prompt; if that fails too, drop the seat and note the uncovered domain in the Phase 5 log.
3. **Open peer DMs** — once the roster is settled, send each seat (one `SendMessage` per seat; there is no broadcast) the final roster and "Peer DMs are open."

The CEO emits a structured status line before proceeding:

```
HANDSHAKE: 8/8 ok | silent-spawn=[] | verdict=PROCEED
```

Grep-able, and distinguishes this state from cross-talk silence. The team config lives at `~/.claude/teams/session-<session-id-prefix>/config.json` if you need to inspect members, but handshakes are the signal.

### Silent-spawn failure vs silent-acceptance

Both look like an idle seat with no message. Distinguish:

- **Silent-spawn (Phase 2.5 concern):** the seat never started. No handshake ever arrived. Remediate: re-spawn or drop.
- **Silent-acceptance (Phase 3 concern, below):** seat posted an opening position and has now gone idle after a CEO narrowing question or resolution proposal. Remediate: treat silence as concurrence.

The handshake disambiguates: handshake missing = spawn failure; handshake present but follow-up missing = silent-acceptance.

## Phase 3 — Cross-talk (peer DMs + CEO routing)

### How idle notifications work

Every teammate goes idle after each turn. The harness delivers an idle notification to the CEO carrying the teammate's last turn text (`result`) and, when it DMed a peer that turn, a `[to <peer>] <summary>` marker. The CEO does not poll an inbox — notifications and messages arrive as conversation turns.

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
5. **All-seats message (sparingly).** One `SendMessage` per seat — broadcast (`to: "*"`) is no longer supported. O(team-size) cost; reserve for genuine all-seats pivots.

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

1. **Silent-promise guard.** Grep the draft log: every DEFER entry must have a non-empty `Tracker:` ID (or a filed tracker command logged if no tracker present). Unfiled DEFERs: either file now or demote to prose note.
2. **Primary-bead close (beads projects).** `bd close <id>`. `--force` if beads flags a known epic-dependency inversion — surface in the log's appendix so the user sees the workaround was intentional.
3. Send each seat `SendMessage(to: "<seat>", message: {type: "shutdown_request", reason: "council concluded"})` — one call per seat, all in one message.
4. Wait for each seat's `shutdown_response`. A seat that rejects or stays silent: one reminder, then report it to the user by name.
5. Surface the log path to the user. There is no team to delete: the session's implicit team ends with the session.

### Stopping early

User says "stop the council" or equivalent at any phase:

1. CEO sends `shutdown_request` with a reason to each seat by name.
2. Saves a partial log with `status: halted` in frontmatter, noting which phase the halt hit and what was in-flight.

Halted logs are durable: user may restart with a different roster/question referencing them.

### Shipping the decision

See `implementation-handoff.md` for the three ship paths (warm-team / fresh-crew / handoff), the 6 production gotchas, and the merge primitive (`git checkout <SHA> -- <files>` + `git commit --no-verify -C <SHA>` — not cherry-pick for mixed-base worktrees).
