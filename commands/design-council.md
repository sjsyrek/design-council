---
description: Convene parallel role-specialized peer agents to debate a cross-domain decision
argument-hint: [decision-or-focus]
---

Invoke the `design-council` skill on the current project.

**Decision or focus**: $ARGUMENTS

If the decision/focus above is empty, ask the user what decision or codebase area the council should convene on, then proceed. If the decision/focus is provided, treat it as the council's opening question — the CEO will frame it into the Phase 0 plan card and the eventual opening prompt to seats.

Begin with Phase 0 (plan card) before any `TeamCreate`. Do not skip the plan card even though the slash command was explicit; the user still needs to confirm roster, models, and budget.
