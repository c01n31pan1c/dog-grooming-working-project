## EventBus — Central signal bus for cross-system communication.
## Autoloaded singleton. All game-wide events route through here
## to keep systems decoupled.
extends Node

# Grooming signals
signal grooming_started(breed_data: Resource)
signal grooming_completed(breed_data: Resource, results: Dictionary)
signal tool_selected(tool_data: Resource)
signal zone_groomed(zone_id: String, tool_data: Resource)

# Competition signals
signal competition_started(competition_data: Dictionary)
signal competition_ended(results: Dictionary)
signal score_calculated(score_breakdown: Dictionary)

# Progression signals
signal currency_changed(new_amount: int, delta: int)
signal breed_unlocked(breed_data: Resource)
signal tier_advanced(new_tier: int)

# UI signals
signal scene_transition_requested(scene_path: String)
signal loading_started()
signal loading_finished()

# Save signals
signal save_completed(success: bool)
signal load_completed(success: bool)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
