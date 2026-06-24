## GameManager — Top-level state machine for game flow.
## Autoloaded singleton. Manages which major game state is active
## and coordinates transitions between them via signals.
extends Node

enum GameState {
	MAIN_MENU,
	SALON,
	GROOMING,
	COMPETITION,
	BREED_PEDIA,
	SHOP,
	LOADING,
}

## Emitted when the game state changes. Passes old and new state.
signal state_changed(old_state: GameState, new_state: GameState)

## The currently active game state.
var current_state: GameState = GameState.MAIN_MENU

## Map of GameState to scene path for SceneManager integration.
var state_scene_map: Dictionary = {
	GameState.MAIN_MENU: "res://scenes/main_menu.tscn",
	GameState.SALON: "res://scenes/salon.tscn",
	GameState.GROOMING: "res://scenes/grooming_arena.tscn",
	GameState.COMPETITION: "res://scenes/competition.tscn",
	GameState.BREED_PEDIA: "res://scenes/breed_pedia.tscn",
	GameState.SHOP: "res://scenes/shop.tscn",
}

## Transition data passed to the target scene (e.g., which breed to groom).
var transition_context: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Request a state change. Returns true if the transition is valid.
func change_state(new_state: GameState, context: Dictionary = {}) -> bool:
	if new_state == current_state:
		push_warning("GameManager: Requested transition to current state %s — ignoring." % GameState.keys()[new_state])
		return false

	var old_state := current_state
	current_state = new_state
	transition_context = context

	state_changed.emit(old_state, new_state)

	# Ask SceneManager to load the corresponding scene
	var scene_path: String = state_scene_map.get(new_state, "")
	if scene_path != "":
		SceneManager.goto_scene(scene_path)
	else:
		push_error("GameManager: No scene mapped for state %s" % GameState.keys()[new_state])

	return true


## Helper to get the name of the current state as a string.
func get_state_name() -> String:
	return GameState.keys()[current_state]
