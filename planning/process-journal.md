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

## Session — 2026-06-24

**Phase:** WS-2 — Dog Models & Grooming Zones

**Summary:**
- Built procedural placeholder dog model (CSG-style primitives: capsule body, sphere head, cylinder legs, box ears, cylinder tail) as reusable scene
- 11 grooming zones with Area3D + CollisionShape3D: head, ears_left, ears_right, back, chest, belly, legs_front_left, legs_front_right, legs_rear_left, legs_rear_right, tail
- Orbit camera with horizontal 360 deg, vertical 15-75 deg clamped, pinch-to-zoom / scroll wheel, touch + mouse support, smooth interpolation
- Shell fur shader (Compatibility renderer compatible): 6-layer shell extrusion with alpha-masked procedural noise, fur_color/tip_color gradient, groomed_amount parameter for visual feedback, highlight_strength for hover, guide_overlay_strength for color-coded overlay
- ShellFurSetup utility class creates shell layer duplicates at runtime to avoid bloating the .tscn
- ZoneDetection rewritten from stub: raycasts from camera through Area3D zones using zone_id metadata, emits zone_hover_changed signal, try_groom_at_position emits EventBus.zone_groomed
- DogModel controller script: manages zone discovery, highlight state, groomed state, guide overlay toggle with guard-size color mapping
- Grooming arena scene: SubViewport with dog model + orbit camera, 3-point lighting (warm key, cool fill, rim), ground plane, UI overlay with guide toggle button, zone info label, color-coded legend panel
- Default shell fur material resource in materials/

**Design decisions:**
- Shell layers created at runtime via ShellFurSetup rather than baked into .tscn — keeps placeholder scene clean and swappable
- Zone identification uses Node.set_meta("zone_id") on both Area3D and MeshInstance3D nodes — lightweight, no extra scripts per zone
- Orbit camera uses _unhandled_input so UI elements can consume input first
- Right-click to groom (left-click reserved for orbit) — placeholder until tool system (WS-3) wires in proper tool-apply input
- Guard size legend uses 7 color bands matching real grooming guard sizes (0" through 6")
- SubViewport used for 3D scene to cleanly separate 3D rendering from 2D UI overlay

**Blockers:**
- None
