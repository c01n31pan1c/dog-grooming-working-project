## GroomingArenaScreen — Main controller for the grooming arena scene.
## Integration hub: wires dog model, orbit camera, zone detection, tool system,
## grooming controller, input handler, toolbar, HUD, timer, callouts, and
## competition context together into a playable grooming session.
extends Node

## Scene node references
@onready var dog_model: DogModel = $SubViewportContainer/SubViewport/DogScene/DogPlaceholder
@onready var orbit_camera: OrbitCamera = $SubViewportContainer/SubViewport/DogScene/OrbitCamera
@onready var zone_detection: ZoneDetection = $ZoneDetection
@onready var guide_button: Button = $UI/TopBar/GuideButton
@onready var zone_label: Label = $UI/BottomBar/ZoneLabel
@onready var legend_panel: PanelContainer = $UI/LegendPanel

## Dynamically created subsystems
var _tool_system: ToolSystem
var _grooming_controller: GroomingController
var _input_handler: TapSelectInput
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


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.GROOMING

	# Load competition context from transition
	var context: Dictionary = GameManager.transition_context
	if context.has("competition_data"):
		_competition_data = context["competition_data"] as CompetitionData
		_is_competition_mode = true
		if _competition_data and _competition_data.breed:
			_breed_data = _competition_data.breed

	# Load the fur shader
	fur_shader = load("res://shaders/shell_fur.gdshader") as Shader

	# Wait a frame for scene tree to be ready
	await get_tree().process_frame

	# Apply shell fur to the dog model
	if dog_model and fur_shader:
		var shell_meshes := ShellFurSetup.setup(dog_model, fur_shader)
		for zone_id in shell_meshes:
			dog_model.zone_meshes[zone_id] = shell_meshes[zone_id]

	# Set breed data on dog model for guide overlay
	if dog_model and _breed_data:
		dog_model.set_breed_data(_breed_data)

	# --- Create subsystems as child nodes ---

	# ToolSystem
	_tool_system = ToolSystem.new()
	_tool_system.name = "ToolSystem"
	add_child(_tool_system)

	# TapSelectInput (input handler)
	_input_handler = TapSelectInput.new()
	_input_handler.name = "TapSelectInput"
	add_child(_input_handler)
	if orbit_camera:
		_input_handler.set_camera(orbit_camera)

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

	# Timer signals
	_timer_system.timer_expired.connect(_on_timer_expired)
	_timer_system.timer_tick.connect(_on_timer_tick)
	_timer_system.timer_warning.connect(_on_timer_warning)

	# Update zone label
	_update_zone_label("")

	# --- Start the grooming session ---
	_start_session()


func _start_session() -> void:
	if _breed_data:
		_grooming_controller.start_grooming(_breed_data)

		# Deduct entry fee
		if _competition_data and _competition_data.entry_fee > 0:
			_currency_manager.spend_currency(_competition_data.entry_fee)

		# Start timer
		var time_limit := 120.0
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
		push_warning("GroomingArena: No breed data — running in free play mode")


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
var _hud_warning_rect: ColorRect

func _setup_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "HUD"
	_hud.layer = 10
	add_child(_hud)

	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 50.0
	top_bar.add_theme_constant_override("separation", 20)
	_hud.add_child(top_bar)

	# Timer
	_hud_timer_label = Label.new()
	_hud_timer_label.text = "2:00"
	_hud_timer_label.add_theme_font_size_override("font_size", 32)
	_hud_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_timer_label.custom_minimum_size = Vector2(120, 0)
	top_bar.add_child(_hud_timer_label)

	_hud_warning_rect = ColorRect.new()
	_hud_warning_rect.color = Color(1.0, 0.549, 0.486, 0.2)
	_hud_warning_rect.custom_minimum_size = Vector2(120, 40)
	_hud_warning_rect.visible = false
	top_bar.add_child(_hud_warning_rect)

	# Tool indicator
	var tool_label_header := Label.new()
	tool_label_header.text = "Tool: "
	tool_label_header.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(tool_label_header)

	_hud_tool_label = Label.new()
	_hud_tool_label.text = "None"
	_hud_tool_label.add_theme_font_size_override("font_size", 20)
	_hud_tool_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_hud_tool_label)

	# Coins
	_hud_coin_label = Label.new()
	_hud_coin_label.text = "%d coins" % SaveManager.data.get("currency", 0)
	_hud_coin_label.add_theme_font_size_override("font_size", 20)
	_hud_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(_hud_coin_label)

	# Progress bar area (just above toolbar)
	var progress_container := HBoxContainer.new()
	progress_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_container.offset_top = -140.0
	progress_container.offset_bottom = -110.0
	progress_container.offset_left = 20.0
	progress_container.offset_right = -20.0
	progress_container.add_theme_constant_override("separation", 10)
	_hud.add_child(progress_container)

	var progress_label := Label.new()
	progress_label.text = "Progress:"
	progress_label.add_theme_font_size_override("font_size", 18)
	progress_container.add_child(progress_label)

	_hud_progress_bar = ProgressBar.new()
	_hud_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_progress_bar.custom_minimum_size = Vector2(0, 24)
	_hud_progress_bar.max_value = 100.0
	_hud_progress_bar.value = 0.0
	progress_container.add_child(_hud_progress_bar)

	_hud_zone_count_label = Label.new()
	_hud_zone_count_label.text = "0 / 0"
	_hud_zone_count_label.add_theme_font_size_override("font_size", 18)
	progress_container.add_child(_hud_zone_count_label)

	# Connect EventBus signals for HUD updates
	EventBus.tool_selected.connect(_on_hud_tool_selected)
	EventBus.zone_groomed.connect(_on_hud_zone_groomed)
	EventBus.currency_changed.connect(_on_hud_currency_changed)

	# Pause button
	var pause_btn := Button.new()
	pause_btn.text = "Pause"
	pause_btn.custom_minimum_size = Vector2(80, 40)
	pause_btn.pressed.connect(func() -> void:
		get_tree().paused = not get_tree().paused
		pause_btn.text = "Resume" if get_tree().paused else "Pause"
		if get_tree().paused:
			_timer_system.pause()
		else:
			_timer_system.resume()
	)
	top_bar.add_child(pause_btn)

	# Guide toggle in HUD
	var guide_btn := Button.new()
	guide_btn.text = "Guide"
	guide_btn.custom_minimum_size = Vector2(80, 40)
	guide_btn.pressed.connect(_on_guide_button_pressed)
	top_bar.add_child(guide_btn)


func _on_hud_tool_selected(tool_data: Resource) -> void:
	if tool_data != null and tool_data is ToolData:
		var td := tool_data as ToolData
		_hud_tool_label.text = td.tool_name
	else:
		_hud_tool_label.text = "None"


func _on_hud_zone_groomed(_zone_id: String, _tool_data: Resource) -> void:
	if _breed_data == null:
		return
	var progress := _grooming_controller.get_grooming_progress()
	_hud_progress_bar.value = progress * 100.0
	var total: int = _breed_data.grooming_zones.size()
	var done: int = int(progress * total)
	_hud_zone_count_label.text = "%d / %d" % [done, total]


func _on_hud_currency_changed(_new_amount: int, _delta: int) -> void:
	_hud_coin_label.text = "%d coins" % SaveManager.data.get("currency", 0)


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
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var label := Label.new()
	label.name = "FactLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
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


func _on_timer_warning(_seconds_remaining: float) -> void:
	if _hud_warning_rect:
		_hud_warning_rect.visible = true


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
		var zone_results := _grooming_controller.get_zone_results()
		var time_bonus := _timer_system.calculate_time_bonus(100.0)

		# Build style extras from zone states
		var style_extras := {
			"cologne": _has_zone_state("cologned"),
			"accessories": [],
			"medicine": _has_zone_state("medicine_applied"),
			"medicine_needed": false,
		}

		var score_breakdown := _scoring_engine.calculate_score(
			zone_results, _breed_data, time_bonus, style_extras
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
