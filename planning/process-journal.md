# Process Journal

> Orchestrator notes per session: dispatches, results, surprises, distillation candidates.

---

## Session 1 — 2026-06-24

**Phase:** Discovery → Spec Lock

**Summary:**
- Ran two parallel research agents: market landscape + tech stack analysis
- Market research revealed weak competition — no high-fidelity grooming sim exists, especially not with competitive/show angle
- Tech research confirmed Unity as recommended engine with shell-based fur for mobile
- 4 rounds of Discovery Q&A with user
- Key insight from user: the kennel club competition progression arc is the core differentiator — not just a grooming salon, but competitive show grooming
- Spec locked with user sign-off

**Agents dispatched:**
- Research agent: dog grooming game market landscape (completed)
- Research agent: game engine/tech stack for grooming sims (completed)

**User corrections:**
- None — smooth Discovery with clear user vision

**Surprises:**
- The competition/show angle emerged organically and became the defining feature
- User wants infotainment as a core pillar, not just flavor — real breed education

**Distillation candidates:**
- None yet (Phase 1 only)

## Session 2 — 2026-06-24

**Phase:** WS-1 — Core Project Scaffold

**Summary:**
- Created full Godot 4.3+ project scaffold per spec, ADR-004 through ADR-008
- 4 autoload singletons functional: EventBus, GameManager, SceneManager, SaveManager
- 4 custom Resource classes: BreedData, ToolData, JudgeData, UpgradeData
- Input abstraction layer with GroomingInput base + TapSelectInput implementation
- 6 scene shells with scripts aware of GameManager state
- Stub scripts for all subsystems (grooming, competition, tycoon, breed_pedia)
- Export presets skeleton for Android + iOS
- .gitignore for Godot

**Design decisions not in ADRs:**
- EventBus loads before GameManager in autoload order (GameManager references SceneManager which references EventBus)
- Scene shell scripts set GameManager.current_state directly in _ready() as a safety net — GameManager.change_state() is the primary transition path but if a scene is loaded directly (e.g., during development), state stays consistent
- SaveManager uses tab-indented JSON for human readability during development
- Resource class .gd files live alongside their .tres instances in resources/ subdirectories rather than in scripts/ — keeps data definitions co-located with data instances
- DataLoader uses DirAccess to scan resource directories dynamically rather than hardcoded lists

**Agents dispatched:**
- None (direct implementation — scaffold is a single coherent unit)

**Surprises:**
- None — clean build from spec
