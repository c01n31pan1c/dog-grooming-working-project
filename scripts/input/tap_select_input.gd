## TapSelectInput — Tap-to-select-tool, tap-zone-to-apply input mode.
## MVP input strategy per ADR-008. Player selects a tool from the toolbar,
## then taps on dog grooming zones to apply it.
## Performs 3D raycasting to detect which grooming zone (Area3D) was tapped.
## Disambiguates taps from drags: quick taps groom, sustained drags orbit.
class_name TapSelectInput
extends GroomingInput

## The camera used for raycasting into the 3D scene.
var _camera: Camera3D = null

## Reference to the SubViewportContainer for coordinate mapping.
var _sub_viewport_container: SubViewportContainer = null
## Reference to the SubViewport for coordinate mapping.
var _sub_viewport: SubViewport = null

## Physics ray length for zone detection.
const RAY_LENGTH: float = 1000.0

## Collision mask for grooming zones (layer 1 = bit 0, matching Area3D defaults).
const ZONE_COLLISION_MASK: int = 1

## Tap vs drag disambiguation: max pixels moved before a press becomes a drag.
const TAP_DISTANCE_THRESHOLD: float = 30.0
## Max time (seconds) for a press to count as a tap.
const TAP_TIME_THRESHOLD: float = 0.5

## Tracking for tap detection
var _press_position: Vector2 = Vector2.ZERO
var _press_time: float = 0.0
var _is_pressed: bool = false


func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Set the SubViewportContainer so screen coords can be mapped to SubViewport coords.
func set_sub_viewport_container(container: SubViewportContainer, viewport: SubViewport) -> void:
	_sub_viewport_container = container
	_sub_viewport = viewport


func _input(event: InputEvent) -> void:
	# Skip events over GUI elements (toolbar at bottom of screen).
	# Without this guard, taps on the toolbar would also trigger grooming raycasts.
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var pos: Vector2
		if event is InputEventMouseButton:
			pos = (event as InputEventMouseButton).position
		else:
			pos = (event as InputEventScreenTouch).position
		var screen_height := get_viewport().get_visible_rect().size.y
		if pos.y > screen_height - 130.0:  # Toolbar area
			return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventScreenDrag:
		pointer_moved.emit((event as InputEventScreenDrag).position)
	elif event is InputEventMouseMotion:
		pointer_moved.emit((event as InputEventMouseMotion).position)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_is_pressed = true
		_press_position = event.position
		_press_time = Time.get_ticks_msec() / 1000.0
	else:
		# Released -- check if it was a tap (short duration, small movement)
		if _is_pressed:
			var elapsed := (Time.get_ticks_msec() / 1000.0) - _press_time
			var dist := event.position.distance_to(_press_position)
			if elapsed <= TAP_TIME_THRESHOLD and dist <= TAP_DISTANCE_THRESHOLD:
				get_viewport().set_input_as_handled()
				_try_apply_at(event.position)
		_is_pressed = false


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_press_position = event.position
			_press_time = Time.get_ticks_msec() / 1000.0
		else:
			# Released -- check if it was a tap
			if _is_pressed:
				var elapsed := (Time.get_ticks_msec() / 1000.0) - _press_time
				var dist := event.position.distance_to(_press_position)
				if elapsed <= TAP_TIME_THRESHOLD and dist <= TAP_DISTANCE_THRESHOLD:
					get_viewport().set_input_as_handled()
					_try_apply_at(event.position)
			_is_pressed = false


## Attempt to apply the active tool at the given screen position.
## Raycasts into the 3D scene to find a grooming zone Area3D.
func _try_apply_at(screen_position: Vector2) -> void:
	if _active_tool == null:
		return

	pointer_moved.emit(screen_position)

	var zone_id := _raycast_for_zone(screen_position)
	if zone_id.is_empty():
		return  # No zone hit -- do nothing.

	tool_applied.emit(zone_id, _active_tool)


## Map screen coordinates to SubViewport coordinates if using a SubViewport.
func _map_to_sub_viewport(screen_pos: Vector2) -> Vector2:
	if _sub_viewport_container == null or _sub_viewport == null:
		return screen_pos

	# Use the container's actual global rect so this works at any screen size.
	var container_rect := _sub_viewport_container.get_global_rect()
	var viewport_size := Vector2(_sub_viewport.size)

	# Convert screen position to a 0-1 normalized position within the container.
	var local_pos := screen_pos - container_rect.position
	var norm_x := local_pos.x / maxf(container_rect.size.x, 1.0)
	var norm_y := local_pos.y / maxf(container_rect.size.y, 1.0)

	# Scale the normalized position to SubViewport pixel coordinates.
	return Vector2(norm_x * viewport_size.x, norm_y * viewport_size.y)


## Cast a ray from the camera through the screen position and detect
## if it hits a grooming zone Area3D. Returns the zone_id or empty string.
func _raycast_for_zone(screen_position: Vector2) -> String:
	if _camera == null or not is_instance_valid(_camera):
		return ""

	var space_state := _camera.get_world_3d().direct_space_state
	if space_state == null:
		return ""

	# Map screen coords to SubViewport coords for correct raycasting
	var viewport_pos := _map_to_sub_viewport(screen_position)

	var from := _camera.project_ray_origin(viewport_pos)
	var to := from + _camera.project_ray_normal(viewport_pos) * RAY_LENGTH

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = ZONE_COLLISION_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return ""

	var collider: Object = result["collider"]
	if collider is Area3D:
		# Grooming zone Area3Ds should have a "zone_id" metadata or be named
		# with the zone_id. Check metadata first, fall back to node name.
		if collider.has_meta("zone_id"):
			return collider.get_meta("zone_id") as String
		else:
			return collider.name

	return ""
