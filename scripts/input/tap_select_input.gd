## TapSelectInput — Tap-to-select-tool, tap-zone-to-apply input mode.
## MVP input strategy per ADR-008. Player selects a tool from the toolbar,
## then taps on dog grooming zones to apply it.
## Performs 3D raycasting to detect which grooming zone (Area3D) was tapped.
class_name TapSelectInput
extends GroomingInput

## The camera used for raycasting into the 3D scene.
var _camera: Camera3D = null

## Physics ray length for zone detection.
const RAY_LENGTH: float = 1000.0

## Collision mask for grooming zones (layer 1 = bit 0, matching Area3D defaults).
const ZONE_COLLISION_MASK: int = 1


func set_camera(camera: Camera3D) -> void:
	_camera = camera


func _unhandled_input(event: InputEvent) -> void:
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
		_try_apply_at(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_apply_at(event.position)


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


## Cast a ray from the camera through the screen position and detect
## if it hits a grooming zone Area3D. Returns the zone_id or empty string.
func _raycast_for_zone(screen_position: Vector2) -> String:
	if _camera == null or not is_instance_valid(_camera):
		return ""

	var space_state := _camera.get_world_3d().direct_space_state
	if space_state == null:
		return ""

	var from := _camera.project_ray_origin(screen_position)
	var to := from + _camera.project_ray_normal(screen_position) * RAY_LENGTH

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = ZONE_COLLISION_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return ""

	var collider := result["collider"]
	if collider is Area3D:
		# Grooming zone Area3Ds should have a "zone_id" metadata or be named
		# with the zone_id. Check metadata first, fall back to node name.
		if collider.has_meta("zone_id"):
			return collider.get_meta("zone_id") as String
		else:
			return collider.name

	return ""
