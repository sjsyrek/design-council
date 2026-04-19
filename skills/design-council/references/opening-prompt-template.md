# Opening Prompt Template

Paste-ready scaffold for Phase 1. Fill every slot before spawning teammates.

---

## Decision Question

<One paragraph, explicit and answerable. Not "how should we handle auth?" — "Should we adopt OAuth 2.0 device flow for the CLI's admin commands, or stick with long-lived API keys stored in the app's XDG config file?">

## Binding Constraints

<Verbatim from: CLAUDE.md (current cwd), referenced plan/spec files, project memory (bd memories / auto-memory), commit conventions, privacy context (public vs private remote). Do not paraphrase. Include at least:>

- **Coding conventions**: <style guide / linting / naming rules from CLAUDE.md>
- **Test discipline**: <TDD required? Mutation ritual? Integration coverage requirements?>
- **Scope discipline**: <scope-creep rules; examples of what counts as "adjacent" and is forbidden>
- **Privacy / publication**: <repo remote visibility; what must not leak to commit history>
- **Version / release constraints**: <semver rules, release gates, branch protection>
- **Project memory relevant to this decision**: <e.g., "prior decision recorded in bd memory X">

## Non-Goals

<Explicit list of what is out of scope. Prevents scope creep in agent positions.>

- <e.g., "Not refactoring the existing auth module; only additive work.">
- <e.g., "Not changing the config file format.">
- <e.g., "Not migrating existing users of the affected API.">

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

Every teammate's spawn prompt includes this opening prompt verbatim. The CEO does not paraphrase it per seat — every seat sees the same constraints. This prevents the failure mode where binding constraints get lost in paraphrasing to fit a specific seat's framing.

When drafting: write as if the user were going to read it. Clarity here cascades into the whole debate.
