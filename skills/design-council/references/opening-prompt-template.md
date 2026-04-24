# Opening Prompt Template

Paste-ready scaffold for Phase 1. Fill every slot before spawning teammates.

---

## Decision Question

<One paragraph, explicit and answerable. Not "how should we handle auth?" — "Should we adopt OAuth 2.0 device flow for the CLI's admin commands, or stick with long-lived API keys stored in the app's XDG config file?">

## Binding Constraints

The CEO writes the full binding-constraints payload **once** to `~/.claude/councils/<slug>/brief.md`, then references it from every spawn prompt. Identical `Read` calls hit the 5-minute prompt cache across parallel seats. This section of the opening prompt is just a pointer:

```
BINDING CONSTRAINTS: Read ~/.claude/councils/<slug>/brief.md before posting your opening.
```

What goes into `brief.md` (verbatim, no paraphrasing):

- **Coding conventions**: <style guide / linting / naming rules from CLAUDE.md>
- **Test discipline**: <TDD required? Mutation ritual? Integration coverage requirements?>
- **Scope discipline**: <scope-creep rules; examples of what counts as "adjacent" and is forbidden>
- **Privacy / publication**: <repo remote visibility; what must not leak to commit history>
- **Version / release constraints**: <semver rules, release gates, branch protection>
- **Project memory relevant to this decision**: <e.g., "prior decision recorded in bd memory X">
- **Memory-vs-skill contradictions flagged** (important): <if any project memory directly contradicts the skill's prescriptions, flag and follow memory — memory is project ground truth>

If no CLAUDE.md exists in the invoking project, say so explicitly in `brief.md`. It's common, not a blocker.

## Non-Goals

<Explicit list of what is out of scope. Prevents scope creep in agent positions.>

- <e.g., "Not refactoring the existing auth module; only additive work.">
- <e.g., "Not changing the config file format.">
- <e.g., "Not migrating existing users of the affected API.">

## Prior-Council Context (when applicable)

<If the decision originated in a prior council — e.g., as a DEFERRED item, a finding in an audit/review, or a follow-up the prior log explicitly punted — cite the log path AND the originating seat(s) here. Seats reading the brief need this: the prior debate's framing, the seats who raised it, and the execution-plan cluster it belongs to all shape how this council's decisions mesh with earlier ones. Include at minimum:>

- **Prior log path:** `~/.claude/councils/<yyyy-mm-dd>-<slug>/log.md`
- **Originating seat(s) and finding#:** <e.g., "qa-engineer F1 + historian F3 — combined into one P0 item">
- **Execution-plan cluster (from the prior log):** <file-ownership group; names the files that may be touched by siblings of this decision>
- **What the prior council explicitly did NOT decide:** <so this council doesn't accidentally relitigate settled items>

Omit this section entirely when the decision is fresh.

## Success Criterion

<How will the CEO know the debate has converged?>

Default: "All seats have posted a verdict. No BLOCK outstanding. All CONCERNS either resolved via cross-talk or arbitrated by the CEO with written rationale."

## Known Deadlines / Budget

<Optional — include if time or cost are load-bearing>

- <e.g., "Decision needed by 2026-05-01 for Q2 release cut.">
- <e.g., "Implementation budget: 2 engineer-weeks.">
- <e.g., "No additional infra spend approved this quarter.">

---

## How this is used

Every teammate's spawn prompt includes this opening prompt's Decision/Non-goals/Success sections verbatim, plus a pointer to `~/.claude/councils/<slug>/brief.md` for binding constraints. The CEO does not paraphrase — every seat sees the same source material. This prevents the failure mode where binding constraints get lost in paraphrasing to fit a specific seat's framing.

When drafting: write as if the user were going to read it. Clarity here cascades into the whole debate.

---

## Review mode variant

Use this variant when the council is auditing a codebase or design surface for issues — not debating a single decision. See `references/review-mode.md` for when to invoke and the full protocol adjustments.

---

## Review Scope

<One paragraph naming what is being reviewed and why. Not "review the repo" — "Review /path/to/repo for resilience and structural soundness before the 1.0 release cut." Include the target quality bar.>

## Priority filter

<The user's severity threshold. Reviews produce a lot of findings; the filter prevents P2+ noise.>

Default: "P0 = critical (security, data loss, broken builds, correctness bugs that corrupt user state). P1 = high (major reliability/perf regressions, serious architectural weaknesses, significant doc gaps that block users). Do not report P2+."

## Per-seat scope partition

<For each seat, name the sub-area they own in this review. Prevents duplication across seats. Example:>

- `principal-engineer`: module boundaries under `internal/`, package graph health
- `security-engineer`: input validation, path safety, credential handling in `cmd/bd/hooks.go`, `.beads/.beads-credential-key`
- `performance-engineer`: hot paths — `bd ready`, `bd list`, cold-start of embedded Dolt
- (… one partition per seat)

## Known signals

<Any pre-observed issues the CEO wants seats to validate or expand on. One line each. Distinct from binding constraints — these are candidate findings, not rules.>

- <e.g., "`bd init --force` produced 'diverged history' warning — investigate if this is a data-loss footgun">
- <e.g., "Recent `fix(ci):` commit cluster (45+ commits) suggests chronic flakiness">

## Output format (strict, enforced on every seat)

Every finding must emit exactly this block:

```
## FINDING <N>: <≤70-char imperative title>
- Priority: P0 | P1
- Type: bug | chore | task | feature
- Evidence: <file:line | grep 'pattern' → N hits | command output>
- Rationale: <why this priority — impact × likelihood, 1–2 sentences>
- Scope: investigate | fix — <effort estimate>
- Description: <3–5 sentences, self-contained, ready for `bd create --description` or equivalent tracker>
```

Zero-findings line (if the seat's area is clean): `NO P0/P1 FINDINGS — <one-line reason>`.

Per-seat max: 5 findings. If more exist, triage to the top 5 and note overflow.

## Binding Constraints (verbatim)

<Same verbatim-from-sources content as the debate-mode template above. Reviews still inherit CLAUDE.md / memory / privacy context.>

## Non-Goals

<Explicit list of out-of-scope items. Reviews especially benefit from these — prevents scope creep into "while I'm here" refactoring.>

- <e.g., "Not proposing rewrites; surface issues only.">
- <e.g., "Not filing P2+ findings.">
- <e.g., "Not duplicating existing tracker items <list>; skip these.">

## Success Criterion

<Default: "All seats have delivered their findings via SendMessage in the strict format above, or explicitly reported NO P0/P1 FINDINGS. CEO has deduplicated overlapping findings and filed each as a tracker item (or prose entry if no tracker detected).">

---

## How Review mode differs from debate mode

- No "Decision Question" — replaced by Review Scope.
- No verdict tags (APPROVE/CONCERNS/BLOCK) — findings carry priority tags instead.
- Cross-talk phase is skipped by default (see `SKILL.md` "Review mode variant" Phase 3 adjustment).
- Decision log emphasizes file-ownership execution map over arbitration rationale.
