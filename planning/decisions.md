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

## ADR-004: Game Engine — Godot 4.x (GDScript)

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Need a game engine for a stylized cartoony 3D mobile game with shell-based fur shaders, rotatable models, and tool-based interaction. Project is learning-first with commercial potential as a secondary goal.
**Decision:** Godot 4.x with GDScript. Compatibility renderer for mobile builds, Forward+ for desktop testing.
**Rationale:**
- Dramatically faster learning curve — GDScript is simpler than Unity C# ecosystem, more time building vs fighting the engine
- Faster iteration: lighter editor, quicker builds, less boilerplate
- Open source with no licensing fees or runtime costs
- Smaller APK sizes (~30-40MB vs Unity's 70-100MB+) — better for mobile youth audience
- Custom shader language (GLSL-like) handles shell-based fur shaders well
- Stylized cartoony art doesn't push Godot's 3D limits
- 60fps mobile achievable with Compatibility renderer for this scope
**Alternatives rejected:**
- Unity 6.3 LTS (URP) — superior monetization SDK ecosystem (first-party AdMob, IAP, analytics) and more mature 3D pipeline, but steeper learning curve, heavier builds, licensing overhead. Remains the backup/port target if commercial monetization demands first-party SDK support.
- Unreal Engine 5 — 150-300MB minimum APK, desktop-first architecture, no ad/IAP SDKs, overkill for stylized mobile game. Wrong-sized for this project.

## ADR-005: Architecture Pattern — MVP + Godot Resources + Signal Bus

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Need an architectural pattern that keeps the codebase modular and maintainable without over-engineering for this project's scale.
**Decision:** Model-View-Presenter pattern with Godot Resources for static data and a signal-based event bus for decoupling. No ECS — overkill for this scale.
- **Godot Resources** replace Unity ScriptableObjects: designer-editable, version-controlled, zero parse cost. Used for breed definitions, tool stats, judge profiles, upgrade data.
- **Signal bus** (autoload singleton) for cross-system communication
- **State machine** (enum-driven) for flow control between game screens
**Alternatives rejected:**
- ECS/DOTS-style (unnecessary complexity for a grooming sim)
- Tight coupling / no pattern (unmaintainable as scope grows)

## ADR-006: Scene Organization — Bootstrap + Additive Scenes

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Need to organize game screens for mobile memory management and clean separation.
**Decision:** One persistent autoload Bootstrap (holds singletons/services) plus separate scenes for each major context: Salon, GroomingArena, Competition, BreedPedia, Shop. Scenes loaded/switched as needed.
**Alternatives rejected:**
- Single scene with everything (memory-heavy on mobile, messy to develop)
- Fully additive layering (over-engineered for this scope)

## ADR-007: Data Storage — Godot Resources + JSON Save Files

**Date:** 2026-06-24
**Status:** Accepted
**Context:** Need storage for static game data and player progression, fully offline.
**Decision:**
- Static data (breeds, tools, judges, upgrades): Godot Resources (.tres/.res files)
- Player save data (progression, inventory, currency): JSON files in `user://` directory with versioned schema
- Async I/O for save operations to avoid frame hitches
**Alternatives rejected:**
- SQLite — DLL management and platform edge cases not worth it for this data volume
- Binary serialization — harder to debug, no human readability

## ADR-008: Input Abstraction — Strategy Pattern via Interface

**Date:** 2026-06-24
**Status:** Accepted
**Context:** MVP uses tool-select-and-apply, but gesture-based input mode may be added later. Need clean swap capability.
**Decision:** Strategy pattern with a common interface/base class:
- `GroomingInput` base class defining signals: `tool_applied`, `pointer_moved`, `set_active_tool()`
- `TapSelectInput` implementation for MVP (select tool from toolbar, tap dog region)
- `GestureInput` implementation added later (swipe-to-brush, pinch-to-trim)
- `GroomingController` consumes only the base interface, never concrete input classes
- Swap implementations via injection at scene load
**Alternatives rejected:**
- Hardcoded input (blocks future gesture mode without refactor)
- Input mapping only (insufficient abstraction for fundamentally different interaction models)
