## GroomingArenaScreen — Main controller for the grooming arena scene.
## Integration hub: wires dog model, orbit camera, zone detection, tool system,
## grooming controller, input handler, toolbar, HUD, timer, callouts, and
## competition context together into a playable grooming session.
extends Node

## Scene node references
@onready var dog_model: DogModel = $SubViewportContainer/SubViewport/DogScene/DogPlaceholder
@onready var orbit_camera: OrbitCamera = $SubViewportContainer/SubViewport/DogScene/OrbitCamera
@onready var zone_detection: ZoneDetection = $ZoneDetection
@onready var zone_label: Label = $UI/BottomBar/ZoneLabel
@onready var legend_panel: PanelContainer = $UI/LegendPanel
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport

## Dynamically created subsystems
var _tool_system: ToolSystem
var _grooming_controller: GroomingController
var _input_handler: ContinuousGroomInput
var _toolbar: Toolbar
var _hud: CanvasLayer  # The HUD scene instance
var _timer_system: TimerSystem
var _callouts: GroomingCallouts
var _scoring_engine: ScoringEngine
var _judge_ai: JudgeAI
var _currency_manager: CurrencyManager
var _progression_manager: ProgressionManager

## Competition context (set from GameManager.transition_context)
var _competition_data: CompetitionData = null
var _breed_data: BreedData = null
var _is_competition_mode: bool = false
var _grooming_finished: bool = false

var fur_shader: Shader

## Particle effect throttling
var _last_particle_time: Dictionary = {}
const PARTICLE_COOLDOWN := 0.4
var _cached_fur_color: Color = Color(0.65, 0.45, 0.25)

## Default breed to load when no competition context is provided (free play).
const DEFAULT_BREED_PATH := "res://resources/breeds/golden_retriever.tres"


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.GROOMING

	# Load competition context from transition
	var context: Dictionary = GameManager.transition_context
	if context.has("competition_data"):
		_competition_data = context["competition_data"] as CompetitionData
		_is_competition_mode = true
		if _competition_data and _competition_data.breed:
			_breed_data = _competition_data.breed

	# Free-play fallback: load default breed if none provided
	if _breed_data == null:
		if context.has("breed_data"):
			_breed_data = context["breed_data"] as BreedData
		if _breed_data == null:
			var default_breed := load(DEFAULT_BREED_PATH)
			if default_breed is BreedData:
				_breed_data = default_breed as BreedData
			else:
				push_warning("GroomingArena: Could not load default breed from %s" % DEFAULT_BREED_PATH)

	# Load the fur shader
	fur_shader = load("res://shaders/shell_fur.gdshader") as Shader

	# Load breed-specific model if available
	if _breed_data and _breed_data.model_scene_path != "":
		var breed_scene := load(_breed_data.model_scene_path) as PackedScene
		if breed_scene:
			var dog_scene_parent := dog_model.get_parent()
			var old_model := dog_model
			var new_model := breed_scene.instantiate() as DogModel
			if new_model:
				dog_scene_parent.add_child(new_model)
				new_model.transform = old_model.transform
				new_model.name = old_model.name
				old_model.queue_free()
				dog_model = new_model
			else:
				push_warning("GroomingArena: Failed to instantiate breed model, using placeholder")
		else:
			push_warning("GroomingArena: Failed to load breed scene '%s', using placeholder" % _breed_data.model_scene_path)

	# Wait a frame for scene tree to be ready
	await get_tree().process_frame

	# Sync SubViewport size to the window viewport so coordinate mapping works
	# on screens that differ from the hardcoded 1920x1080.
	_sync_sub_viewport_size()
	get_tree().root.size_changed.connect(_sync_sub_viewport_size)

	# Load breed-specific fur material if available
	var breed_fur_material: ShaderMaterial = null
	if _breed_data and _breed_data.fur_material_path != "":
		breed_fur_material = load(_breed_data.fur_material_path) as ShaderMaterial

	# Apply shell fur to the dog model (with breed-specific colors if available)
	if dog_model and fur_shader:
		var shell_meshes := ShellFurSetup.setup(dog_model, fur_shader, breed_fur_material)
		for zone_id in shell_meshes:
			dog_model.zone_meshes[zone_id] = shell_meshes[zone_id]

	# Cache fur color for particles from breed material
	if breed_fur_material:
		var fc = breed_fur_material.get_shader_parameter("fur_color")
		if fc is Color:
			_cached_fur_color = fc

	# Set breed data on dog model for guide overlay
	if dog_model and _breed_data:
		dog_model.set_breed_data(_breed_data)

	# --- Create subsystems as child nodes ---

	# ToolSystem
	_tool_system = ToolSystem.new()
	_tool_system.name = "ToolSystem"
	add_child(_tool_system)

	# ContinuousGroomInput (input handler)
	_input_handler = ContinuousGroomInput.new()
	_input_handler.name = "ContinuousGroomInput"
	add_child(_input_handler)
	_input_handler.setup(zone_detection)

	# Give OrbitCamera a reference to the groom input so it can check grooming state
	orbit_camera.set_groom_input(_input_handler)

	# GroomingController
	_grooming_controller = GroomingController.new()
	_grooming_controller.name = "GroomingController"
	add_child(_grooming_controller)
	_grooming_controller.setup(_tool_system, orbit_camera)
	_grooming_controller.set_input_handler(_input_handler)

	# Toolbar (anchored to bottom)
	_toolbar = Toolbar.new()
	_toolbar.name = "Toolbar"
	add_child(_toolbar)
	_toolbar.setup(_tool_system, _input_handler)

	# TimerSystem
	_timer_system = TimerSystem.new()
	_timer_system.name = "TimerSystem"
	add_child(_timer_system)

	# ScoringEngine
	_scoring_engine = ScoringEngine.new()
	_scoring_engine.name = "ScoringEngine"
	add_child(_scoring_engine)

	# JudgeAI
	_judge_ai = JudgeAI.new()
	_judge_ai.name = "JudgeAI"
	add_child(_judge_ai)

	# CurrencyManager
	_currency_manager = CurrencyManager.new()
	_currency_manager.name = "CurrencyManager"
	add_child(_currency_manager)

	# ProgressionManager
	_progression_manager = ProgressionManager.new()
	_progression_manager.name = "ProgressionManager"
	add_child(_progression_manager)

	# HUD (CanvasLayer) — created programmatically since it uses unique name refs
	# We build a minimal HUD inline to avoid scene dependency issues
	_setup_hud()

	# GroomingCallouts
	_callouts = _create_callouts()
	add_child(_callouts)

	# Wire up zone detection with SubViewport references
	if zone_detection and orbit_camera:
		zone_detection.camera = orbit_camera
	if zone_detection and sub_viewport_container and sub_viewport:
		zone_detection.sub_viewport_container = sub_viewport_container
		zone_detection.sub_viewport = sub_viewport

	if zone_detection:
		zone_detection.zone_hover_changed.connect(_on_zone_hover_changed)

	# Hide legend initially
	if legend_panel:
		legend_panel.visible = false

	# Listen for continuous grooming tick to update visuals smoothly
	EventBus.zone_grooming_tick.connect(_on_zone_grooming_tick)
	# Listen for zone_groomed events (threshold crossings) for HUD/effects
	EventBus.zone_groomed.connect(_on_zone_groomed)

	# Timer signals
	_timer_system.timer_expired.connect(_on_timer_expired)
	_timer_system.timer_tick.connect(_on_timer_tick)
	_timer_system.timer_warning.connect(_on_timer_warning)

	# Update zone label
	_update_zone_label("")

	# --- Start the grooming session ---
	_start_session()


## Keep the SubViewport size in sync with the window so that screen-to-viewport
## coordinate mapping stays correct on every display resolution.
func _sync_sub_viewport_size() -> void:
	if sub_viewport:
		var window_size := get_tree().root.size
		if window_size != Vector2i.ZERO and sub_viewport.size != window_size:
			sub_viewport.size = window_size


func _start_session() -> void:
	if _breed_data:
		_grooming_controller.start_grooming(_breed_data)

		# Entry fee is deducted by PreShowScreen before arriving here.

		# Start timer
		var time_limit := 180.0
		if _competition_data:
			time_limit = _competition_data.time_limit_seconds
		_timer_system.start_timer(time_limit)

		# Configure HUD
		if _hud_progress_bar:
			_hud_progress_bar.max_value = 100.0
			_hud_progress_bar.value = 0.0
		if _hud_zone_count_label:
			var zone_count: int = _breed_data.grooming_zones.size()
			_hud_zone_count_label.text = "0 / %d" % zone_count

		# Record breed groomed for progression
		_progression_manager.record_breed_groomed(_breed_data.breed_name)
	else:
		push_warning("GroomingArena: No breed data — grooming session cannot start")


func _process(_delta: float) -> void:
	if _grooming_finished:
		return

	# Check if all zones are done
	if _breed_data and _grooming_controller.get_grooming_progress() >= 1.0:
		_finish_grooming()


## --- HUD setup (inline to avoid scene dependency) ---

var _hud_timer_label: Label
var _hud_tool_label: Label
var _hud_progress_bar: ProgressBar
var _hud_zone_count_label: Label
var _hud_coin_label: Label
var _hud_guide_button: Button
var _hud_done_button: Button
var _hud_instruction_label: Label
var _instruction_dismissed: bool = false

func _setup_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "HUD"
	_hud.layer = 10
	add_child(_hud)

	# -- Top LEFT group: Timer + Tool indicator --
	var top_left := HBoxContainer.new()
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.offset_left = 16.0
	top_left.offset_top = 8.0
	top_left.offset_right = 300.0
	top_left.offset_bottom = 70.0
	top_left.add_theme_constant_override("separation", 16)
	_hud.add_child(top_left)

	_hud_timer_label = Label.new()
	_hud_timer_label.text = "3:00"
	_hud_timer_label.add_theme_font_size_override("font_size", 36)
	_hud_timer_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314))
	_hud_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hud_timer_label.custom_minimum_size = Vector2(100, 0)
	top_left.add_child(_hud_timer_label)

	_hud_tool_label = Label.new()
	_hud_tool_label.text = "Tool: None"
	_hud_tool_label.add_theme_font_size_override("font_size", 28)
	_hud_tool_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314))
	_hud_tool_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_left.add_child(_hud_tool_label)

	# -- Top RIGHT group: Coins + Pause --
	var top_right := HBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -440.0
	top_right.offset_top = 8.0
	top_right.offset_right = -16.0
	top_right.offset_bottom = 70.0
	top_right.add_theme_constant_override("separation", 12)
	top_right.alignment = BoxContainer.ALIGNMENT_END
	_hud.add_child(top_right)

	_hud_coin_label = Label.new()
	_hud_coin_label.text = "%d coins" % SaveManager.data.get("currency", 0)
	_hud_coin_label.add_theme_font_size_override("font_size", 28)
	_hud_coin_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314))
	_hud_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_right.add_child(_hud_coin_label)

	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(100, 64)
	quit_btn.pressed.connect(_on_quit_pressed)
	top_right.add_child(quit_btn)

	_hud_guide_button = Button.new()
	_hud_guide_button.text = "Guide"
	_hud_guide_button.custom_minimum_size = Vector2(160, 64)
	_hud_guide_button.pressed.connect(_on_guide_button_pressed)
	top_right.add_child(_hud_guide_button)

	var pause_btn := Button.new()
	pause_btn.text = "Pause"
	pause_btn.custom_minimum_size = Vector2(120, 64)
	pause_btn.pressed.connect(func() -> void:
		get_tree().paused = not get_tree().paused
		pause_btn.text = "Resume" if get_tree().paused else "Pause"
		if get_tree().paused:
			_timer_system.pause()
		else:
			_timer_system.resume()
	)
	top_right.add_child(pause_btn)

	# -- Progress bar area (just above toolbar) --
	var progress_container := HBoxContainer.new()
	progress_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_container.offset_top = -160.0
	progress_container.offset_bottom = -120.0
	progress_container.offset_left = 20.0
	progress_container.offset_right = -20.0
	progress_container.add_theme_constant_override("separation", 10)
	_hud.add_child(progress_container)

	var progress_label := Label.new()
	progress_label.text = "Progress:"
	progress_label.add_theme_font_size_override("font_size", 26)
	progress_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314))
	progress_container.add_child(progress_label)

	_hud_progress_bar = ProgressBar.new()
	_hud_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_progress_bar.custom_minimum_size = Vector2(0, 32)
	_hud_progress_bar.max_value = 100.0
	_hud_progress_bar.value = 0.0
	progress_container.add_child(_hud_progress_bar)

	_hud_zone_count_label = Label.new()
	_hud_zone_count_label.text = "0 / 0"
	_hud_zone_count_label.add_theme_font_size_override("font_size", 26)
	_hud_zone_count_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314))
	progress_container.add_child(_hud_zone_count_label)

	# -- "Done" button (hidden until at least 1 zone groomed) --
	_hud_done_button = Button.new()
	_hud_done_button.text = "Done"
	_hud_done_button.custom_minimum_size = Vector2(140, 64)
	_hud_done_button.visible = false
	_hud_done_button.pressed.connect(_finish_grooming)
	progress_container.add_child(_hud_done_button)

	# -- Instruction label (center screen, semi-transparent) --
	_hud_instruction_label = Label.new()
	_hud_instruction_label.text = "Select a tool below, then drag across the dog to groom!"
	_hud_instruction_label.add_theme_font_size_override("font_size", 30)
	_hud_instruction_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314, 0.85))
	_hud_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_instruction_label.set_anchors_preset(Control.PRESET_CENTER)
	_hud_instruction_label.offset_left = -250.0
	_hud_instruction_label.offset_right = 250.0
	_hud_instruction_label.offset_top = -20.0
	_hud_instruction_label.offset_bottom = 20.0
	_hud_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_child(_hud_instruction_label)

	# Auto-dismiss instruction after 5 seconds
	get_tree().create_timer(5.0).timeout.connect(_dismiss_instruction)

	# Connect EventBus signals for HUD updates
	EventBus.tool_selected.connect(_on_hud_tool_selected)
	EventBus.zone_groomed.connect(_on_hud_zone_groomed)
	EventBus.currency_changed.connect(_on_hud_currency_changed)


func _dismiss_instruction() -> void:
	if _instruction_dismissed:
		return
	_instruction_dismissed = true
	if _hud_instruction_label and _hud_instruction_label.is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_hud_instruction_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(_hud_instruction_label.queue_free)


func _on_hud_tool_selected(tool_data: Resource) -> void:
	if tool_data != null and tool_data is ToolData:
		var td := tool_data as ToolData
		_hud_tool_label.text = "Tool: %s" % td.tool_name
	else:
		_hud_tool_label.text = "Tool: None"
	# Dismiss instruction on first tool selection
	_dismiss_instruction()


func _on_hud_zone_groomed(_zone_id: String, _tool_data: Resource) -> void:
	if _breed_data == null:
		return
	var progress := _grooming_controller.get_grooming_progress()
	# Smooth progress bar fill instead of jumping
	UIAnimations.smooth_progress(_hud_progress_bar, progress * 100.0, 0.3)
	var total: int = _breed_data.grooming_zones.size()
	var done: int = int(progress * total)
	_hud_zone_count_label.text = "%d / %d" % [done, total]
	# Show Done button after at least 1 zone has been groomed
	if done >= 1 and _hud_done_button and not _hud_done_button.visible:
		_hud_done_button.visible = true


var _prev_coin_value: int = -1

func _on_hud_currency_changed(_new_amount: int, _delta: int) -> void:
	var new_coins: int = SaveManager.data.get("currency", 0)
	if _prev_coin_value >= 0 and _prev_coin_value != new_coins:
		UIAnimations.coin_change(_hud_coin_label, _prev_coin_value, new_coins)
	else:
		_hud_coin_label.text = "%d coins" % new_coins
	_prev_coin_value = new_coins


## --- Callouts ---

func _create_callouts() -> GroomingCallouts:
	# GroomingCallouts needs Panel > MarginContainer > FactLabel
	var callouts := GroomingCallouts.new()
	callouts.name = "GroomingCallouts"

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 20.0
	panel.offset_top = -180.0
	panel.offset_right = 420.0
	panel.offset_bottom = -120.0
	panel.visible = false
	callouts.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var label := Label.new()
	label.name = "FactLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	margin.add_child(label)

	return callouts


## --- Timer callbacks ---

func _on_timer_tick(seconds_remaining: float) -> void:
	if _hud_timer_label:
		var minutes := int(seconds_remaining) / 60
		var seconds := int(seconds_remaining) % 60
		_hud_timer_label.text = "%d:%02d" % [minutes, seconds]

		# Urgency coloring
		var total := _timer_system.get_duration()
		var fraction := seconds_remaining / maxf(total, 0.01)
		if fraction <= 0.15:
			_hud_timer_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42))
		elif fraction <= 0.4:
			_hud_timer_label.add_theme_color_override("font_color", Color(1.0, 0.549, 0.486))
		else:
			_hud_timer_label.add_theme_color_override("font_color", Color(0.173, 0.243, 0.314))


var _timer_pulse_tween: Tween = null

func _on_timer_warning(_seconds_remaining: float) -> void:
	# Start gentle pulse on timer label
	if _hud_timer_label and _timer_pulse_tween == null:
		_timer_pulse_tween = UIAnimations.start_pulse(_hud_timer_label)


func _on_timer_expired() -> void:
	_finish_grooming()


## --- Grooming completion ---

func _finish_grooming() -> void:
	if _grooming_finished:
		return
	_grooming_finished = true

	_timer_system.stop_timer()
	_grooming_controller.finish_grooming()

	if _is_competition_mode and _competition_data:
		# Calculate scores and show results via competition results screen
		var raw_zone_results := _grooming_controller.get_zone_results()
		var time_bonus := _timer_system.calculate_time_bonus(100.0)

		# Convert GroomingController zone format to ScoringEngine format.
		# GroomingController stores: {groomed: bool, quality: float, tool_used: ToolData|null, ...}
		# ScoringEngine expects:     {completed: bool, tool_used: String, guard_size: float}
		var scoring_results: Dictionary = {}
		for zone_id in raw_zone_results:
			var raw: Dictionary = raw_zone_results[zone_id]
			var tool_used_str: String = ""
			var guard_size_val: float = 0.0
			var tool_ref = raw.get("tool_used", null)
			if tool_ref != null and tool_ref is ToolData:
				var td: ToolData = tool_ref as ToolData
				tool_used_str = ToolData.ToolType.keys()[td.tool_type]
				guard_size_val = td.guard_size
			scoring_results[zone_id] = {
				"completed": raw.get("groomed", false),
				"tool_used": tool_used_str,
				"guard_size": guard_size_val,
			}

		# Build style extras from zone states
		var style_extras := {
			"cologne": _has_zone_state("cologned"),
			"accessories": [],
			"medicine": _has_zone_state("medicine_applied"),
			"medicine_needed": false,
		}

		var score_breakdown := _scoring_engine.calculate_score(
			scoring_results, _breed_data, time_bonus, style_extras
		)

		var panel_result := _judge_ai.calculate_panel_score(
			score_breakdown, _competition_data.judges
		)

		# Determine placement
		var panel_score: float = panel_result["panel_score"]
		var placement := 4
		var thresholds := {1: 80.0, 2: 60.0, 3: 40.0}
		for rank in [1, 2, 3]:
			if panel_score >= thresholds[rank]:
				placement = rank
				break

		# Award coins
		var reward: int = _competition_data.get_reward(placement)
		if reward > 0:
			_currency_manager.add_currency(reward)

		# Record competition in progression
		var won: bool = placement == 1
		_progression_manager.record_competition(won, _competition_data.tier)

		# Save after competition
		SaveManager.save_game()

		# Emit competition ended
		EventBus.competition_ended.emit({
			"panel_score": panel_score,
			"placement": placement,
			"reward": reward,
			"judge_results": panel_result["judge_results"],
			"score_breakdown": score_breakdown,
			"competition_data": _competition_data,
		})

		# Transition to results screen
		GameManager.change_state(GameManager.GameState.COMPETITION_RESULTS, {
			"competition_data": _competition_data,
			"panel_result": panel_result,
			"score_breakdown": score_breakdown,
			"placement": placement,
			"reward": reward,
		})
	else:
		# Free play mode — just go back to salon
		GameManager.change_state(GameManager.GameState.SALON)


func _has_zone_state(state_key: String) -> bool:
	var results := _grooming_controller.get_zone_results()
	for zone_id in results:
		if results[zone_id].get(state_key, false):
			return true
	return false


## --- Zone hover / visual feedback ---

func _on_zone_hover_changed(zone_id: String) -> void:
	if dog_model:
		dog_model.set_highlighted_zone(zone_id)
	_update_zone_label(zone_id)


func _on_zone_grooming_tick(zone_id: String, amount: float) -> void:
	if dog_model:
		dog_model.set_groomed_amount(zone_id, amount)
		_maybe_spawn_particles(zone_id)


func _maybe_spawn_particles(zone_id: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _last_particle_time.has(zone_id) and now - _last_particle_time[zone_id] < PARTICLE_COOLDOWN:
		return
	_last_particle_time[zone_id] = now
	_spawn_grooming_particles(zone_id)


func _spawn_grooming_particles(zone_id: String) -> void:
	if not dog_model:
		return
	# Locate the Area3D node for this zone to get a world-space spawn position
	if not dog_model.zones.has(zone_id):
		return
	var zone_node: Node3D = dog_model.zones[zone_id]
	var particles := GroomingParticles.new()
	particles.set_fur_color(_cached_fur_color)
	particles.global_position = zone_node.global_position
	# Add to the DogScene parent so particles live in the 3D SubViewport
	dog_model.get_parent().add_child(particles)


func _on_zone_groomed(zone_id: String, _tool_data: Resource) -> void:
	# Spawn touch effect + floating indicator at mouse/touch position
	var ui_layer := $UI as Control
	if ui_layer:
		var touch_pos := ui_layer.get_viewport().get_mouse_position()

		# Touch ripple effect
		UIAnimations.spawn_touch_effect(ui_layer, touch_pos, UIAnimations.COLOR_MINT, 30.0)

		# Check if correct tool was used
		var is_correct := true
		if _breed_data and _tool_data is ToolData:
			var td := _tool_data as ToolData
			var zone_info: Dictionary = _breed_data.grooming_zones.get(zone_id, {})
			var required_tool: String = zone_info.get("required_tool", "")
			if required_tool != "" and td.tool_type != ToolData.ToolType.get(required_tool.to_upper(), -1):
				is_correct = false

		if is_correct:
			UIAnimations.spawn_float_indicator(ui_layer, "Good!", touch_pos, UIAnimations.COLOR_MINT)
		else:
			UIAnimations.spawn_float_indicator(ui_layer, "Wrong tool", touch_pos, UIAnimations.COLOR_CORAL)


func _on_quit_pressed() -> void:
	_grooming_finished = true
	_timer_system.stop_timer()
	if _is_competition_mode:
		GameManager.change_state(GameManager.GameState.COMPETITION)
	else:
		GameManager.change_state(GameManager.GameState.SALON)


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
