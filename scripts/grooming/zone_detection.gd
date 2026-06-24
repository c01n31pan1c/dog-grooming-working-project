## ZoneDetection — Resolves screen-space input to grooming zone IDs.
## Stub for WS-2/WS-3 — will use raycasting against zone collision shapes.
class_name ZoneDetection
extends Node

## Given a screen position, returns the zone_id under the pointer, or "" if none.
func get_zone_at_position(_screen_pos: Vector2) -> String:
	# WS-2 implements raycasting against dog model zone colliders
	return ""
