## ZoneDetection — Resolves screen-space input to grooming zone IDs.
## Uses raycasting from camera through zone Area3D collision shapes.
## Supports SubViewport setups: the camera's world_3d is used for raycasting
## and screen coordinates are mapped to SubViewport coordinates when needed.
class_name ZoneDetection
extends Node

## Reference to the camera used for raycasting
@export var camera: Camera3D

## Reference to SubViewportContainer for coordinate mapping (set by arena)
var sub_viewport_container: SubViewportContainer = null
## Reference to SubViewport for coordinate mapping (set by arena)
var sub_viewport: SubViewport = null

## The physics space to raycast in (from the camera's world, not the main viewport)
var _space_state: PhysicsDirectSpaceState3D

## Currently hovered zone_id (or "" if none)
var current_zone: String = ""

## Signal emitted when hover changes
signal zone_hover_changed(zone_id: String)


func _ready() -> void:
	# Defer space state access until physics is ready
	await get_tree().physics_frame
	_update_space_state()


## Refresh the physics space state from the camera's world.
func _update_space_state() -> void:
	if camera:
		var world := camera.get_world_3d()
		if world:
			_space_state = world.direct_space_state


func _physics_process(_delta: float) -> void:
	if not camera:
		return

	# Lazily acquire space state if it wasn't ready before
	if _space_state == null:
		_update_space_state()
		if _space_state == null:
			return

	var mouse_pos := get_viewport().get_mouse_position()
	var new_zone := get_zone_at_position(mouse_pos)

	if new_zone != current_zone:
		current_zone = new_zone
		zone_hover_changed.emit(current_zone)


## Map screen coordinates to SubViewport coordinates if using a SubViewport.
func _map_to_sub_viewport(screen_pos: Vector2) -> Vector2:
	if sub_viewport_container == null or sub_viewport == null:
		return screen_pos

	# Use the container's actual global rect so this works at any screen size.
	var container_rect := sub_viewport_container.get_global_rect()
	var viewport_size := Vector2(sub_viewport.size)

	# Convert screen position to a 0-1 normalized position within the container.
	var local_pos := screen_pos - container_rect.position
	var norm_x := local_pos.x / maxf(container_rect.size.x, 1.0)
	var norm_y := local_pos.y / maxf(container_rect.size.y, 1.0)

	# Scale the normalized position to SubViewport pixel coordinates.
	return Vector2(norm_x * viewport_size.x, norm_y * viewport_size.y)


## Given a screen position, returns the zone_id under the pointer, or "" if none.
func get_zone_at_position(screen_pos: Vector2) -> String:
	if not camera or not _space_state:
		return ""

	# Map to SubViewport coords for correct raycasting
	var viewport_pos := _map_to_sub_viewport(screen_pos)

	var from := camera.project_ray_origin(viewport_pos)
	var to := from + camera.project_ray_normal(viewport_pos) * 100.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1  # Layer 1 for grooming zones

	var result := _space_state.intersect_ray(query)

	if result.is_empty():
		return ""

	var collider: Object = result.get("collider")
	if collider and collider.has_meta("zone_id"):
		return collider.get_meta("zone_id") as String

	return ""


## Apply grooming to the zone under the pointer. Returns the zone_id groomed, or "".
func try_groom_at_position(screen_pos: Vector2, tool_data: Resource = null) -> String:
	var zone_id := get_zone_at_position(screen_pos)
	if zone_id != "":
		EventBus.zone_groomed.emit(zone_id, tool_data)
	return zone_id
