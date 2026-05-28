# Changelog

All notable changes to the design-council plugin are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] — 2026-05-28

Documentation-only patch. The README "Slash command" section and the SKILL.md "What the user sees" invocation note now show the actual namespaced form (`/design-council:design-council`) instead of the bare form. Claude Code namespaces every plugin slash command as `/<plugin>:<command>` to avoid collisions across third-party plugins; the bare `/design-council` form (advertised in 0.4.0) was never a valid invocation.

### Fixed

- **README**: `/design-council [decision-or-focus]` → `/design-council:design-council [decision-or-focus]` in the Slash command section and example.
- **SKILL.md**: same fix in the "What the user sees" invocation note.

## [0.4.0] — 2026-05-28

Slash-command standardization across the `sjsyrek/claude-plugins` marketplace. `design-council`, `red-team`, and the new `compliance-panel` plugin all now expose both proactive trigger-phrase invocation and an explicit `/<plugin-name>` slash command, so users have one consistent invocation idiom regardless of which plugin they reach for.

### Added

- **`/design-council` slash command** (`commands/design-council.md`) with optional `[decision-or-focus]` argument. The slash invocation still routes through Phase 0 plan card — the user confirms roster, models, and budget before any seat spawns.
- **README "Slash command" section** documenting the new invocation pathway alongside the existing trigger phrases.
- **`SKILL.md` "What the user sees" invocation note** linking the slash command and trigger phrases as equivalent entry points.

## [0.3.0] — 2026-05-27

Two roster additions surfaced by a contributor running design-councils on infrastructure decisions ([@Tazmainiandevil](https://github.com/Tazmainiandevil), PR #1): a dedicated reliability seat (`sre-engineer`) and an expanded `finops-engineer` covering the infrastructure FinOps layer. Both remain opt-ins; the default 11-seat roster is unchanged.

### Added

- **`sre-engineer` opt-in seat.** Reliability lens distinct from `devops-engineer`'s deployment-lifecycle lens: blast radius (direct + cascading downstream), rollback validated by execution time not just designed ("we have rolled back and it took N minutes" is the bar, not "we can"), SLO/SLI ownership and error-budget policy, graceful degradation vs. hard failure, MTTD relative to blast radius, toil introduced without an automation path, capacity assumptions backed by data. Four vetoes: untested rollback, silent failure modes, SLO-violating design, unverified cascading blast radius. Activate alongside `devops-engineer` on decisions with production reliability stakes (new services, significant load-profile changes, shared infrastructure).
- **`sre`↔`devops` pairing hint** in the `SKILL.md` opt-in line so the CEO doesn't spawn both seats redundantly on lower-stakes decisions. `README.md` opt-ins list now also includes `sre-engineer`.

### Changed

- **`finops-engineer` extended to cover the infrastructure FinOps layer.** Existing scope (product/API/LLM costs, quotas, tiering) preserved verbatim; new ownership areas added — cost allocation and tagging, unit economics (cost per business-value unit), rate optimization (reserved/committed vs. on-demand), resource lifecycle (TTLs, orphan prevention), workload placement (managed vs. self-managed TCO), licensing, anomaly coverage, dev/staging cost parity. Two new vetoes: untagged/unallocated resources, missing anomaly coverage. Opening framing sharpened — spend should be *proportional to business value*, not just minimized.
- **`plugin.json` + `SKILL.md` frontmatter version → 0.3.0.** MINOR per Conventional Commits: additive features, no breaking change.

## [0.2.1] — 2026-04-24

Documentation-only patch release. Three small protocol-text tweaks surfaced during the first fresh-session dogfood of 0.2.0 (an end-to-end council on a real data-loss P0 in the beads tracker). No behavioral change; no code change.

### Changed

- **Structured-response requirement in spawn-prompt contract.** Universal rule 3 now explicitly reminds seats that protocol responses (`shutdown_response`, `plan_approval_response`) must use their structured JSON form — prose acks don't close the protocol state and will block teardown. Observed on the bd-q83 dogfood: one seat prose-acked the shutdown request, blocking `TeamDelete` until a follow-up nudge. `SKILL.md` + `references/protocol.md` Phase 2 updated in parallel.
- **Cross-talk closure waits for in-flight DMs.** `references/protocol.md` Phase 3 "Round closure" now instructs the CEO to verify no peer-DM exchange is mid-flight (check idle-notification `[to <seat>]` summary markers within the current round) before declaring the round closed. Writing Phase 4 arbitration on incomplete cross-talk forces a rewrite when the late convergence arrives. Observed on the bd-q83 dogfood: integration-security converged ~10 seconds after CEO had drafted v1 of the decision log, forcing a v2 revision. The one-more-idle-cycle wait costs little and prevents the rewrite.
- **Opening-prompt template carries prior-council context.** `references/opening-prompt-template.md` now has a "Prior-Council Context" section for decisions that originated from a prior council (deferred items, audit findings, punted follow-ups). Includes the prior log path, originating seat/finding, execution-plan cluster, and explicit non-litigated items. Seats need the prior framing to mesh cleanly with earlier decisions; omitting this makes the new council re-derive context the prior log already settled.

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
