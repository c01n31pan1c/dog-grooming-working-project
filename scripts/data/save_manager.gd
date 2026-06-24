## SaveManager — JSON save/load to user:// with versioned schema.
## Autoloaded singleton.
extends Node

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

## Default save data structure — defines the schema.
var _default_data: Dictionary = {
	"save_version": SAVE_VERSION,
	"player_name": "",
	"currency": 0,
	"unlocked_breeds": [],
	"unlocked_tools": ["basic_clipper", "basic_brush", "basic_dryer"],
	"current_tier": 0,
	"competition_history": [],
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"haptics_enabled": true,
	},
}

## In-memory copy of the current save data.
var data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = _default_data.duplicate(true)


## Save current data to disk. Returns true on success.
func save_game() -> bool:
	data["save_version"] = SAVE_VERSION
	var json_string := JSON.stringify(data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Could not open %s for writing. Error: %s" % [SAVE_PATH, FileAccess.get_open_error()])
		EventBus.save_completed.emit(false)
		return false

	file.store_string(json_string)
	file.close()

	EventBus.save_completed.emit(true)
	return true


## Load save data from disk. Returns true on success.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("SaveManager: No save file found at %s — using defaults." % SAVE_PATH)
		data = _default_data.duplicate(true)
		EventBus.load_completed.emit(true)
		return true

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Could not open %s for reading." % SAVE_PATH)
		EventBus.load_completed.emit(false)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		EventBus.load_completed.emit(false)
		return false

	var loaded_data: Variant = json.data
	if not loaded_data is Dictionary:
		push_error("SaveManager: Save file root is not a Dictionary.")
		EventBus.load_completed.emit(false)
		return false

	data = _migrate(loaded_data as Dictionary)
	EventBus.load_completed.emit(true)
	return true


## Migrate save data from older versions to current schema.
func _migrate(loaded: Dictionary) -> Dictionary:
	var version: int = loaded.get("save_version", 0)

	if version < SAVE_VERSION:
		# Future migrations go here. For now, merge with defaults.
		var merged := _default_data.duplicate(true)
		for key in loaded:
			merged[key] = loaded[key]
		merged["save_version"] = SAVE_VERSION
		return merged

	return loaded


## Reset save data to defaults (new game).
func reset_save() -> void:
	data = _default_data.duplicate(true)


## Convenience: check if a breed is unlocked.
func is_breed_unlocked(breed_id: String) -> bool:
	return breed_id in data.get("unlocked_breeds", [])


## Convenience: check if a tool is unlocked.
func is_tool_unlocked(tool_id: String) -> bool:
	return tool_id in data.get("unlocked_tools", [])


## Convenience: modify currency safely.
func modify_currency(delta: int) -> void:
	var old_amount: int = data.get("currency", 0)
	var new_amount: int = maxi(0, old_amount + delta)
	data["currency"] = new_amount
	EventBus.currency_changed.emit(new_amount, new_amount - old_amount)
