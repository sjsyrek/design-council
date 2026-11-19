# Decision Log Template

Paste-ready scaffold for Phase 5. Save to `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md`.

**Length cap: ~600 words** (frontmatter excluded). Executive summary, not transcript. The log records *what* was decided and *who ships what*; per-task requirements (acceptance criteria, test expectations, constraints, base-branch instructions) go into the implementer briefs at ship time — see `implementation-handoff.md` "Implementer briefs".

Budgets below are targets per section; omit any optional section that would be empty.

---

```markdown
---
date: YYYY-MM-DD
slug: <kebab-case-slug>
council: <yyyy-mm-dd>-<slug>
status: concluded
primary-tracker-id:          # e.g., "beads-3mj6"; omit if none
linked-tracker-ids: []       # follow-ups filed during this council
---

# Council decision log: <one-line decision title>

## Decision                                   <!-- ≤60 words -->

<The question in one sentence, then the outcome in one or two.>

## Opening verdicts                          <!-- ≤90 words, includes roster -->

| Seat | Verdict | One-line position |
|------|---------|-------------------|
| principal-engineer | APPROVE \| CONCERNS \| BLOCK | <≤12 words> |
| ... (one row per seat) |

<Opt-ins activated, one line, if any. Dropped/un-spawned seats, one line, if any.>

## Rationale                                  <!-- ≤120 words -->

<Why the winning option won, engaging the strongest argument for the losing option: "B's best point — X — is mitigated by Y, which we adopt alongside A.">

## Resolved disagreements                     <!-- ≤80 words, optional -->

- <seats>: debated <what>; resolved as <outcome in ≤15 words>.

<One line per disagreement, no sub-bullets. If the resolution is a set of rules an implementer must follow, the line names the outcome and the rules go into that task's implementer brief.>

## CEO arbitration                            <!-- ≤80 words per item, optional -->

- **<title>** (<seats>): A — <best argument, 1 sentence>; B — <1 sentence>. **Decision:** <side or DEFER>. <1-sentence rationale engaging the loser.>

## Escalated / deferred / blocked            <!-- ≤60 words, optional -->

- Escalated: <title> — user chose <x>.
- DEFER: <title> — revisit when <concrete criterion>. Tracker: <id-or-"unfiled">.

<Every deferred item — filed or not, "nice-to-have" or "v2" — needs a concrete "revisit when" (a signal, a date, or an event). An idea with no criterion is not a DEFER: drop it from the log.>
- BLOCKED: <title> — re-open only if <structural change>.

## Execution plan                             <!-- ≤120 words -->

**Ship path:** <warm-team | fresh-crew | handoff> — <one-line reason>

| # | Task | Files touched | Depends on |
|---|------|---------------|------------|
| 1 | <atomic task, no "and"> | <files> | — |
| 2 | <atomic task> | <files> | 1 |

**Shared surfaces:** `<file>` → task <n>. **Merge order:** <e.g., 1 → 2 → 3, each rebased on the previous>.

## Emergent insight                           <!-- ≤60 words, optional -->

<One reusable principle that outlives this decision, if the debate produced one. This is the log's last section: no appendix, and no notes about how the session ran (denied tools, permission modes) — tell the user those in chat.>
```

---

## Notes for the CEO when writing

- **Count before you preview.** Count the draft with Bash, no file needed: `wc -w <<'EOF'` … `EOF`. Over ~600 words: move implementation rules into briefs first, then cut narration, then merge resolved disagreements into the rationale, then shorten one-line positions. Never cut the verdict table, the rationale, or the execution-plan table. Recount after cutting.
- **Requirements belong in briefs, not the log.** No acceptance criteria, test lists, edge cases, or step-by-step instructions per task. If a seat's requirement must survive, put it in that task's implementer brief when you ship (see `implementation-handoff.md`). The log's task row is title + files + dependency.
- **No transcripts, no full positions.** The session and teammate transcripts hold the debate.
- **Verdict column uses the exact strings** `APPROVE` / `CONCERNS` / `BLOCK` so tooling can grep the log.
- **Rationale must engage the loser's argument.** "We picked A because we liked it" is not a rationale.
- **Deferred items are promises.** Every DEFER needs a concrete revisit criterion and a tracker ID (or `unfiled`, which the Phase 5 silent-promise guard catches).
- **DEFER vs BLOCKED.** DEFER is expected-later on a time/signal trigger and gets a tracker item; BLOCKED is out of scope until a structural change and stays prose-only.
- **Review-mode logs.** Replace "Opening verdicts" with per-seat P0/P1 finding counts, and "Rationale" with CEO dedup decisions (merged findings → tracker items). The execution plan becomes a file-ownership map of the filed items. Same ~600-word cap.
