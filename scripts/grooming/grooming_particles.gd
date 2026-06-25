## GroomingParticles -- One-shot burst of fur clipping particles.
## Uses CPUParticles3D for web-export compatibility (no GPU compute shaders).
## Spawned at a zone position, emits a short burst of small spheres, then frees itself.
class_name GroomingParticles
extends CPUParticles3D


func _ready() -> void:
	# One-shot burst configuration
	emitting = false
	one_shot = true
	amount = 25
	lifetime = 1.0
	explosiveness = 0.8

	# Physics -- particles drift downward like loose fur clippings
	direction = Vector3(0, -1, 0)
	gravity = Vector3(0, -4.0, 0)
	spread = 45.0
	initial_velocity_min = 0.5
	initial_velocity_max = 2.0

	# Appearance -- small sphere particles representing fur clippings
	var sphere := SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	mesh = sphere

	# Scale variation for natural look
	scale_amount_min = 0.5
	scale_amount_max = 1.5

	# Begin emitting
	emitting = true

	# Auto-free when the one-shot burst finishes
	finished.connect(queue_free)


## Set particle color to match the dog's fur.
func set_fur_color(fur_color: Color) -> void:
	color = fur_color
