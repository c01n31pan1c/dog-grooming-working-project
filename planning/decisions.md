# Architecture Decision Records

> Every major decision: what was chosen, why, and what alternatives were rejected.

---

## ADR-001: Target Audience — 13+

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Youth audience, need to balance monetization flexibility with accessibility. Under-13 triggers strict COPPA requirements limiting ad networks and data collection.
**Decision:** Target 13+ to maximize monetization options (broader ad networks, fewer data restrictions) while keeping the stylized cartoony art style appealing to younger-skewing players.
**Alternatives rejected:**
- 6-10 (too restrictive for monetization, limits gameplay complexity)
- 10-14 (13 is the key COPPA boundary; straddling it creates compliance ambiguity)

## ADR-002: Primary Input Mode — Tool-Select-and-Apply

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Need a grooming interaction model. Options: gesture-based (swipe/drag), tool-select-and-apply (pick tool, touch area), guided sequence (step-by-step).
**Decision:** Tool-select-and-apply as primary. Requires player to choose the right tool for each area, adding a decision layer. Architecture includes input abstraction layer so gesture-based mode can be added later without refactoring.
**Alternatives rejected:**
- Gesture-based only (less strategic, harder to map complex tool choices)
- Guided sequence (too hand-holdy, removes decision-making)

## ADR-003: Monetization — F2P with IAP + Ads

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Mobile game targeting 13+ casual audience.
**Decision:** Free-to-play with in-app purchases and ad support. No pay-to-win. IAP for acceleration/cosmetics, rewarded video ads for bonus resources.
**Alternatives rejected:**
- Premium ($) — limits audience reach on mobile for this genre
- Subscription — no precedent in this genre, high churn risk
