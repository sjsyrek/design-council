# Changelog

All notable changes to the design-council plugin are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-04-24

Redesign pass driven by a design-council session convened on the skill itself (`council-2026-04-24-skill-redesign`). SKILL.md trimmed from 308 to 117 lines via progressive disclosure; three bold moves landed based on accumulated memory learnings.

### Added

- **Phase 0 — Plan card.** Before any `TeamCreate`, the CEO shows the user a one-screen card: mode, roster, per-seat model, rough token/wall-clock budget, and drafted opening question. User replies `go` / `swap` / `drop` / `add` / `abort`. Addresses the `model-choice-up-front` memory — users no longer discover seat-model choices mid-debate.
- **Shared binding-constraints artifact.** CEO writes constraints once to `~/.claude/councils/<slug>/brief.md`; every spawn prompt points to that path. Identical `Read` results hit the 5-minute prompt cache across parallel seats (~7–12k tokens saved per 8-seat council, zero correctness cost).
- **User-facing "What the user sees" section** at the top of SKILL.md. 15 lines covering plan card, handshake status, cross-talk, log preview, output location, and the "stop early" path. Addresses the "308 lines, zero user-facing content" gap.
- **Phase 2.5 structured handshake status line.** CEO emits `HANDSHAKE: N/N ok | silent-spawn=[] | empty-pane=[] | verdict=PROCEED` so spawn health is visible, not just inferred.
- **"Stop early" path** documented: broadcast `shutdown_request`, save partial log with `status: halted`, `TeamDelete`.
- **Phase 1 skill self-audit.** The CEO greps `~/.claude/projects/*/memory/` for council-relevant feedback and the `Appendix — Emergent insights` section of every prior decision log in `~/.claude/councils/`. Findings land in `brief.md` so every seat sees them. **If any memory contradicts a prescription in SKILL.md or protocol.md, memory is ground truth** — follow memory, flag the drift, record it as an emergent insight for the next skill-redesign council. Would have caught the cherry-pick-vs-checkout drift automatically the first 0.1.5 council after `feedback_cherrypick_vs_checkout_implementation_handoff.md` was written. No external exfiltration: the self-audit stays on the user's machine; upstream contribution remains manual and user-gated.
- **Log preview step** in Phase 5: CEO posts draft to chat before saving; user replies `save` / `amend` / `discard`.
- **`references/implementation-handoff.md`** (new reference). The six post-debate gotchas — worktree `team_name` override, cwd leaks, commit-hook races, tracker-state pollution, worktree base drift, per-lane CHANGELOG conflicts — now load only when the CEO reaches the shipping sub-step.
- **`references/tracker-integration.md`** (new reference). Beads auto-detection + adapter contract for future trackers (gh / glab / linear / jira).
- **`references/review-mode.md`** (new reference). Full review-mode protocol adjustments and finding format, loaded only when running in audit mode.
- **`CHANGELOG.md`** (new file at repo root).

### Changed

- **Merge primitive:** `git checkout <agent-SHA> -- <files>` + `git commit --no-verify -C <agent-SHA>` replaces `git cherry-pick` everywhere, matching the `checkout-over-cherrypick` memory (proven on `council-2026-04-23-docs-audit` where cherry-pick cascade-failed across 6 lanes). Cherry-pick fails on mixed-base worktrees; checkout imports file contents directly without replaying a diff.
- **SKILL.md description** rewritten: co-equal debate/review framing; crisper "Do NOT invoke" list; explicit stake-threshold language ("cross-domain decision with real stakes"). Addresses the over-triggering concern that near-tautological phrasing caused false-positive invocations.
- **Dynamic roster sizing** codified as the default, not an exception. No runtime UI → drop ui-ux + a11y. No user input / no infra → drop security + platform. Internal-tooling defaults of 4–6 seats are now explicitly valid.
- **Model defaults surfaced** in SKILL.md and plan card: Opus for synthesis-heavy seats (principal, PM, tech-writer, historian); Sonnet for analytical seats (test, perf, platform, qa); all-Opus on "high quality bar" framings.
- **Universal spawn prompt rules single-sourced** in `references/protocol.md` Phase 2. SKILL.md keeps only the 4-bullet contract; the canonical wording (with peer-DM addressing and debate-vs-review footer) lives in protocol.md.
- **Opening-prompt template** points every seat to `brief.md` instead of inlining verbatim constraints per spawn.

### Removed

- **Failure modes #10–15** from SKILL.md — pure table-of-contents duplication of the subsections directly below them. Zero information loss; remaining 9 failure modes are one-line-each.
- **"Implementation handoff gotchas" subsection** (~90 lines) from SKILL.md. Content moves verbatim to `references/implementation-handoff.md` and is no longer paid for on every council invocation.
- **"Tracker integration" subsection** (~40 lines) from SKILL.md. Content moves to `references/tracker-integration.md`.
- **Review-mode interleaved sections** from SKILL.md. Content moves to `references/review-mode.md`; SKILL.md keeps a one-line Variants pointer.
- **Duplicate universal-spawn-rules prose** from SKILL.md (was in both SKILL.md and protocol.md). Single-sourced in protocol.md.

### Measured impact

- **SKILL.md: 308 → 117 lines** (62% reduction in always-loaded context).
- **`references/protocol.md`: 400 → 288 lines** (28% reduction after removing spawn-rule duplication and the obsolete inlined binding-constraints template).
- **Shared-brief pattern: expected ~7–12k tokens saved** per 8-seat council on constraint-heavy projects, via prompt-cache hits.
- **Three files extracted** to references (implementation-handoff, tracker-integration, review-mode) — loaded only when relevant.

## [0.1.4] — pre-0.2.0

Tracker-agnostic framing + three new handoff gotchas (worktree base drift, tracker-state pollution, per-lane CHANGELOG conflicts).

## [0.1.3] — pre-0.2.0

Review-mode variant + universal spawn prompt rules + Phase 2.5 handshake verification.

## [0.1.2] — pre-0.2.0

Refinements from the `sync-aem` council session.

## [0.1.1] — pre-0.2.0

README alignment with SKILL.md handoff guidance.

## [0.1.0] — pre-0.2.0

Initial migration of the `design-council` skill into a Claude Code plugin.
