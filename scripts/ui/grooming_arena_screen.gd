## GroomingArenaScreen — Main controller for the grooming arena scene.
## Integration hub: wires dog model, orbit camera, zone detection, tool system,
## grooming controller, input handler, toolbar, HUD, timer, callouts, and
## competition context together into a playable grooming session.
extends Node

## Scene node references
@onready var dog_model: DogModel = $SubViewportContainer/SubViewport/DogScene/DogPlaceholder
@onready var orbit_camera: OrbitCamera = $SubViewportContainer/SubViewport/DogScene/OrbitCamera
@onready var zone_detection: ZoneDetection = $ZoneDetection
@onready var zone_label: Label = $UI/ZoneLabel
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport

## Dynamically created subsystems
var _tool_system: ToolSystem
var _grooming_controller: GroomingController
var _input_handler: ContinuousGroomInput
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

	# Toolbar is now built inside _setup_hud using DGCToolButton components

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

	# Guard legend visibility is managed by the HUD setup

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
			var zone_count: int = _breed_data.grooming_zones.size()
			_hud_progress_bar.label_text = "0/%d zones" % zone_count

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
## Uses DGC components: DGCProgressBar, DGCToolButton, DGCGuardLegend,
## DGCButton, DGCPanel for the design-system compliant arena HUD.

var _hud_timer_label: Label
var _hud_progress_bar: DGCProgressBar
var _hud_coin_balance: DGCCoinBalance
var _hud_done_button: DGCButton
var _hud_fact_prefix_label: Label
var _hud_fact_text_label: Label
var _hud_guard_legend: DGCGuardLegend
var _hud_instruction_label: Label
var _instruction_dismissed: bool = false
var _tool_buttons: Dictionary = {}  # tool resource_path -> DGCToolButton
var _active_tool_button: DGCToolButton = null
var _timer_warning_active: bool = false

func _setup_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "HUD"
	_hud.layer = 10
	add_child(_hud)

	# Root container spanning the full screen
	var root := VBoxContainer.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(root)

	# === TOP BAR: DGCProgressBar + Timer ===
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.add_theme_constant_override("separation", DesignTokens.SPACE[3])
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 18)
	top_margin.add_theme_constant_override("margin_right", 18)
	top_margin.add_theme_constant_override("margin_top", 14)
	top_margin.add_theme_constant_override("margin_bottom", 0)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(top_bar)
	root.add_child(top_margin)

	# Progress bar (flex, fills remaining space)
	_hud_progress_bar = DGCProgressBar.new()
	_hud_progress_bar.name = "ProgressBar"
	_hud_progress_bar.bar_height = 28
	_hud_progress_bar.tone = DGCProgressBar.Tone.MINT
	_hud_progress_bar.label_text = "0/0 zones"
	_hud_progress_bar.max_value = 100.0
	_hud_progress_bar.value = 0.0
	_hud_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_hud_progress_bar)

	# Timer display with styled background
	var timer_panel := PanelContainer.new()
	timer_panel.name = "TimerPanel"
	var timer_style := StyleBoxFlat.new()
	timer_style.bg_color = DesignTokens.BLUE_PANEL  # #f0f7ff
	timer_style.border_color = DesignTokens.BLUE_LINE  # stroke-card
	timer_style.set_border_width_all(DesignTokens.BORDER_THIN)
	timer_style.set_corner_radius_all(DesignTokens.RADIUS_BUTTON)  # 24
	timer_style.content_margin_left = 16
	timer_style.content_margin_right = 16
	timer_style.content_margin_top = 6
	timer_style.content_margin_bottom = 6
	timer_panel.add_theme_stylebox_override("panel", timer_style)
	top_bar.add_child(timer_panel)

	_hud_timer_label = Label.new()
	_hud_timer_label.name = "TimerLabel"
	_hud_timer_label.text = "3:00"
	_hud_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_timer_label.custom_minimum_size = Vector2(72, 0)
	_hud_timer_label.add_theme_font_size_override("font_size", 26)
	_hud_timer_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_extrabold:
		_hud_timer_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
	timer_panel.add_child(_hud_timer_label)

	# === DOG STAGE SPACER (flex to push remaining content down) ===
	var stage_spacer := Control.new()
	stage_spacer.name = "StageSpacer"
	stage_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stage_spacer)

	# === GUARD LEGEND OVERLAY (top-right of stage area, compact) ===
	_hud_guard_legend = DGCGuardLegend.new()
	_hud_guard_legend.name = "GuardLegend"
	_hud_guard_legend.compact = true
	_hud_guard_legend.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hud_guard_legend.offset_left = -170.0
	_hud_guard_legend.offset_top = 60.0
	_hud_guard_legend.offset_right = -12.0
	_hud_guard_legend.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hud.add_child(_hud_guard_legend)

	# === FACT CALLOUT (below stage) ===
	var fact_panel := PanelContainer.new()
	fact_panel.name = "FactCallout"
	var fact_style := StyleBoxFlat.new()
	fact_style.bg_color = DesignTokens.BLUE_PANEL
	fact_style.border_color = DesignTokens.BLUE_LINE
	fact_style.set_border_width_all(DesignTokens.BORDER_THIN)
	fact_style.set_corner_radius_all(DesignTokens.RADIUS_PANEL)
	fact_style.content_margin_left = 16
	fact_style.content_margin_right = 16
	fact_style.content_margin_top = 10
	fact_style.content_margin_bottom = 10
	fact_panel.add_theme_stylebox_override("panel", fact_style)

	var fact_margin := MarginContainer.new()
	fact_margin.add_theme_constant_override("margin_left", 18)
	fact_margin.add_theme_constant_override("margin_right", 18)
	fact_margin.add_theme_constant_override("margin_top", 12)
	fact_margin.add_theme_constant_override("margin_bottom", 0)
	fact_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fact_margin.add_child(fact_panel)
	root.add_child(fact_margin)

	var fact_hbox := HBoxContainer.new()
	fact_hbox.add_theme_constant_override("separation", 4)
	fact_panel.add_child(fact_hbox)

	_hud_fact_prefix_label = Label.new()
	_hud_fact_prefix_label.text = "Did you know? "
	_hud_fact_prefix_label.add_theme_font_size_override("font_size", 14)
	_hud_fact_prefix_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_body_extrabold:
		_hud_fact_prefix_label.add_theme_font_override("font", DesignTokens.font_body_extrabold)
	fact_hbox.add_child(_hud_fact_prefix_label)

	_hud_fact_text_label = Label.new()
	_hud_fact_text_label.text = ""
	_hud_fact_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_fact_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_fact_text_label.add_theme_font_size_override("font_size", 14)
	_hud_fact_text_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_semibold:
		_hud_fact_text_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
	fact_hbox.add_child(_hud_fact_text_label)

	# Set initial fact from breed data
	if _breed_data and _breed_data.grooming_facts.size() > 0:
		_hud_fact_text_label.text = _breed_data.grooming_facts[0]

	# === TOOL BAR: row of DGCToolButton ===
	var toolbar_margin := MarginContainer.new()
	toolbar_margin.name = "ToolbarMargin"
	toolbar_margin.add_theme_constant_override("margin_left", 18)
	toolbar_margin.add_theme_constant_override("margin_right", 18)
	toolbar_margin.add_theme_constant_override("margin_top", 14)
	toolbar_margin.add_theme_constant_override("margin_bottom", 0)
	root.add_child(toolbar_margin)

	var toolbar_scroll := ScrollContainer.new()
	toolbar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	toolbar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	toolbar_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_margin.add_child(toolbar_scroll)

	var toolbar_hbox := HBoxContainer.new()
	toolbar_hbox.name = "ToolbarHBox"
	toolbar_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar_hbox.add_theme_constant_override("separation", 10)
	toolbar_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_scroll.add_child(toolbar_hbox)

	# Build tool buttons from ToolSystem
	if _tool_system:
		var tools := _tool_system.get_available_tools()
		tools.sort_custom(func(a: ToolData, b: ToolData) -> bool:
			if a.tool_type != b.tool_type:
				return a.tool_type < b.tool_type
			return a.guard_size < b.guard_size
		)
		for tool_data in tools:
			var tb := DGCToolButton.new()
			tb.glyph = _get_tool_glyph(tool_data)
			tb.label = _get_tool_short_label(tool_data)
			tb.selected = false
			tb.tool_selected.connect(_on_dgc_tool_pressed.bind(tool_data))
			toolbar_hbox.add_child(tb)
			_tool_buttons[tool_data.resource_path] = tb

	# === BOTTOM ACTION BUTTON ===
	var action_margin := MarginContainer.new()
	action_margin.name = "ActionMargin"
	action_margin.add_theme_constant_override("margin_left", 18)
	action_margin.add_theme_constant_override("margin_right", 18)
	action_margin.add_theme_constant_override("margin_top", 0)
	action_margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(action_margin)

	_hud_done_button = DGCButton.new()
	_hud_done_button.name = "ActionButton"
	_hud_done_button.text = "Finish Early"
	_hud_done_button.variant = DGCButton.Variant.PRIMARY
	_hud_done_button.size = DGCButton.Size.MD
	_hud_done_button.block = true
	_hud_done_button.visible = false
	_hud_done_button.pressed.connect(_finish_grooming)
	action_margin.add_child(_hud_done_button)

	# -- Instruction label (center screen, semi-transparent) --
	_hud_instruction_label = Label.new()
	_hud_instruction_label.text = "Select a tool below, then drag across the dog to groom!"
	_hud_instruction_label.add_theme_font_size_override("font_size", 30)
	_hud_instruction_label.add_theme_color_override("font_color", Color(DesignTokens.INK.r, DesignTokens.INK.g, DesignTokens.INK.b, 0.85))
	if DesignTokens.font_body_bold:
		_hud_instruction_label.add_theme_font_override("font", DesignTokens.font_body_bold)
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


## Get a glyph/emoji for a tool type.
func _get_tool_glyph(tool_data: ToolData) -> String:
	match tool_data.tool_type:
		ToolData.ToolType.CLIPPER:
			return "\u2702\uFE0F"
		ToolData.ToolType.BRUSH:
			return "\U0001FAA5"
		ToolData.ToolType.DRYER:
			return "\U0001F4A8"
		ToolData.ToolType.SCISSORS:
			return "\u2700"
		ToolData.ToolType.NAIL_TRIMMER:
			return "\U0001F485"
		ToolData.ToolType.SHAMPOO:
			return "\U0001F9F4"
		ToolData.ToolType.COLOGNE:
			return "\U0001F48E"
		ToolData.ToolType.MEDICINE:
			return "\U0001FA79"
		ToolData.ToolType.HAND_STRIP:
			return "\u270B"
	return "\U0001F527"


## Get a short label for a tool button.
func _get_tool_short_label(tool_data: ToolData) -> String:
	match tool_data.tool_type:
		ToolData.ToolType.CLIPPER:
			return tool_data.tool_name
		ToolData.ToolType.BRUSH:
			return "Brush"
		ToolData.ToolType.DRYER:
			return "Dryer"
		ToolData.ToolType.SCISSORS:
			return "Scissors"
		ToolData.ToolType.NAIL_TRIMMER:
			return "Nails"
		ToolData.ToolType.SHAMPOO:
			return "Shampoo"
		ToolData.ToolType.COLOGNE:
			return "Cologne"
		ToolData.ToolType.MEDICINE:
			return "Meds"
		ToolData.ToolType.HAND_STRIP:
			return "Strip"
	return tool_data.tool_name


## Handle DGCToolButton press — select the tool via ToolSystem.
func _on_dgc_tool_pressed(tool_data: ToolData) -> void:
	if _tool_system:
		_tool_system.select_tool(tool_data)
	if _input_handler:
		_input_handler.set_active_tool(tool_data)


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
		# Highlight the matching DGCToolButton, deselect others
		for path in _tool_buttons:
			var tb: DGCToolButton = _tool_buttons[path]
			tb.selected = (path == td.resource_path)
			if tb.selected:
				_active_tool_button = tb
	else:
		# Deselect all
		for path in _tool_buttons:
			_tool_buttons[path].selected = false
		_active_tool_button = null
	# Dismiss instruction on first tool selection
	_dismiss_instruction()


func _on_hud_zone_groomed(_zone_id: String, _tool_data: Resource) -> void:
	if _breed_data == null:
		return
	var progress := _grooming_controller.get_grooming_progress()
	var total: int = _breed_data.grooming_zones.size()
	var done: int = int(progress * total)

	# Update DGCProgressBar
	if _hud_progress_bar:
		_hud_progress_bar.value = progress * 100.0
		_hud_progress_bar.label_text = "%d/%d zones" % [done, total]

	# Update fact callout with a random fact on each zone groomed
	if _breed_data.grooming_facts.size() > 0 and _hud_fact_text_label:
		_hud_fact_text_label.text = _breed_data.grooming_facts[randi() % _breed_data.grooming_facts.size()]

	# Show/update action button
	if done >= 1 and _hud_done_button and not _hud_done_button.visible:
		_hud_done_button.visible = true
	# Update button text based on completion
	if _hud_done_button:
		if progress >= 1.0:
			_hud_done_button.text = "Present to Judges"
		else:
			_hud_done_button.text = "Finish Early"


var _prev_coin_value: int = -1

func _on_hud_currency_changed(_new_amount: int, _delta: int) -> void:
	var new_coins: int = SaveManager.data.get("currency", 0)
	if _hud_coin_balance:
		_hud_coin_balance.amount = new_coins
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

		# Warning state at <= 30 seconds: coral color + pulse
		if seconds_remaining <= 30.0:
			_hud_timer_label.add_theme_color_override("font_color", DesignTokens.CORAL)
			if not _timer_warning_active:
				_timer_warning_active = true
				_start_timer_pulse()
		else:
			_hud_timer_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)


var _timer_pulse_tween: Tween = null

func _start_timer_pulse() -> void:
	if _hud_timer_label and _timer_pulse_tween == null:
		_hud_timer_label.pivot_offset = _hud_timer_label.size / 2.0
		_timer_pulse_tween = _hud_timer_label.create_tween().set_loops()
		_timer_pulse_tween.tween_property(_hud_timer_label, "scale", Vector2(DesignTokens.PULSE_SCALE, DesignTokens.PULSE_SCALE), DesignTokens.DUR_PULSE).set_trans(Tween.TRANS_SINE)
		_timer_pulse_tween.tween_property(_hud_timer_label, "scale", Vector2.ONE, DesignTokens.DUR_PULSE).set_trans(Tween.TRANS_SINE)

func _on_timer_warning(_seconds_remaining: float) -> void:
	# Timer warning is now handled in _on_timer_tick at <= 30s threshold
	pass


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
	if _hud_guard_legend:
		_hud_guard_legend.visible = dog_model.guide_overlay_visible if dog_model else false


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
