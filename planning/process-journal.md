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

## Session — 2026-06-24

**Phase:** WS-7 — UI & Menus

**Summary:**
- Built complete UI framework: main menu, HUD, competition select, settings overlay, scene transition, and UI theme
- Main menu scene (main_menu.tscn) fully rebuilt with responsive layout: player info bar (tier + coins) at top, stylized title centered, Play/Breed-pedia/Settings buttons in lower 60% for thumb reach, cream background, embedded settings overlay
- HUD script (hud.gd) as CanvasLayer: timer with yellow/red urgency coloring, tool indicator, grooming progress bar, coin balance, guide toggle, pause button. Listens to EventBus signals (zone_groomed, tool_selected, currency_changed)
- Competition select (competition_select.gd): scrollable card list with tier badge, breed, time limit, entry fee. Detail panel with full info and "Enter" button that checks funds. Locked competitions greyed out with requirement text. Placeholder competition data for 3 competitions
- Settings overlay (settings_screen.gd): Master/Music/SFX volume sliders with percentage labels, audio bus integration, controls placeholder, version display, credits placeholder. Saves via SaveManager
- Scene transition (scene_transition.gd): CanvasLayer with ColorRect fade, 0.3s duration, auto-hooks into SceneManager.scene_unloading/scene_loaded signals, blocks input during transitions
- UI theme (resources/ui_theme.tres): warm color palette (soft blues for buttons, cream backgrounds, green progress bars), 12px rounded corners on buttons, consistent padding, styled panel containers, slider and progress bar styles

**Design decisions:**
- Settings is an overlay (not a scene change) — embedded directly in main_menu.tscn, toggled via visibility. Same pattern can be used when settings is opened from other scenes
- Buttons positioned in lower 60% of screen via VBoxContainer stretch ratios (TopSpacer 1.5 : MidSpacer 1.0 : BottomSpacer 0.5) ensuring thumb-reach on mobile
- All touch targets minimum 80px height (buttons) or 44px height (sliders) for mobile usability
- HUD timer urgency: yellow at 40% remaining, red at 15% remaining — provides two escalation levels
- Competition cards built dynamically in code (not in .tscn) since they'll be data-driven from resources
- Scene transition connects to SceneManager signals automatically — no manual calls needed from other systems
- UI theme applied at scene root level so all children inherit; individual nodes can override with theme_override_* properties
- Competition select uses placeholder data array — will be replaced by resource-driven data when breed/competition resources are populated

**Blockers:**
- SceneTransition needs to be registered as an autoload in project.godot (DO NOT TOUCH per ownership rules — needs orchestrator or WS-1 owner to add: `SceneTransition="*res://scripts/ui/scene_transition.gd"`)
- SaveManager default_data does not include "master_volume" in settings dict — settings_screen.gd handles this gracefully with .get() defaults, but SaveManager should add it for consistency

## Session — 2026-06-24

**Phase:** WS-6 — Breed Data & Infotainment

**Summary:**
- Created 4 breed .tres resources with researched, accurate grooming data: Standard Poodle, Golden Retriever, Miniature Schnauzer, Irish Terrier
- Each breed has 10-12 grooming facts, 11 grooming zones with required tools, guard sizes, step sequences, suggested grooming order, and groomer notes
- Built GroomingCallouts system (grooming_callouts.gd): displays contextual breed facts during grooming, auto-dismiss after 4s, no repeats within session, cooldown between popups
- Built BreedViewer detail view (breed_viewer.gd): shows breed info, all facts, zone-by-zone grooming guide with tool/guard/steps, difficulty rating, lock overlay for locked breeds
- Built BreedPediaScreen (breed_pedia_screen.gd): collection grid of breed cards sorted by difficulty, tracks encountered breeds, signals first encounters via EventBus.breed_unlocked
- Updated breed_pedia.tscn scene with full UI node tree for collection view and detail view
- Created LoadingTips (loading_tips.gd): 28 tips mixing breed facts, grooming techniques, and gameplay hints, no-repeat-within-session via static tracker
- Added get_zone_color() static method on BreedViewer for grooming guide overlay color mapping (guard size to warm/cool color spectrum)

**Breed research sources:**
- AKC Standard Poodle grooming guide, Andis Poodle grooming chart, Groomers Online
- AKC Golden Retriever grooming guide, GoldenRetriever.hair, Petco grooming guide
- American Miniature Schnauzer Club procedures, Schnauzers-Rule grooming chart, Groomers Online
- North of England Irish Terrier Club grooming guide, Irish Terrier Club of Chicago, Learn2GroomDogs

**Design decisions:**
- BreedData resource class unchanged — Dictionary type for grooming_zones already supports the richer per-zone data (steps, suggested_order, notes)
- Guard size of 0.0 used for zones requiring scissors, brush, or hand-stripping (no clipper guard needed)
- Zone color mapping: red (very close <1mm) -> orange (short <3mm) -> yellow (medium <10mm) -> green (long 10mm+) -> blue (no guard / scissors work)
- LoadingTips uses static vars for session tracking since it's a utility class, not a node
- GroomingCallouts is a CanvasLayer to ensure it renders above gameplay
- Encountered breeds tracked in a Dictionary for O(1) lookup; persistence via SaveManager is stubbed (restore_encountered/get_encountered_list methods ready)

**Blockers:**
- None
