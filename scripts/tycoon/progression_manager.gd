## ProgressionManager — Tracks tier advancement through the kennel club circuit.
## Tiers: LOCAL (0), REGIONAL (1), NATIONAL (2).
## Persists via SaveManager, emits EventBus.tier_advanced on promotion.
class_name ProgressionManager
extends Node

enum Tier { LOCAL = 0, REGIONAL = 1, NATIONAL = 2 }

## Tier display names.
const TIER_NAMES: Dictionary = {
	Tier.LOCAL: "Local Amateur",
	Tier.REGIONAL: "Regional Circuit",
	Tier.NATIONAL: "National Elite",
}

## Advancement requirements: {wins_required, coins_required}
const ADVANCEMENT_REQS: Dictionary = {
	Tier.LOCAL: {"wins_required": 5, "coins_required": 500},
	Tier.REGIONAL: {"wins_required": 10, "coins_required": 2000},
	# Tier.NATIONAL has no further advancement
}


func _ready() -> void:
	_ensure_save_fields()


## Ensure progression fields exist in save data.
func _ensure_save_fields() -> void:
	if not SaveManager.data.has("total_wins"):
		SaveManager.data["total_wins"] = 0
	if not SaveManager.data.has("total_coins_earned"):
		SaveManager.data["total_coins_earned"] = 0
	if not SaveManager.data.has("competitions_completed"):
		SaveManager.data["competitions_completed"] = 0
	if not SaveManager.data.has("tier_wins"):
		# Wins per tier: {0: count, 1: count, 2: count}
		SaveManager.data["tier_wins"] = {0: 0, 1: 0, 2: 0}
	if not SaveManager.data.has("breeds_groomed"):
		SaveManager.data["breeds_groomed"] = []


## Get the current tier as an int.
func get_current_tier() -> int:
	return SaveManager.data.get("current_tier", 0)


## Get the display name of the current tier.
func get_tier_name(tier: int = -1) -> String:
	if tier < 0:
		tier = get_current_tier()
	return TIER_NAMES.get(tier, "Unknown")


## Record a completed competition. Call this after each competition ends.
func record_competition(won: bool, tier: int = -1) -> void:
	if tier < 0:
		tier = get_current_tier()

	SaveManager.data["competitions_completed"] = SaveManager.data.get("competitions_completed", 0) + 1

	if won:
		SaveManager.data["total_wins"] = SaveManager.data.get("total_wins", 0) + 1
		var tier_wins: Dictionary = SaveManager.data.get("tier_wins", {0: 0, 1: 0, 2: 0})
		tier_wins[tier] = tier_wins.get(tier, 0) + 1
		SaveManager.data["tier_wins"] = tier_wins

	SaveManager.save_game()
	_check_advancement()


## Record a breed as groomed (for stats tracking).
func record_breed_groomed(breed_id: String) -> void:
	var breeds: Array = SaveManager.data.get("breeds_groomed", [])
	if breed_id not in breeds:
		breeds.append(breed_id)
		SaveManager.data["breeds_groomed"] = breeds


## Check if the player qualifies for tier advancement and promote if so.
func _check_advancement() -> void:
	var current: int = get_current_tier()
	if current >= Tier.NATIONAL:
		return  # Already at max tier

	if not ADVANCEMENT_REQS.has(current):
		return

	var reqs: Dictionary = ADVANCEMENT_REQS[current]
	var tier_wins: Dictionary = SaveManager.data.get("tier_wins", {0: 0, 1: 0, 2: 0})
	var wins_at_tier: int = tier_wins.get(current, 0)
	var total_earned: int = SaveManager.data.get("total_coins_earned", 0)

	if wins_at_tier >= reqs["wins_required"] and total_earned >= reqs["coins_required"]:
		_advance_tier()


## Promote the player to the next tier.
func _advance_tier() -> void:
	var old_tier: int = get_current_tier()
	var new_tier: int = old_tier + 1
	SaveManager.data["current_tier"] = new_tier
	SaveManager.save_game()
	EventBus.tier_advanced.emit(new_tier)


## Get progress toward the next tier as a dictionary.
## Returns {wins_current, wins_required, coins_current, coins_required, progress_pct}.
func get_advancement_progress() -> Dictionary:
	var current: int = get_current_tier()
	if current >= Tier.NATIONAL:
		return {"wins_current": 0, "wins_required": 0, "coins_current": 0, "coins_required": 0, "progress_pct": 1.0, "at_max": true}

	var reqs: Dictionary = ADVANCEMENT_REQS[current]
	var tier_wins: Dictionary = SaveManager.data.get("tier_wins", {0: 0, 1: 0, 2: 0})
	var wins_at_tier: int = tier_wins.get(current, 0)
	var total_earned: int = SaveManager.data.get("total_coins_earned", 0)

	var win_pct: float = clampf(float(wins_at_tier) / float(reqs["wins_required"]), 0.0, 1.0)
	var coin_pct: float = clampf(float(total_earned) / float(reqs["coins_required"]), 0.0, 1.0)
	var progress: float = (win_pct + coin_pct) / 2.0

	return {
		"wins_current": wins_at_tier,
		"wins_required": reqs["wins_required"],
		"coins_current": total_earned,
		"coins_required": reqs["coins_required"],
		"progress_pct": progress,
		"at_max": false,
	}


## Get total wins across all tiers.
func get_total_wins() -> int:
	return SaveManager.data.get("total_wins", 0)


## Get total competitions completed.
func get_competitions_completed() -> int:
	return SaveManager.data.get("competitions_completed", 0)


## Get unique breeds groomed count.
func get_breeds_groomed_count() -> int:
	return SaveManager.data.get("breeds_groomed", []).size()
