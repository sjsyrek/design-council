# Decision Log Template

Paste-ready scaffold for Phase 5. Save to `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md`.

**Length cap: one page.** Executive summary, not transcript.

---

```markdown
---
date: YYYY-MM-DD
slug: <kebab-case-slug>
team: council-<yyyy-mm-dd>-<slug>
status: concluded
---

# Council decision log: <one-line decision title>

## Opening prompt

<Decision question from Phase 1 — one paragraph>

## Binding constraints (digest)

- <Top 3–5 constraints that shaped the debate; full list lives in the spawn prompts>

## Roster convened

**Default seats (11):** principal-engineer, platform-engineer, integration-engineer, test-engineer, qa-engineer, security-engineer, performance-engineer, product-manager, ui-ux-designer, accessibility-specialist, technical-writer.

**Opt-ins activated:** <e.g., devops-engineer (deploy risk); legal-compliance (PII in the feature)>

**Total: <N> seats**

## Opening verdicts

| Seat | Verdict | One-line position |
|------|---------|-------------------|
| principal-engineer | APPROVE \| CONCERNS \| BLOCK | <one line> |
| platform-engineer | ... | ... |
| integration-engineer | ... | ... |
| ... (one row per seat) |

## Resolved disagreements

<One line per disagreement. Format: "<seats involved>: debated <what>; resolved as <outcome>.">

- <e.g., "security-engineer ↔ performance-engineer: debated 24h cache TTL; resolved as 1h TTL with explicit invalidation on logout.">
- <e.g., "ui-ux-designer ↔ product-manager: debated flag naming; resolved as `--dry-run` (standard across ecosystem).">

## CEO arbitration (unresolved in cross-talk)

<For each disagreement CEO had to decide>

### <Short disagreement title>

- **Seats**: <who disagreed>
- **Best argument A**: <1–2 sentences>
- **Best argument B**: <1–2 sentences>
- **Decision**: <chosen side, or DEFER>
- **Rationale**: <2–3 sentences engaging with the loser's argument>

<Repeat for each arbitrated item. Omit the section entirely if cross-talk resolved everything.>

## Human-escalated items

<For each item escalated>

### <Short title>

- **Escalation summary**: <≤150 words, the question presented to the user>
- **User decision**: <what they chose>
- **Rationale given**: <if any>

<Omit the section if nothing was escalated.>

## Deferred items

<For each DEFER decision>

- <short title>: revisit when <criterion>. <Tracker ID if filed, e.g., "beads bd-1234">

## Execution plan

<Required. How the decision ships — by the warm team re-briefed, by a fresh crew, or via handoff. Designed so parallel implementers don't collide. See `protocol.md` Phase 5 "Execution plan — merge-conflict discipline".>

**Ship path:** <warm-team | fresh-crew | handoff> — <one-line rationale>

**Tasks (ordered):**

| # | Task | Files touched | Depends on | Parallel-safe with |
|---|------|---------------|-----------|---------------------|
| 1 | <atomic task title> | <comma-separated file list> | — | <task numbers> |
| 2 | <atomic task title> | <comma-separated file list> | 1 | <task numbers> |

**Shared-surface callouts:** <list files that are merge-conflict magnets — lockfiles, manifests, shared registries/types. Each assigned to exactly one task.>

- `<file>` — owned by task #<n>; no side-touches from other tasks.

**Branch/rebase discipline:** <how branches stack; what rebases on what; merge order into target branch.>

## Follow-up actions (record-keeping only, not implementation)

<Tracker items the CEO files to record deferred decisions. Implementation tasks belong in the Execution plan above, not here.>

- [ ] <e.g., "File beads bd-5678 recording the deferred fallback plan with revisit criterion.">
- [ ] <e.g., "Link this log from the project tracker's epic notes.">

## Appendix (optional)

<Only if the debate surfaced a non-obvious pattern or principle worth preserving beyond this decision. One paragraph max. If nothing rises to this bar, omit.>
```

---

## Notes for the CEO when writing

- **Length cap is one page.** If the decision required extensive arbitration, still one page — link out to the opening-prompt file or the team's task list dump for details. The log itself stays executive-length.
- **No full transcripts.** If someone later wants the full debate, the team's task list and conversation logs were captured during the run (preserved until `TeamDelete` runs); they can be archived separately if the user wants.
- **Verdict column uses the exact strings** `APPROVE` / `CONCERNS` / `BLOCK`. Don't paraphrase — consistent strings let future tooling grep the log.
- **Rationale must engage the loser's argument.** "We picked A because we liked it" is not a rationale. "We picked A because B's best point — X — is mitigated by Y that we're adopting alongside A" is a rationale.
- **Deferred items are promises.** Record the revisit criterion crisply. "Someday" is not a criterion.
