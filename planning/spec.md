# Dog Grooming Working Project — Spec (LOCKED)

> Locked: 2026-06-24 — Discovery complete, user signed off.

---

## Problem

No high-quality arcade-style dog grooming time-management game exists on mobile. The competitive dog grooming / kennel club world is rich with real content (breed standards, show culture, grooming technique) but no game has tapped it. Existing titles are either low-fidelity casual minigames or shallow sims with no progression depth.

## Users

- **Primary:** mobile gamers aged 13+
- **Profile:** casual-to-mid-core players who enjoy time-management games (Cooking Mama, Diner Dash), animal content, and light tycoon progression
- **Secondary:** dog enthusiasts interested in breed education / infotainment

## Concept

Competitive dog grooming time-management game. You're a dog groomer climbing the kennel club circuit — from amateur local shows to elite national competitions. Cooking Mama meets dog show culture.

## Core Loop (2–5 minute sessions)

1. **Receive a dog** — presented with a breed-specific grooming guide: color-coded overlay showing clip directions, guard sizes (e.g., 1-inch vs 6-inch), rotatable 3D model.
2. **Groom** — select tools from a toolbar and apply to the dog (tap/touch target areas). Tool-select-and-apply is the primary input mode; system architected with an abstraction layer so gesture-based input can be added/toggled later.
3. **Extras** — optional actions: spray-on colognes, administer allergy meds, apply accessories. Creative extras that improve the dog's show performance.
4. **Score** — judged on accuracy to breed standard + time bonus + style points. AI judge panel with hidden preferences (pay coins to reveal preferences before a competition).
5. **Earn & progress** — rewards fund equipment upgrades, unlock new breeds, advance to higher-tier competitions.

## Competition System

- **Structure:** tiered kennel club circuit (local amateur → regional → national elite)
- **Judging:** AI judge panel with individual hidden preferences
  - Pay coins to reveal a judge's preference before a show (strategic resource spend)
  - Scoring combines: breed-standard accuracy, time bonus, style points
- **Scoring details:** refined iteratively during development — exact weights and formulas TBD

## Progression

| Tier | Competitions | Tools | Breeds | Complexity |
|------|-------------|-------|--------|------------|
| Early | Local amateur shows | Basic clippers, dryer, brush | ~4 starter breeds | Simple cuts, forgiving scoring |
| Mid | Regional circuits | Specialized guards, pro dryer, styling tools | ~10+ breeds | Complex breed-specific cuts |
| Late | National kennel club | Pro-grade everything, rare consumables | Exotic/rare breeds | High-stakes judging, tight tolerances |

Breed count grows with progression — new breeds unlock as you advance through tiers.

## Tycoon Layer (Medium Depth)

Subordinate to the core grooming gameplay — enhances, never overshadows.

- **Equipment upgrades:** clippers, guards (various sizes), dryers, grooming tables
- **Consumables:** colognes, allergy meds, special shampoos, accessories
- **Salon upgrades:** cosmetic improvements to your workspace
- **Resource management:** lightweight — spend wisely to prepare for competitions

The tycoon loop feeds back into the core loop: better equipment → better grooming capability → higher competition scores → more rewards.

## Infotainment System

Breed education is a core pillar, not an afterthought.

- **In-game callouts:** during grooming, contextual facts appear ("Irish Terriers get a hand-stripped coat because...")
- **Grooming guide overlay:** color-coded map on the 3D dog model showing clip directions, guard sizes per body region — visible and rotatable during gameplay
- **Breed-pedia:** collectible encyclopedia, entries unlock as you encounter each breed
- **Loading screen tips:** breed facts, grooming technique tips
- **Reinforcement:** every time you groom a breed, the guide and callouts reinforce the correct technique — learn by doing

## Art Style

Stylized cartoony — not chibi/kawaii, not realistic. A warm, appealing middle ground appropriate for the 13+ audience and the educational content.

## Monetization

- **Model:** Free-to-play with IAP + ads
- **IAP candidates:** premium tools, cosmetic salon items, coin packs, reveal-judge-preference tokens
- **Ads:** rewarded video ads (extra coins, free reveals, energy refills); interstitial between sessions
- **No pay-to-win:** IAP accelerates or decorates, doesn't gate core content

## Social Features (if easily integrated)

- Leaderboards (per competition tier)
- Friend challenges (async)
- Competitive events

Not MVP-critical — integrate if the architecture supports it without significant additional complexity.

## Platform & Technical

- **Platform:** mobile-first (iOS + Android)
- **Offline:** fully functional offline — no always-online requirement
- **Performance target:** 60fps on mobile
- **Fur rendering:** simplified approach (shell texturing or equivalent) for mobile performance; strand-based upgrade path for potential PC port
- **Input abstraction:** tool-select-and-apply primary, architecture supports future gesture-based mode toggle
- **3D model:** rotatable dog models with per-region interaction zones

## Future Scope (Not MVP)

- Other pets (cats, rabbits, etc.) — each is a significant content investment
- Gesture-based input mode toggle
- VR support (only if it makes sense)
- PC port with enhanced fur rendering

## Inspiration

- **Cooking Mama** — tactile mini-game feel, satisfying completion
- **Diner Dash** — time-management pacing, session length
- **PowerWash Simulator** — satisfying cleanup/completion loop (tonal reference)
- **Real kennel club culture** — breed standards, show circuits, competitive grooming as a real profession

## Design Principles

1. **Core loop is king** — every system serves the grooming gameplay, not the other way around
2. **Learn by playing** — breed education emerges naturally from gameplay, never feels like homework
3. **Short sessions, long progression** — 2-5 min sessions that feed a months-long unlock arc
4. **Input flexibility** — architect for the input mode we want later, not just the one we start with
5. **Iterate scoring** — competition judging is a living system refined through playtesting, not locked in spec
