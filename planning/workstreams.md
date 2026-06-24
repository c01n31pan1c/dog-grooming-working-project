# Workstreams

> Parallel tracks with owner agents, state, and dependencies.

---

## Wave 1 — Foundation

### WS-1: Core Project Scaffold
- **State:** 🔵 ACTIVE
- **Owner:** builder-scaffold
- **Dependencies:** none
- **Deliverables:**
  - Godot 4.x project with correct folder structure per ADR-005
  - Autoload singletons: GameManager, EventBus (signal bus), SceneManager
  - State machine (enum-driven): MainMenu, Salon, GroomingArena, Competition, BreedPedia, Shop
  - Empty scene shells for each major context
  - Base Resource classes: BreedData, ToolData, JudgeData, UpgradeData
  - Input abstraction: GroomingInput base, TapSelectInput stub
  - SaveManager with JSON read/write to user://
  - .gitignore for Godot project
  - Export presets for Android/iOS (skeleton)

---

## Wave 2 — Parallel Feature Tracks (starts after WS-1)

### WS-2: Dog Models & Grooming Zones
- **State:** ⚪ WAITING (blocked on WS-1)
- **Owner:** builder-models
- **Dependencies:** WS-1
- **Deliverables:**
  - 3D dog model pipeline (placeholder/prototype models)
  - Per-region interaction zones (clickable areas mapped to body parts)
  - Orbit camera / rotation controls (touch drag to rotate)
  - Shell fur shader (Compatibility renderer compatible)
  - Grooming state per zone (ungroomed → groomed visual feedback)

### WS-3: Tool System & Input
- **State:** ⚪ WAITING (blocked on WS-1)
- **Owner:** builder-tools
- **Dependencies:** WS-1
- **Deliverables:**
  - ToolData Resources (clipper variants with guard sizes, brush, dryer, scissors, etc.)
  - Toolbar UI (select active tool)
  - TapSelectInput full implementation (select tool → tap zone → apply)
  - GroomingController connecting input → tool → zone → visual feedback
  - Tool effect system (each tool type modifies zone state differently)

### WS-4: Competition & Scoring
- **State:** ⚪ WAITING (blocked on WS-1)
- **Owner:** builder-competition
- **Dependencies:** WS-1
- **Deliverables:**
  - JudgeData Resources (personality, preferences, scoring weights)
  - ScoringEngine: accuracy to breed standard + time bonus + style points
  - Competition flow: pre-show → grooming phase → judging → results
  - Timer system with time-pressure UI
  - Judge preference reveal mechanic (spend coins to peek)
  - Results screen with score breakdown

### WS-5: Progression & Tycoon
- **State:** ⚪ WAITING (blocked on WS-1)
- **Owner:** builder-progression
- **Dependencies:** WS-1
- **Deliverables:**
  - CurrencyManager (coins earned from competitions)
  - UpgradeData Resources (equipment tiers, prices, effects)
  - Shop/upgrade UI
  - Tier progression (local → regional → national)
  - Breed unlock system (new breeds available at higher tiers)
  - Save/load integration (persist progression to JSON)

### WS-6: Breed Data & Infotainment
- **State:** ⚪ WAITING (blocked on WS-1)
- **Owner:** builder-breeds
- **Dependencies:** WS-1
- **Deliverables:**
  - BreedData Resources for starter breeds (~4): grooming standards, facts, required tools, guard sizes per zone
  - Breed-pedia scene (collection view, detail view per breed)
  - In-game callout system (contextual breed facts during grooming)
  - Grooming guide overlay (color-coded body map showing clip directions/guard sizes)
  - Loading screen tip system

### WS-7: UI & Menus
- **State:** ⚪ WAITING (blocked on WS-1)
- **Owner:** builder-ui
- **Dependencies:** WS-1
- **Deliverables:**
  - Main menu scene
  - Settings screen (audio, controls)
  - HUD during grooming (timer, tool bar, score preview)
  - Competition select screen (tier → competition → enter)
  - Scene transition system (fade/slide)
  - Loading screen with tips

---

## Wave 3 — Integration (starts after Wave 2 tracks converge)

### WS-8: Integration & Polish
- **State:** ⚪ WAITING (blocked on WS-2 through WS-7)
- **Owner:** builder-integration
- **Dependencies:** WS-2, WS-3, WS-4, WS-5, WS-6, WS-7
- **Deliverables:**
  - Wire tool system to dog model zones (WS-3 ↔ WS-2)
  - Wire scoring to breed standards (WS-4 ↔ WS-6)
  - Wire progression to breed/tool unlocks (WS-5 ↔ WS-6, WS-3)
  - End-to-end flow: menu → select competition → groom dog → judged → rewards → upgrade → repeat
  - Bug fixing and polish pass

---

## Milestones

| # | Milestone | What "done" looks like | Target wave |
|---|-----------|----------------------|-------------|
| M1 | Core interaction POC | Single dog on screen, rotatable, select clipper, tap zone to groom | End of WS-1 + early WS-2/WS-3 |
| M2 | Grooming loop | Full grooming session: receive dog, see guide, use multiple tools, get scored | End of Wave 2 |
| M3 | Competition loop | Enter competition, groom under time pressure, judged, earn rewards | Wave 3 |
| M4 | Progression loop | Spend rewards, upgrade tools, unlock breeds, advance tiers | Wave 3 |
| M5 | Content & polish | 4+ breeds with real data, breed-pedia, infotainment, UI polish | Wave 3 |
