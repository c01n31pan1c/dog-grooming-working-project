## ZoneDetection — Resolves screen-space input to grooming zone IDs.
## Uses raycasting from camera through zone Area3D collision shapes.
class_name ZoneDetection
extends Node

## Reference to the camera used for raycasting
@export var camera: Camera3D

## The physics space to raycast in (auto-detected from scene tree)
var _space_state: PhysicsDirectSpaceState3D

## Currently hovered zone_id (or "" if none)
var current_zone: String = ""

## Signal emitted when hover changes
signal zone_hover_changed(zone_id: String)


func _ready() -> void:
	# Defer space state access until physics is ready
	await get_tree().physics_frame
	var viewport := get_viewport()
	if viewport and viewport.world_3d:
		_space_state = viewport.world_3d.direct_space_state


func _physics_process(_delta: float) -> void:
	if not camera or not _space_state:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var new_zone := get_zone_at_position(mouse_pos)

	if new_zone != current_zone:
		current_zone = new_zone
		zone_hover_changed.emit(current_zone)


## Given a screen position, returns the zone_id under the pointer, or "" if none.
func get_zone_at_position(screen_pos: Vector2) -> String:
	if not camera or not _space_state:
		return ""

	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1  # Layer 1 for grooming zones

	var result := _space_state.intersect_ray(query)

	if result.is_empty():
		return ""

	var collider := result.get("collider")
	if collider and collider.has_meta("zone_id"):
		return collider.get_meta("zone_id") as String

	return ""


## Apply grooming to the zone under the pointer. Returns the zone_id groomed, or "".
func try_groom_at_position(screen_pos: Vector2, tool_data: Resource = null) -> String:
	var zone_id := get_zone_at_position(screen_pos)
	if zone_id != "":
		EventBus.zone_groomed.emit(zone_id, tool_data)
	return zone_id
