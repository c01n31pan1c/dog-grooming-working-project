## ContinuousGroomInput — Paint-mode grooming input.
## Single finger drags across the dog to groom continuously.
## Two fingers are reserved for OrbitCamera (orbit + pinch zoom).
## Interaction mode is determined per-tool via ToolData.interaction_mode:
##   CONTINUOUS — hold/drag emits grooming_tick every frame
##   SWIPE — directional swipe emits tool_applied on successful gesture
##   TAP — single tap emits tool_applied on finger release
class_name ContinuousGroomInput
extends GroomingInput

var _zone_detection: ZoneDetection = null

var _touch_points: Dictionary = {}
var _touch_position: Vector2 = Vector2.ZERO
var _is_touching: bool = false
var _touch_index: int = -1
var _was_multi_touch: bool = false

## Tap / swipe shared press tracking
var _press_position: Vector2 = Vector2.ZERO
var _press_time: float = 0.0
const TAP_DISTANCE_THRESHOLD: float = 30.0
const TAP_TIME_THRESHOLD: float = 0.5

## Swipe detection
const SWIPE_MIN_DISTANCE := 80.0  # pixels
const SWIPE_MAX_TIME := 0.5  # seconds
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_start_time: float = 0.0


func setup(zone_detection: ZoneDetection) -> void:
	_zone_detection = zone_detection


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var pos: Vector2
		if event is InputEventScreenTouch:
			pos = (event as InputEventScreenTouch).position
		else:
			pos = (event as InputEventScreenDrag).position
		var screen_height := get_viewport().get_visible_rect().size.y
		if pos.y > screen_height - 130.0:
			return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 1 and not _was_multi_touch:
			_is_touching = true
			_touch_position = event.position
			_touch_index = event.index
			_press_position = event.position
			_press_time = Time.get_ticks_msec() / 1000.0
			_swipe_start_pos = event.position
			_swipe_start_time = _press_time
			get_viewport().set_input_as_handled()
		else:
			# 2+ fingers detected — stop grooming, mark multi-touch
			_is_touching = false
			_was_multi_touch = true
	else:
		var was_single := _touch_points.size() == 1 and _is_touching
		_touch_points.erase(event.index)
		if _touch_points.size() == 1:
			if _was_multi_touch:
				_is_touching = false  # DON'T resume grooming after orbit
			else:
				var remaining_index: int = _touch_points.keys()[0]
				_is_touching = true
				_touch_index = remaining_index
				_touch_position = _touch_points[remaining_index]
				_press_position = _touch_position
				_press_time = Time.get_ticks_msec() / 1000.0
				_swipe_start_pos = _touch_position
				_swipe_start_time = _press_time
		elif _touch_points.size() == 0:
			_is_touching = false
			_touch_index = -1
			_was_multi_touch = false
			if was_single:
				_on_single_touch_release(event.position)


func _handle_drag(event: InputEventScreenDrag) -> void:
	_touch_points[event.index] = event.position
	if _touch_points.size() == 1 and event.index == _touch_index and not _was_multi_touch:
		_touch_position = event.position
		get_viewport().set_input_as_handled()


func _on_single_touch_release(release_position: Vector2) -> void:
	if _active_tool == null:
		return
	var td := _active_tool as ToolData
	if td == null:
		return

	match td.interaction_mode:
		ToolData.InteractionMode.TAP:
			_try_tap_apply(release_position)
		ToolData.InteractionMode.SWIPE:
			_try_swipe_apply(release_position)
		ToolData.InteractionMode.CONTINUOUS:
			pass  # Continuous tools handle input in _process(), nothing on release.


func _try_tap_apply(release_position: Vector2) -> void:
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _press_time
	var dist := release_position.distance_to(_press_position)
	if elapsed > TAP_TIME_THRESHOLD or dist > TAP_DISTANCE_THRESHOLD:
		return

	if _zone_detection == null:
		return
	var zone_id := _zone_detection.get_zone_at_position(release_position)
	if zone_id.is_empty():
		return

	tool_applied.emit(zone_id, _active_tool)


func _try_swipe_apply(release_position: Vector2) -> void:
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _swipe_start_time
	var dist := release_position.distance_to(_swipe_start_pos)
	if dist < SWIPE_MIN_DISTANCE or elapsed > SWIPE_MAX_TIME:
		return

	if _zone_detection == null:
		return
	var midpoint := (_swipe_start_pos + release_position) * 0.5
	var zone_id := _zone_detection.get_zone_at_position(midpoint)
	if zone_id.is_empty():
		return

	tool_applied.emit(zone_id, _active_tool)


func _process(delta: float) -> void:
	if not _is_touching or _active_tool == null or _zone_detection == null:
		return

	var td := _active_tool as ToolData
	if td == null or td.interaction_mode != ToolData.InteractionMode.CONTINUOUS:
		return

	var zone_id := _zone_detection.get_zone_at_position(_touch_position)
	if zone_id.is_empty():
		return

	grooming_tick.emit(zone_id, _active_tool, delta)
	pointer_moved.emit(_touch_position)
