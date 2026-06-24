## BreedData — Custom Resource defining a dog breed's grooming profile.
## Create .tres instances in resources/breeds/ for each breed.
class_name BreedData
extends Resource

@export var breed_name: String = ""
@export var breed_group: String = ""
@export_multiline var description: String = ""
@export var grooming_facts: Array[String] = []

## Maps zone_id (String) -> Dictionary with keys: required_tool (String), guard_size (float)
@export var grooming_zones: Dictionary = {}

## Difficulty tier: 0 = beginner, 1 = intermediate, 2 = advanced
@export_range(0, 2) var difficulty_tier: int = 0

## What the player needs to unlock this breed (e.g., "tier_1", "competition_wins_5")
@export var unlock_requirement: String = ""
