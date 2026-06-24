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

## Session 3 — 2026-06-24

**Phase:** WS-3 — Tool System & Input

**Summary:**
- Created 9 starter tool .tres resources (3 clippers at 1/3/6-inch guards, brush, dryer, scissors, nail trimmer, shampoo, cologne)
- Fleshed out ToolSystem: loads tools from disk via DirAccess, tracks ownership, filters by type, emits selection events
- Fleshed out GroomingController: full tool-zone validation, quality scoring against breed standards, per-zone progress tracking with prep-sequence awareness (brush-before-clip bonus, shampoo-dry flow)
- Created Toolbar UI script: horizontal scrollable button bar at bottom of screen, shows guard sizes on clipper buttons, highlights active tool, sorts tools by type
- Updated TapSelectInput: proper 3D raycasting via Camera3D.project_ray_origin/normal, PhysicsRayQueryParameters3D targeting Area3D grooming zones, resolves zone_id from node metadata or name

**Design decisions not in ADRs:**
- Grooming zones are Area3Ds on collision layer 2; TapSelectInput raycasts with collide_with_areas=true, collide_with_bodies=false
- Zone identification: Area3D nodes should set "zone_id" metadata; falls back to node.name — this avoids coupling zone detection to a specific naming convention while keeping it simple
- Quality scoring: perfect guard match = 1.0, wrong guard = partial credit scaled by distance (min 0.2), wrong tool type = 0.3, brushing before cutting = +0.1 bonus (capped at 1.0)
- Nail trimmer restricted to PAW_ZONES const array; scissors get 0.7 quality on detail zones even when not the required tool (realistic — scissors are flexible in real grooming)
- All starter tools granted including consumables (shampoo/cologne) for MVP — shop gating comes later
- Toolbar sorts tools by ToolType enum order then guard_size for consistent UX

**Agents dispatched:**
- None (direct implementation — cohesive system with tight interdependencies)

**Blockers:**
- None
