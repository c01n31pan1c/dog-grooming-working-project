## DogModel — Controls the procedural placeholder dog model.
## Manages grooming zones, fur shader instances, highlight/overlay state.
class_name DogModel
extends Node3D

## Maps zone_id -> Area3D node
var zones: Dictionary = {}
## Maps zone_id -> groomed amount (0.0 to 1.0)
var groomed_state: Dictionary = {}
## Maps zone_id -> Array of MeshInstance3D with shell fur materials
var zone_meshes: Dictionary = {}

## Whether the grooming guide overlay is visible
var guide_overlay_visible: bool = false

## Guard size color mapping for the guide overlay
const GUARD_COLORS: Dictionary = {
	0.0: Color(0.4, 0.7, 1.0, 0.7),     # Scissors/Brush/Hand-strip (no clipper) - Light Blue
	0.0625: Color(0.9, 0.2, 0.2, 0.7),  # #10 Blade (1/16") - Red (close shave)
	0.125: Color(0.9, 0.5, 0.1, 0.7),   # #7F Blade (1/8") - Orange
	0.25: Color(0.9, 0.9, 0.1, 0.7),    # #5 Blade (1/4") - Yellow
	0.5: Color(0.5, 0.9, 0.1, 0.7),     # 1/2" guard - Yellow-Green
	1.0: Color(0.1, 0.8, 0.1, 0.7),     # 1" Guard Comb - Green
}

## Currently highlighted zone
var _highlighted_zone: String = ""

## BreedData for guide overlay colors
var breed_data: Resource = null


func _ready() -> void:
	# Discover all zone Area3D nodes
	_discover_zones(self)
	# Initialize groomed state
	for zone_id in zones:
		groomed_state[zone_id] = 0.0
	# Discover mesh instances per zone
	_discover_zone_meshes(self)


func _discover_zones(node: Node) -> void:
	if node is Area3D and node.has_meta("zone_id"):
		var zone_id: String = node.get_meta("zone_id")
		zones[zone_id] = node
	for child in node.get_children():
		_discover_zones(child)


func _discover_zone_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.has_meta("zone_id"):
		var zone_id: String = node.get_meta("zone_id")
		if not zone_meshes.has(zone_id):
			zone_meshes[zone_id] = []
		zone_meshes[zone_id].append(node)
	for child in node.get_children():
		_discover_zone_meshes(child)


## Set which zone is highlighted (hovered). Pass "" to clear.
func set_highlighted_zone(zone_id: String) -> void:
	if zone_id == _highlighted_zone:
		return

	# Clear old highlight
	if _highlighted_zone != "" and zone_meshes.has(_highlighted_zone):
		for mesh in zone_meshes[_highlighted_zone]:
			_set_shader_param(mesh, "highlight_strength", 0.0)

	_highlighted_zone = zone_id

	# Apply new highlight
	if _highlighted_zone != "" and zone_meshes.has(_highlighted_zone):
		for mesh in zone_meshes[_highlighted_zone]:
			_set_shader_param(mesh, "highlight_strength", 1.0)


## Apply grooming to a zone (increases groomed amount)
func apply_grooming(zone_id: String, amount: float = 0.25) -> void:
	if not groomed_state.has(zone_id):
		return
	groomed_state[zone_id] = clampf(groomed_state[zone_id] + amount, 0.0, 1.0)
	_update_zone_groomed_visuals(zone_id)


## Set the groomed amount directly (used by continuous grooming tick).
func set_groomed_amount(zone_id: String, amount: float) -> void:
	if not groomed_state.has(zone_id):
		return
	groomed_state[zone_id] = amount
	_update_zone_groomed_visuals(zone_id)


## Toggle the grooming guide overlay
func toggle_guide_overlay() -> void:
	guide_overlay_visible = not guide_overlay_visible
	_update_guide_overlay()


## Set guide overlay visibility directly
func set_guide_overlay(visible_flag: bool) -> void:
	guide_overlay_visible = visible_flag
	_update_guide_overlay()


## Set breed data for guide overlay colors
func set_breed_data(data: Resource) -> void:
	breed_data = data
	if guide_overlay_visible:
		_update_guide_overlay()


func _update_zone_groomed_visuals(zone_id: String) -> void:
	if not zone_meshes.has(zone_id):
		return
	var groomed := groomed_state.get(zone_id, 0.0) as float
	for mesh in zone_meshes[zone_id]:
		_set_shader_param(mesh, "groomed_amount", groomed)


func _update_guide_overlay() -> void:
	for zone_id in zone_meshes:
		var overlay_strength := 0.0
		var color := Color(0.5, 0.5, 0.5, 0.5)

		if guide_overlay_visible:
			overlay_strength = 1.0
			color = _get_guide_color_for_zone(zone_id)

		for mesh in zone_meshes[zone_id]:
			_set_shader_param(mesh, "guide_overlay_strength", overlay_strength)
			_set_shader_param(mesh, "guide_color", color)


func _get_guide_color_for_zone(zone_id: String) -> Color:
	if breed_data and breed_data.grooming_zones.has(zone_id):
		var zone_info: Dictionary = breed_data.grooming_zones[zone_id]
		var required_tool: String = zone_info.get("required_tool", "")
		var guard_size: float = zone_info.get("guard_size", 0.0)

		# Non-clipper tools always get the 0.0 color (light blue)
		if required_tool != "CLIPPER":
			return GUARD_COLORS[0.0]

		# For clippers, find closest guard color (skip 0.0 which is non-clipper)
		var best_key := 0.0625
		var best_diff := 999.0
		for key in GUARD_COLORS:
			if key == 0.0:
				continue  # Skip the non-clipper color
			var diff := absf(key - guard_size)
			if diff < best_diff:
				best_diff = diff
				best_key = key
		return GUARD_COLORS[best_key]

	# Default color based on zone type for demo purposes
	var default_colors: Dictionary = {
		"crown": Color(0.1, 0.8, 0.1, 0.7),
		"muzzle": Color(0.2, 0.7, 0.2, 0.7),
		"ears_left": Color(0.9, 0.5, 0.1, 0.7),
		"ears_right": Color(0.9, 0.5, 0.1, 0.7),
		"back": Color(0.1, 0.5, 0.9, 0.7),
		"chest": Color(0.9, 0.9, 0.1, 0.7),
		"belly": Color(0.9, 0.1, 0.1, 0.7),
		"leg_front_left": Color(0.5, 0.1, 0.9, 0.7),
		"leg_front_right": Color(0.5, 0.1, 0.9, 0.7),
		"leg_rear_left": Color(0.9, 0.1, 0.9, 0.7),
		"leg_rear_right": Color(0.9, 0.1, 0.9, 0.7),
		"tail": Color(0.1, 0.9, 0.9, 0.7),
		"paw_front_left": Color(0.6, 0.3, 0.8, 0.7),
		"paw_front_right": Color(0.6, 0.3, 0.8, 0.7),
		"paw_rear_left": Color(0.8, 0.3, 0.6, 0.7),
		"paw_rear_right": Color(0.8, 0.3, 0.6, 0.7),
	}
	return default_colors.get(zone_id, Color(0.5, 0.5, 0.5, 0.7))


func _set_shader_param(mesh: MeshInstance3D, param: String, value: Variant) -> void:
	# Shell fur uses material overrides — iterate all surface overrides
	var mat_count := mesh.get_surface_override_material_count()
	for i in mat_count:
		var mat := mesh.get_surface_override_material(i)
		if mat is ShaderMaterial:
			mat.set_shader_parameter(param, value)
	# Also check the mesh's own material
	if mesh.material_override is ShaderMaterial:
		(mesh.material_override as ShaderMaterial).set_shader_parameter(param, value)
	# Check mesh surface materials
	if mesh.mesh:
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(i)
			if mat is ShaderMaterial:
				mat.set_shader_parameter(param, value)


## Get all zone IDs
func get_zone_ids() -> Array:
	return zones.keys()


## Reset all grooming state
func reset_grooming() -> void:
	for zone_id in groomed_state:
		groomed_state[zone_id] = 0.0
		_update_zone_groomed_visuals(zone_id)
