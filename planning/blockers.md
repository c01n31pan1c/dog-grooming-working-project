# Blockers

> Tracks all blockers (technical, content, design) with full lifecycle.
> Format per OPERATING_MANUAL.md § Blocker Protocol.

---

## BLK-001: SceneTransition autoload registration

**Filed:** 2026-06-24
**Workstream:** WS-7 (UI & Menus)
**Status:** Open
**Owner needed:** WS-1 owner or orchestrator
**Description:** `scripts/ui/scene_transition.gd` is designed as an autoload singleton but WS-7 cannot modify `project.godot`. Needs the following line added to `[autoload]` section:
```
SceneTransition="*res://scripts/ui/scene_transition.gd"
```
**Impact:** Scene transitions will not work until this is registered. All other UI works independently.

## BLK-002: SaveManager missing master_volume default

**Filed:** 2026-06-24
**Workstream:** WS-7 (UI & Menus)
**Status:** Open (non-blocking, gracefully handled)
**Owner needed:** WS-1 owner
**Description:** `SaveManager._default_data.settings` has `music_volume` and `sfx_volume` but no `master_volume`. Settings screen handles this with `.get("master_volume", 1.0)` fallback, but SaveManager should include it for schema completeness.
