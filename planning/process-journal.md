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

**Phase:** Wave 2 — Parallel Feature Tracks (WS-2 through WS-7)

**WS-2 — Dog Models & Grooming Zones:**
- Procedural placeholder dog model (capsule body, sphere head, cylinder legs, box ears, cylinder tail)
- 11 grooming zones with Area3D + CollisionShape3D
- Orbit camera: 360° horizontal, 15-75° vertical, pinch-to-zoom, smooth interpolation
- Shell fur shader: 6-layer, Compatibility renderer compatible, groomed_amount + highlight + guide overlay params
- ShellFurSetup creates shell layers at runtime (keeps .tscn clean/swappable)
- ZoneDetection: raycasts through Area3D zones using zone_id metadata
- Grooming arena scene: SubViewport + 3-point lighting + UI overlay with guide toggle + legend

**WS-3 — Tool System & Input:**
- 9 starter tool .tres resources (3 clippers at 1/3/6-inch, brush, dryer, scissors, nail trimmer, shampoo, cologne)
- ToolSystem: loads from disk, tracks ownership, filters by type, emits selection events
- GroomingController: tool-zone validation, quality scoring vs breed standards, prep-sequence tracking
- Toolbar UI: horizontal scrollable bar at bottom, guard sizes on clipper buttons, active tool highlight
- TapSelectInput: proper 3D raycasting via Camera3D, PhysicsRayQueryParameters3D targeting Area3D zones

**WS-4 — Competition & Scoring:**
- 3 judge .tres resources (Mrs. Pemberton/traditional, Carlos Rivera/flashy, Dr. Tanaka/balanced)
- TimerSystem: countdown, warnings, time bonus calc
- ScoringEngine: accuracy/time/style scoring against breed standard
- JudgeAI: per-judge weighted eval, strictness penalty, personality-keyed comments
- CompetitionData resource class
- Competition screen: 3-phase flow (pre-show, grooming, results) with judge reveal mechanic

**WS-5 — Progression & Tycoon:**
- CurrencyManager: balance tracking, auto-save, lifetime total_coins_earned
- UpgradeSystem: dynamic catalog loading, purchase/own/consumable tracking, stat modifiers
- ProgressionManager: 3-tier system (LOCAL→REGIONAL→NATIONAL), auto-advancement
- ShopManager: categorized inventory, purchase flow
- Shop scene with Equipment/Consumables/Salon Decor tabs
- Salon hub scene with tier progress, stats, navigation

**WS-6 — Breed Data & Infotainment:**
- 4 breed .tres resources with AKC-researched grooming data (Poodle, Golden Retriever, Schnauzer, Irish Terrier)
- Grooming callouts: contextual breed facts during grooming, non-repeating, auto-dismiss
- Breed-pedia: collection grid + detail view with zone grooming guide
- 28 loading screen tips

**WS-7 — UI & Menus:**
- Main menu with Play/Breed-pedia/Settings, player info bar
- HUD: timer with urgency colors, tool indicator, progress bar, guide toggle, pause
- Competition select: scrollable cards, detail panel, entry fee check
- Settings overlay: audio sliders with AudioServer integration
- Scene transitions: fade-to-black via CanvasLayer
- UI theme: warm color palette, rounded buttons, touch-friendly sizing

**Blockers filed:**
- BLK-001: SceneTransition autoload needs registration in project.godot
- BLK-002: SaveManager missing master_volume default (non-blocking, handled with fallback)

**Blockers:**
- None critical — BLK-001 and BLK-002 resolved during integration merge
