## ShellFurSetup — Applies shell fur shader to all tagged MeshInstance3D nodes.
## Call setup() after the dog model scene is loaded to create shell layers.
class_name ShellFurSetup
extends RefCounted

const SHELL_COUNT: int = 6

## Apply shell fur materials to all MeshInstance3D children with zone_id metadata.
## Returns a Dictionary mapping zone_id -> Array[MeshInstance3D] (the shell copies).
## If breed_material is provided, its shader parameters are used as defaults for fur color/length/density.
static func setup(dog_root: Node3D, fur_shader: Shader, breed_material: ShaderMaterial = null) -> Dictionary:
	var zone_shells: Dictionary = {}
	var meshes: Array[MeshInstance3D] = []
	_find_fur_meshes(dog_root, meshes)

	for original_mesh in meshes:
		var zone_id: String = original_mesh.get_meta("zone_id", "")
		if zone_id == "":
			continue

		if not zone_shells.has(zone_id):
			zone_shells[zone_id] = []

		# Apply shell materials to the original mesh (shell 0 = base)
		var base_mat := _create_shell_material(fur_shader, 0, zone_id, breed_material)
		original_mesh.material_override = base_mat
		zone_shells[zone_id].append(original_mesh)

		# Create additional shell layers as duplicated meshes
		for shell_idx in range(1, SHELL_COUNT):
			var shell_mesh := MeshInstance3D.new()
			shell_mesh.mesh = original_mesh.mesh
			shell_mesh.transform = Transform3D.IDENTITY
			shell_mesh.name = "%s_shell_%d" % [original_mesh.name, shell_idx]
			shell_mesh.set_meta("zone_id", zone_id)

			var shell_mat := _create_shell_material(fur_shader, shell_idx, zone_id, breed_material)
			shell_mesh.material_override = shell_mat

			original_mesh.add_child(shell_mesh)
			zone_shells[zone_id].append(shell_mesh)

	return zone_shells


static func _create_shell_material(fur_shader: Shader, shell_index: int, _zone_id: String, breed_material: ShaderMaterial = null) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = fur_shader
	mat.set_shader_parameter("shell_index", shell_index)
	mat.set_shader_parameter("shell_count", SHELL_COUNT)

	# Use breed-specific fur parameters if available, otherwise defaults
	if breed_material:
		mat.set_shader_parameter("fur_color", breed_material.get_shader_parameter("fur_color"))
		mat.set_shader_parameter("fur_tip_color", breed_material.get_shader_parameter("fur_tip_color"))
		mat.set_shader_parameter("fur_length", breed_material.get_shader_parameter("fur_length"))
		mat.set_shader_parameter("fur_density", breed_material.get_shader_parameter("fur_density"))
	else:
		mat.set_shader_parameter("fur_color", Color(0.65, 0.45, 0.25, 1.0))
		mat.set_shader_parameter("fur_tip_color", Color(0.85, 0.7, 0.45, 1.0))
		mat.set_shader_parameter("fur_length", 0.04)
		mat.set_shader_parameter("fur_density", 40.0)

	mat.set_shader_parameter("groomed_amount", 0.0)
	mat.set_shader_parameter("highlight_strength", 0.0)
	mat.set_shader_parameter("guide_overlay_strength", 0.0)
	mat.set_shader_parameter("guide_color", Color(0.5, 0.5, 0.5, 0.5))

	# Outer shells need transparency for alpha blending
	if shell_index > 0:
		mat.render_priority = shell_index

	return mat


static func _find_fur_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.has_meta("zone_id"):
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		_find_fur_meshes(child, result)
