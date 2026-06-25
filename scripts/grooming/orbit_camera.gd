## OrbitCamera — Camera that orbits around the dog model via touch/mouse drag.
## Supports horizontal orbit (360deg), vertical orbit (limited), and zoom.
## Only begins orbiting after the pointer has moved past a drag threshold,
## so quick taps pass through to the grooming input system.
class_name OrbitCamera
extends Camera3D

## The target point to orbit around
@export var target: Vector3 = Vector3.ZERO
## Current orbit distance from target
@export var distance: float = 3.0
## Minimum zoom distance
@export var min_distance: float = 1.5
## Maximum zoom distance
@export var max_distance: float = 6.0
## Horizontal rotation speed (degrees per pixel)
@export var horizontal_sensitivity: float = 0.4
## Vertical rotation speed (degrees per pixel)
@export var vertical_sensitivity: float = 0.3
## Minimum vertical angle (degrees from horizontal)
@export var min_vertical_angle: float = 15.0
## Maximum vertical angle (degrees from horizontal)
@export var max_vertical_angle: float = 75.0
## Zoom speed for scroll wheel
@export var zoom_speed: float = 0.3
## Smoothing factor for camera movement (lower = smoother)
@export var smoothing: float = 10.0

## Current angles in degrees
var _horizontal_angle: float = 0.0
var _vertical_angle: float = 35.0
## Target angles for smoothing
var _target_horizontal: float = 0.0
var _target_vertical: float = 35.0
var _target_distance: float = 3.0

## Touch/drag tracking
var _is_dragging: bool = false
var _drag_started: bool = false
var _last_drag_pos: Vector2 = Vector2.ZERO
var _press_start_pos: Vector2 = Vector2.ZERO
## Touch tracking for two-finger orbit + pinch zoom
var _touch_points: Dictionary = {}
var _initial_pinch_distance: float = 0.0
var _initial_zoom_distance: float = 0.0
var _prev_midpoint: Vector2 = Vector2.ZERO

## Minimum pixels the pointer must move before we consider it a drag (not a tap).
const DRAG_THRESHOLD: float = 25.0


func _ready() -> void:
	_target_distance = distance
	_update_position_immediate()


func _input(event: InputEvent) -> void:
	# Mouse drag for orbit
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_started = false
				_last_drag_pos = mb.position
				_press_start_pos = mb.position
			else:
				_is_dragging = false
				_drag_started = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_distance = clampf(_target_distance - zoom_speed, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_distance = clampf(_target_distance + zoom_speed, min_distance, max_distance)

	if event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		# Only start actual drag rotation after passing threshold
		if not _drag_started:
			if mm.position.distance_to(_press_start_pos) >= DRAG_THRESHOLD:
				_drag_started = true
				_last_drag_pos = mm.position
				get_viewport().set_input_as_handled()
		if _drag_started:
			var delta := mm.position - _last_drag_pos
			_last_drag_pos = mm.position
			_target_horizontal -= delta.x * horizontal_sensitivity
			_target_vertical -= delta.y * vertical_sensitivity
			_target_vertical = clampf(_target_vertical, min_vertical_angle, max_vertical_angle)

	# Touch input for mobile — single finger is reserved for grooming,
	# two fingers orbit (midpoint delta) and pinch zoom.
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touch_points[st.index] = st.position
			if _touch_points.size() == 2:
				var points := _touch_points.values()
				_prev_midpoint = ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5
				_initial_pinch_distance = (points[0] as Vector2).distance_to(points[1] as Vector2)
				_initial_zoom_distance = _target_distance
		else:
			_touch_points.erase(st.index)

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touch_points[sd.index] = sd.position
		if _touch_points.size() == 2:
			var points := _touch_points.values()
			var midpoint := ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5
			var mid_delta := midpoint - _prev_midpoint
			_prev_midpoint = midpoint
			_target_horizontal -= mid_delta.x * horizontal_sensitivity
			_target_vertical -= mid_delta.y * vertical_sensitivity
			_target_vertical = clampf(_target_vertical, min_vertical_angle, max_vertical_angle)
			var current_pinch := (points[0] as Vector2).distance_to(points[1] as Vector2)
			if _initial_pinch_distance > 0.0:
				var zoom_ratio := _initial_pinch_distance / current_pinch
				_target_distance = clampf(_initial_zoom_distance * zoom_ratio, min_distance, max_distance)


func _process(delta: float) -> void:
	var t := clampf(delta * smoothing, 0.0, 1.0)
	_horizontal_angle = lerp(_horizontal_angle, _target_horizontal, t)
	_vertical_angle = lerp(_vertical_angle, _target_vertical, t)
	distance = lerp(distance, _target_distance, t)
	_update_position()


func _update_position() -> void:
	var h_rad := deg_to_rad(_horizontal_angle)
	var v_rad := deg_to_rad(_vertical_angle)

	var offset := Vector3(
		cos(v_rad) * sin(h_rad) * distance,
		sin(v_rad) * distance,
		cos(v_rad) * cos(h_rad) * distance
	)

	global_position = target + offset
	look_at(target, Vector3.UP)


func _update_position_immediate() -> void:
	_horizontal_angle = _target_horizontal
	_vertical_angle = _target_vertical
	_update_position()
