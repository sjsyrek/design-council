# Tracker integration

Optional, auto-detected. The skill's core protocol runs identically with or without a tracker. Most users have no tracker configured — that's the default path, not the exceptional one.

## What's supported today

**First-class: [beads](https://github.com/gastownhall/beads)** — because it exposes a `bd` CLI and a memory system that compose cleanly with Claude's tool surface.

**Other trackers** (GitHub Issues via `gh`, GitLab via `glab`, Linear, Jira) can be wired by following the same detection + command-mapping pattern below. The skill does not ship bindings for them yet; contributions welcome.

## Beads detection

```
test -d .beads || command -v bd
```

Run from the invoking project's git root. Either succeeds → beads is this project's tracker.

## What the skill does when beads is detected

- **Phase 1 brief:** runs `bd memories`, `bd ready`, and `bd show <id>` for every bead ID the user references. Output is inlined verbatim in the opening prompt.
- **Phase 4 arbitration:** every `DEFER` decision is translated to a `bd create --title=... --description=... --type=task --priority=N` command and executed before Phase 5 teardown. The filed bead ID is recorded in the log and the frontmatter `linked-tracker-ids` list.
- **Phase 5 teardown:** if a primary bead was under debate, `bd close <id>` runs before `TeamDelete`. Use `--force` if beads flags a known epic-dependency inversion (that's a beads behavior, not a skill bug).

## When no tracker is detected (common case)

Deferred items remain prose entries in the decision log. The CEO does not invent commands for a tracker that isn't there. Users with other trackers port the pattern manually (`gh issue create`, `glab issue create`, etc.) based on their workflow — the skill's durable contract is the decision log's `## Deferred items` list; the tracker integration is a convenience layer on top.

## Two-list discipline (when a persistent tracker is present)

`TeamCreate` creates `~/.claude/tasks/<team>/` for session-scoped coordination between teammates during the debate. Persistent work (existing issues, follow-ups, epics) lives in the tracker. Never duplicate. Never file session-scoped coordination items as persistent tracker items.

## Silent-promise guard

A `DEFER` with no filed tracker item decays to nothing. Phase 5 verification (before `TeamDelete`) greps the log for DEFER entries and confirms each has a non-empty `Tracker:` ID. Missing IDs must be filed now or the DEFER must be downgraded to a prose note and removed from the Deferred-items list. Do not teardown past this gate with unfiled defers.

## Adapter contract (for future trackers)

Each tracker adapter should expose four hooks:

1. **`detect()`** — returns true if this tracker is active in the current project.
2. **`fetch_for_brief()`** — returns text to inline in the opening prompt (ready queue, memories, referenced items).
3. **`translate_defer(title, description, priority)`** — returns the tracker-specific command or ID after filing.
4. **`close_primary(id)`** — closes the primary tracked item at teardown.

Implementations live in `references/tracker-adapters/<name>.md` (today only `beads.md` exists as reference content in this file).
