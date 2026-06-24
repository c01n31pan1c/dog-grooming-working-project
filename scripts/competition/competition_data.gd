## CompetitionData — Resource defining a single competition event.
class_name CompetitionData
extends Resource

enum Tier {
	LOCAL,
	REGIONAL,
	NATIONAL,
}

@export var competition_name: String = ""
@export var tier: Tier = Tier.LOCAL

## The judges assigned to this competition (Array of JudgeData resources).
@export var judges: Array[JudgeData] = []

## The breed that must be groomed in this competition.
@export var breed: BreedData = null

## Time limit in seconds for the grooming phase.
@export var time_limit_seconds: float = 120.0

## Entry fee in coins to participate.
@export var entry_fee: int = 0

## Maps placement (int, 1-based) to coin reward. E.g., {1: 100, 2: 60, 3: 30}
@export var reward_table: Dictionary = {1: 100, 2: 60, 3: 30}


## Helper to get the tier name as a display string.
func get_tier_name() -> String:
	match tier:
		Tier.LOCAL:
			return "Local"
		Tier.REGIONAL:
			return "Regional"
		Tier.NATIONAL:
			return "National"
		_:
			return "Unknown"


## Get reward for a given placement. Returns 0 if placement has no reward.
func get_reward(placement: int) -> int:
	return reward_table.get(placement, 0)
