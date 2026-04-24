# Review-mode variant

The default protocol is **debate-oriented**: seats post verdicts on a single proposal, peer-DM to resolve disagreements, CEO arbitrates what's left. That shape fits *decisions* (OAuth vs API keys, monolith vs split, migrate now vs later).

For **audit / review** tasks — "review this repo for P0/P1 issues", "security audit of the auth flow", "pre-1.0 hardening pass" — that shape misfits. Seats work disjoint sub-areas, peer-DMs are rare, and cross-talk rounds 2–3 add no value.

**Signal that you should be in review mode:** the user asks for a "review" over a broad scope and expects many findings back, not one decision.

## Protocol adjustments

1. **Phase 1 Brief:** use `opening-prompt-template.md` → Review-mode section. Strict finding format, priority filter (P0/P1 only by default), evidence rules. Partition the codebase/scope across seats in the opening prompt so findings don't duplicate.
2. **Phase 2 Convene:** same parallel fan-out. Still run Phase 2.5 handshake verification.
3. **Phase 3 Cross-talk:** **SKIP by default.** Review seats rarely need to DM each other. Only run Phase 3 if the CEO sees ≥2 overlapping findings that need deduplication via the seats themselves (rare — the CEO usually dedupes at Phase 4).
4. **Phase 4 Arbitration:** repurposed to **deduplicate overlapping findings** across seats and decide whether merged findings file as one or many tracker items. Verdict tags (APPROVE/CONCERNS/BLOCK) are not used; findings carry a priority tag (P0/P1) instead.
5. **Phase 5 Decision log:** primary artifact is the **file-ownership execution map** of the filed tracker items, not arbitration rationale. The "Opening verdicts" and "Resolved disagreements" sections are typically empty — replace with "Per-seat finding counts" and "CEO dedup decisions." Bulk-file tracker items (review mode can produce dozens) before teardown.

## Output format (strict, enforced on every seat)

Every finding emits exactly this block:

```
## FINDING <N>: <≤70-char imperative title>
- Priority: P0 | P1
- Type: bug | chore | task | feature
- Evidence: <file:line | grep 'pattern' → N hits | command output>
- Rationale: <why this priority — impact × likelihood, 1–2 sentences>
- Scope: investigate | fix — <effort estimate>
- Description: <3–5 sentences, self-contained, ready for `bd create --description` or equivalent>
```

Zero-findings line (when the seat's area is clean): `NO P0/P1 FINDINGS — <one-line reason>`.

**Per-seat max:** 5 findings. If more exist, triage to the top 5 and note overflow.

## Universal spawn rules still apply

Handshake, SendMessage-only, final-work-delivered-via-SendMessage, base-fix-instruction-on-worktrees — all unchanged. Silent-spawn failures are more common at large review rosters; a seat that never actually started silently reduces review coverage, so Phase 2.5 handshake verification is mandatory.

## Review-mode decision log differences

The log frontmatter and sections diverge from debate mode:

- **Opening verdicts** section → drop; replace with **Per-seat finding counts** (P0/P1 breakdown per seat).
- **Resolved disagreements** → drop; replace with **CEO dedup decisions** (overlapping findings merged with brief rationale).
- **Execution plan** → becomes a **file-ownership map of the filed tracker items**. Which clusters share code and must be serialized for follow-up implementation.
- **Un-spawned seats / uncovered domains** → add a section when Phase 2.5 dropped any seats, so future maintainers know which lanes were not reviewed.

See `decision-log-template.md` for both variants.
