## GroomingController — Central coordinator for grooming gameplay.
## Connects input strategy to tool system and zone detection.
## Consumes GroomingInput interface only (never concrete input classes).
## Validates tool-zone combinations, calculates quality, tracks progress.
class_name GroomingController
extends Node

## Reference to the active input handler (strategy pattern, ADR-008).
var _input_handler: GroomingInput = null

## Reference to the ToolSystem for tool queries.
var _tool_system: ToolSystem = null

## The breed currently being groomed (set when grooming session starts).
var _current_breed: BreedData = null

## Per-zone grooming state: zone_id -> {groomed: bool, groomed_amount: float, quality: float, tool_used: ToolData, wet: bool, brushed: bool, cologned: bool}
var _zone_progress: Dictionary = {}

## Tracks last threshold crossed per zone for zone_groomed emission.
var _last_threshold: Dictionary = {}

## Rate at which continuous grooming fills a zone (1.0 / rate = seconds to fill).
const GROOM_RATE_PER_SECOND: float = 0.3

## Camera used for raycasting (assigned by scene setup).
var _camera: Camera3D = null

## Collision mask for grooming zone Area3Ds (layer 1 = bit 0, matching Area3D defaults).
const ZONE_COLLISION_LAYER: int = 1

## ---- Tool-zone compatibility maps ----

## Zones where nail trimmer is valid.
const PAW_ZONES: Array[String] = ["paw_front_left", "paw_front_right", "paw_rear_left", "paw_rear_right"]

## Zones considered detail zones for scissors.
const DETAIL_ZONES: Array[String] = ["crown", "muzzle", "ears_left", "ears_right"]


# -- Setup ------------------------------------------------------------------

func setup(tool_system: ToolSystem, camera: Camera3D = null) -> void:
	_tool_system = tool_system
	_camera = camera


func set_input_handler(handler: GroomingInput) -> void:
	if _input_handler != null:
		if _input_handler.tool_applied.is_connected(_on_tool_applied):
			_input_handler.tool_applied.disconnect(_on_tool_applied)
		if _input_handler.grooming_tick.is_connected(_on_grooming_tick):
			_input_handler.grooming_tick.disconnect(_on_grooming_tick)
		if _input_handler.pointer_moved.is_connected(_on_pointer_moved):
			_input_handler.pointer_moved.disconnect(_on_pointer_moved)

	_input_handler = handler
	_input_handler.tool_applied.connect(_on_tool_applied)
	_input_handler.grooming_tick.connect(_on_grooming_tick)
	_input_handler.pointer_moved.connect(_on_pointer_moved)


func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Start a grooming session for a given breed.
func start_grooming(breed_data: BreedData) -> void:
	_current_breed = breed_data
	_zone_progress.clear()

	# Initialize progress tracking for every zone defined on the breed.
	_last_threshold.clear()
	for zone_id in breed_data.grooming_zones:
		_zone_progress[zone_id] = {
			"groomed": false,
			"groomed_amount": 0.0,
			"quality": 0.0,
			"tool_used": null,
			"wet": false,
			"brushed": false,
			"cologned": false,
		}
		_last_threshold[zone_id] = 0.0

	EventBus.grooming_started.emit(breed_data)


## End grooming and emit results.
func finish_grooming() -> void:
	if _current_breed == null:
		return

	var results := {
		"zone_results": get_zone_results(),
		"completion": get_grooming_progress(),
	}
	EventBus.grooming_completed.emit(_current_breed, results)


# -- Input callbacks --------------------------------------------------------

func _on_tool_applied(zone_id: String, tool_data: Resource) -> void:
	if _current_breed == null:
		return

	var td: ToolData = tool_data as ToolData
	if td == null:
		return

	# If zone_id is still "unresolved", skip (raycasting didn't hit anything).
	if zone_id == "unresolved" or zone_id.is_empty():
		return

	# Only process zones that exist on this breed.
	if not _zone_progress.has(zone_id):
		return

	var quality := _calculate_quality(zone_id, td)
	_apply_tool_effect(zone_id, td, quality)


func _on_grooming_tick(zone_id: String, tool_data: Resource, delta: float) -> void:
	if _current_breed == null:
		return

	var td: ToolData = tool_data as ToolData
	if td == null:
		return

	if zone_id == "unresolved" or zone_id.is_empty():
		return

	if not _zone_progress.has(zone_id):
		return

	if not _is_tool_valid_for_zone(zone_id, td):
		return

	var quality := _calculate_quality(zone_id, td)
	if quality <= 0.0:
		return

	var zone_state: Dictionary = _zone_progress[zone_id]
	var amount := GROOM_RATE_PER_SECOND * delta * quality
	zone_state["groomed_amount"] = clampf(zone_state["groomed_amount"] + amount, 0.0, 1.0)

	_apply_prep_effect_if_needed(zone_id, td, zone_state)

	if zone_state["groomed_amount"] >= 1.0 and not zone_state["groomed"]:
		zone_state["groomed"] = true
		zone_state["tool_used"] = td
		if quality > zone_state["quality"]:
			zone_state["quality"] = quality

	EventBus.zone_grooming_tick.emit(zone_id, zone_state["groomed_amount"])

	if _check_threshold(zone_id, zone_state["groomed_amount"]):
		EventBus.zone_groomed.emit(zone_id, td)


func _apply_prep_effect_if_needed(zone_id: String, tool_data: ToolData, zone_state: Dictionary) -> void:
	match tool_data.tool_type:
		ToolData.ToolType.SHAMPOO:
			zone_state["wet"] = true
		ToolData.ToolType.DRYER:
			if zone_state["wet"]:
				zone_state["wet"] = false
		ToolData.ToolType.BRUSH:
			zone_state["brushed"] = true
		ToolData.ToolType.COLOGNE:
			zone_state["cologned"] = true


func _check_threshold(zone_id: String, amount: float) -> bool:
	var prev: float = _last_threshold.get(zone_id, 0.0)
	var thresholds: Array[float] = [0.25, 0.5, 0.75, 1.0]
	for t in thresholds:
		if prev < t and amount >= t:
			_last_threshold[zone_id] = t
			return true
	return false


func _on_pointer_moved(_position: Vector2) -> void:
	pass


# -- Tool effect logic ------------------------------------------------------

## Apply a tool's effect to a zone and update progress.
func _apply_tool_effect(zone_id: String, tool_data: ToolData, quality: float) -> void:
	var zone_state: Dictionary = _zone_progress[zone_id]

	match tool_data.tool_type:
		ToolData.ToolType.SHAMPOO:
			zone_state["wet"] = true
			# Shampoo is a prep step; don't mark groomed yet.

		ToolData.ToolType.DRYER:
			if zone_state["wet"]:
				zone_state["wet"] = false
				# Drying is a prep step; don't mark groomed.
			else:
				quality = 0.0  # Drying a dry zone does nothing useful.

		ToolData.ToolType.BRUSH:
			zone_state["brushed"] = true
			# Brushing is a prep step.

		ToolData.ToolType.COLOGNE:
			zone_state["cologned"] = true
			# Cologne is a finishing bonus; doesn't mark groomed.

		ToolData.ToolType.MEDICINE:
			# Medicine is a bonus action; doesn't mark groomed.
			zone_state["medicine_applied"] = true

		ToolData.ToolType.SCISSORS:
			# Scissors use incremental grooming: +0.25 per swipe (4 swipes to complete).
			zone_state["groomed_amount"] = minf(1.0, zone_state.get("groomed_amount", 0.0) + 0.25 * quality)
			zone_state["tool_used"] = tool_data
			if quality > zone_state["quality"]:
				zone_state["quality"] = quality
			if zone_state["groomed_amount"] >= 1.0:
				zone_state["groomed"] = true

		ToolData.ToolType.CLIPPER, ToolData.ToolType.NAIL_TRIMMER:
			# These are primary grooming tools that mark a zone done.
			zone_state["groomed"] = true
			zone_state["groomed_amount"] = 1.0
			zone_state["tool_used"] = tool_data
			# Keep best quality if groomed multiple times.
			if quality > zone_state["quality"]:
				zone_state["quality"] = quality

	EventBus.zone_groomed.emit(zone_id, tool_data)


## Calculate quality score (0.0 - 1.0) for applying a tool to a zone.
func _calculate_quality(zone_id: String, tool_data: ToolData) -> float:
	if _current_breed == null:
		return 0.0

	var zone_spec: Dictionary = _current_breed.grooming_zones.get(zone_id, {})
	var zone_state: Dictionary = _zone_progress.get(zone_id, {})
	var quality := 0.0

	# Check tool-zone validity first.
	if not _is_tool_valid_for_zone(zone_id, tool_data):
		return 0.0

	# For primary grooming tools, evaluate against breed standard.
	match tool_data.tool_type:
		ToolData.ToolType.CLIPPER:
			var required_tool: String = zone_spec.get("required_tool", "")
			var required_guard: float = zone_spec.get("guard_size", 0.0)

			if required_tool == "CLIPPER":
				# Right tool type -- check guard size.
				if absf(tool_data.guard_size - required_guard) < 0.02:
					quality = 1.0  # Perfect match.
				else:
					# Wrong guard -- partial credit scaled by how far off.
					var diff := absf(tool_data.guard_size - required_guard)
					quality = maxf(0.2, 1.0 - (diff / 0.5))
			else:
				quality = 0.3  # Wrong tool type entirely.

		ToolData.ToolType.SCISSORS:
			var required_tool: String = zone_spec.get("required_tool", "")
			if required_tool == "SCISSORS":
				quality = 1.0
			elif zone_id in DETAIL_ZONES:
				quality = 0.7  # Scissors acceptable on detail zones even if not required.
			else:
				quality = 0.3

		ToolData.ToolType.NAIL_TRIMMER:
			var required_tool: String = zone_spec.get("required_tool", "")
			if required_tool == "NAIL_TRIMMER":
				quality = 1.0
			else:
				quality = 0.0  # Nail trimmer only works on paw zones.

		ToolData.ToolType.BRUSH:
			quality = 0.8  # Brushing is always decent prep.

		ToolData.ToolType.SHAMPOO:
			quality = 0.8

		ToolData.ToolType.DRYER:
			quality = 0.8 if zone_state.get("wet", false) else 0.0

		ToolData.ToolType.COLOGNE:
			quality = 1.0  # Bonus -- always good.

		ToolData.ToolType.MEDICINE:
			quality = 1.0  # Bonus -- always good if breed needs it.

	# Bonus for proper prep sequence.
	if tool_data.tool_type in [ToolData.ToolType.CLIPPER, ToolData.ToolType.SCISSORS]:
		if zone_state.get("brushed", false):
			quality = minf(1.0, quality + 0.1)  # Brushing before cutting = bonus.

	return quality


## Check if a tool type is valid for a given zone.
func _is_tool_valid_for_zone(zone_id: String, tool_data: ToolData) -> bool:
	match tool_data.tool_type:
		ToolData.ToolType.NAIL_TRIMMER:
			# Only valid on paw zones.
			return zone_id in PAW_ZONES

		ToolData.ToolType.DRYER:
			# Only useful on wet zones.
			var zone_state: Dictionary = _zone_progress.get(zone_id, {})
			return zone_state.get("wet", false)

		_:
			# All other tools work on any zone (quality varies).
			return true


# -- Progress queries -------------------------------------------------------

## Overall completion percentage (0.0 - 1.0).
func get_grooming_progress() -> float:
	if _zone_progress.is_empty():
		return 0.0

	var total := 0.0
	for zone_id in _zone_progress:
		total += _zone_progress[zone_id]["groomed_amount"]

	return total / float(_zone_progress.size())


## Detailed per-zone results for scoring.
func get_zone_results() -> Dictionary:
	return _zone_progress.duplicate(true)


## Get the current breed being groomed.
func get_current_breed() -> BreedData:
	return _current_breed
