## GroomingArenaScreen — Main controller for the grooming arena scene.
## Wires up dog model, orbit camera, zone detection, fur shader, and UI overlays.
extends Node

@onready var dog_model: DogModel = $SubViewportContainer/SubViewport/DogScene/DogPlaceholder
@onready var orbit_camera: OrbitCamera = $SubViewportContainer/SubViewport/DogScene/OrbitCamera
@onready var zone_detection: ZoneDetection = $ZoneDetection
@onready var guide_button: Button = $UI/TopBar/GuideButton
@onready var zone_label: Label = $UI/BottomBar/ZoneLabel
@onready var legend_panel: PanelContainer = $UI/LegendPanel

var fur_shader: Shader


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.GROOMING

	# Load the fur shader
	fur_shader = load("res://shaders/shell_fur.gdshader") as Shader

	# Wait a frame for scene tree to be ready
	await get_tree().process_frame

	# Apply shell fur to the dog model
	if dog_model and fur_shader:
		var shell_meshes := ShellFurSetup.setup(dog_model, fur_shader)
		# Update the dog_model's zone_meshes with shell copies
		for zone_id in shell_meshes:
			dog_model.zone_meshes[zone_id] = shell_meshes[zone_id]

	# Wire up zone detection
	if zone_detection and orbit_camera:
		zone_detection.camera = orbit_camera

	if zone_detection:
		zone_detection.zone_hover_changed.connect(_on_zone_hover_changed)

	# Wire up guide button
	if guide_button:
		guide_button.pressed.connect(_on_guide_button_pressed)

	# Hide legend initially
	if legend_panel:
		legend_panel.visible = false

	# Listen for zone_groomed events to update visuals
	EventBus.zone_groomed.connect(_on_zone_groomed)

	# Update zone label
	_update_zone_label("")


func _unhandled_input(event: InputEvent) -> void:
	# Click/tap to groom the hovered zone (when not dragging camera)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Only groom on quick taps, not drags — use a short threshold
			# For now, right-click to groom (left-click is camera orbit)
			pass
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and zone_detection:
			zone_detection.try_groom_at_position(mb.position)


func _on_zone_hover_changed(zone_id: String) -> void:
	if dog_model:
		dog_model.set_highlighted_zone(zone_id)
	_update_zone_label(zone_id)


func _on_zone_groomed(zone_id: String, _tool_data: Resource) -> void:
	if dog_model:
		dog_model.apply_grooming(zone_id, 0.25)


func _on_guide_button_pressed() -> void:
	if dog_model:
		dog_model.toggle_guide_overlay()
	if legend_panel:
		legend_panel.visible = dog_model.guide_overlay_visible if dog_model else false


func _update_zone_label(zone_id: String) -> void:
	if not zone_label:
		return
	if zone_id == "":
		zone_label.text = "Hover over a zone"
	else:
		var display_name := zone_id.replace("_", " ").capitalize()
		var groomed_pct := ""
		if dog_model and dog_model.groomed_state.has(zone_id):
			var pct := int(dog_model.groomed_state[zone_id] * 100)
			groomed_pct = " (%d%% groomed)" % pct
		zone_label.text = display_name + groomed_pct
