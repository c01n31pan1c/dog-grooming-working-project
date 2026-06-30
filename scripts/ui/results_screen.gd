## ResultsScreen -- Standalone results screen after a competition.
## Full-height centered layout: trophy, placement badge (pulsing gold),
## score with count-up animation, judge scores panel, reward, action buttons.
extends Control

## Results data loaded from transition context.
var _competition_data: CompetitionData = null
var _panel_result: Dictionary = {}
var _score_breakdown: Dictionary = {}
var _placement: int = 4
var _reward: int = 0

## UI references built in _ready.
var _score_label: Label
var _judge_score_rows: Array[Control] = []
var _score_tween: Tween


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.COMPETITION_RESULTS

	# Load results from transition context
	var context: Dictionary = GameManager.transition_context
	if context.has("competition_data"):
		_competition_data = context["competition_data"] as CompetitionData
	_panel_result = context.get("panel_result", {})
	_score_breakdown = context.get("score_breakdown", {})
	_placement = context.get("placement", 4)
	_reward = context.get("reward", 0)

	_build_ui()
	_animate_results()


func _build_ui() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.color = DesignTokens.BLUE_SKY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered content container
	var center_scroll := ScrollContainer.new()
	center_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(center_scroll)

	var outer_margin := MarginContainer.new()
	outer_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_margin.add_theme_constant_override("margin_left", DesignTokens.PAD_SCREEN_LG - 12)
	outer_margin.add_theme_constant_override("margin_right", DesignTokens.PAD_SCREEN_LG - 12)
	outer_margin.add_theme_constant_override("margin_top", DesignTokens.PAD_SCREEN_LG)
	outer_margin.add_theme_constant_override("margin_bottom", DesignTokens.PAD_SCREEN_LG)
	center_scroll.add_child(outer_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", DesignTokens.SPACE[5])
	outer_margin.add_child(main_vbox)

	# (a) Trophy emoji (64px)
	var trophy_label := Label.new()
	trophy_label.text = "\U0001F3C6"
	trophy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy_label.add_theme_font_size_override("font_size", 64)
	if DesignTokens.font_display_bold:
		trophy_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	main_vbox.add_child(trophy_label)

	# (b) Pulsing gold Badge: placement text
	var badge_center := CenterContainer.new()
	main_vbox.add_child(badge_center)

	var placement_badge := DGCBadge.new()
	placement_badge.tone = DGCBadge.Tone.GOLD
	placement_badge.pulse = true
	placement_badge.label_text = _get_placement_text()
	badge_center.add_child(placement_badge)

	# (c) Score block
	var score_block := VBoxContainer.new()
	score_block.add_theme_constant_override("separation", DesignTokens.SPACE[1])
	score_block.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(score_block)

	var score_heading := Label.new()
	score_heading.text = "Total Score"
	score_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_heading.add_theme_font_size_override("font_size", DesignTokens.FS_BODY - 8)
	score_heading.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_bold:
		score_heading.add_theme_font_override("font", DesignTokens.font_body_bold)
	score_block.add_child(score_heading)

	_score_label = Label.new()
	_score_label.text = "0.0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 72)
	_score_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_extrabold:
		_score_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
	score_block.add_child(_score_label)

	# (d) Judge scores Panel
	var judge_results: Array = _panel_result.get("judge_results", [])
	if judge_results.size() > 0:
		var judge_panel := DGCPanel.new()
		main_vbox.add_child(judge_panel)
		# Wait for panel to build its internal structure
		await judge_panel.ready
		var panel_content: VBoxContainer = null
		for child in judge_panel.get_children():
			if child is VBoxContainer:
				panel_content = child as VBoxContainer
				break
		if panel_content == null:
			panel_content = VBoxContainer.new()
			judge_panel.add_child(panel_content)

		panel_content.add_theme_constant_override("separation", DesignTokens.SPACE[3])

		for jr in judge_results:
			var row := _make_judge_score_row(
				jr.get("judge_name", "Judge"),
				jr.get("weighted_score", 0.0)
			)
			row.modulate.a = 0.0  # Start invisible for stagger
			panel_content.add_child(row)
			_judge_score_rows.append(row)

	# (e) Reward line
	if _reward > 0:
		var reward_row := HBoxContainer.new()
		reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
		reward_row.add_theme_constant_override("separation", DesignTokens.SPACE[2])
		main_vbox.add_child(reward_row)

		var reward_label := Label.new()
		reward_label.text = "Reward"
		reward_label.add_theme_font_size_override("font_size", DesignTokens.FS_BODY - 8)
		reward_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
		if DesignTokens.font_body_bold:
			reward_label.add_theme_font_override("font", DesignTokens.font_body_bold)
		reward_row.add_child(reward_label)

		var reward_coins := DGCCoinBalance.new()
		reward_coins.amount = _reward
		reward_coins.compact = true
		reward_row.add_child(reward_coins)

	# (f) Two action buttons
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", DesignTokens.SPACE[3])
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn_margin := MarginContainer.new()
	btn_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_margin.add_theme_constant_override("margin_top", DesignTokens.SPACE[2])
	btn_margin.add_child(button_row)
	main_vbox.add_child(btn_margin)

	var salon_btn := DGCButton.new()
	salon_btn.text = "Salon"
	salon_btn.variant = DGCButton.Variant.SECONDARY
	salon_btn.button_size = DGCButton.Size.MD
	salon_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salon_btn.pressed.connect(_on_salon_pressed)
	button_row.add_child(salon_btn)

	var next_btn := DGCButton.new()
	next_btn.text = "Next Show"
	next_btn.variant = DGCButton.Variant.PRIMARY
	next_btn.button_size = DGCButton.Size.MD
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_btn.pressed.connect(_on_next_show_pressed)
	button_row.add_child(next_btn)


func _get_placement_text() -> String:
	match _placement:
		1: return "1ST PLACE"
		2: return "2ND PLACE"
		3: return "3RD PLACE"
		_: return "FINISHED"


func _make_judge_score_row(judge_name: String, score: float) -> HBoxContainer:
	var row := HBoxContainer.new()

	var name_label := Label.new()
	name_label.text = judge_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_bold:
		name_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	row.add_child(name_label)

	var score_label := Label.new()
	score_label.text = "%.1f" % score
	score_label.add_theme_font_size_override("font_size", 17)
	score_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_body_extrabold:
		score_label.add_theme_font_override("font", DesignTokens.font_body_extrabold)
	row.add_child(score_label)

	return row


## ---- Score count-up animation ----

func _animate_results() -> void:
	var panel_score: float = _panel_result.get("panel_score", 0.0)

	# Count up total score from 0 to final over DUR_SCORE (1.5s)
	UIAnimations.number_ticker(
		_score_label, 0.0, panel_score,
		DesignTokens.DUR_SCORE, "%.1f", 0.3
	)

	# Stagger judge score rows (100ms delay each)
	for i in range(_judge_score_rows.size()):
		var row := _judge_score_rows[i]
		var delay: float = 0.3 + i * DesignTokens.DUR_STAGGER
		_stagger_fade_in(row, delay)

	# Celebration for 1st place
	if _placement == 1:
		var celebration_delay := 0.3 + DesignTokens.DUR_SCORE + 0.3
		get_tree().create_timer(celebration_delay).timeout.connect(func():
			var center := size * 0.5
			UIAnimations.celebration(self, center, 12)
		)


func _stagger_fade_in(node: Control, delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", 1.0, DesignTokens.DUR_ENTRANCE_SM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## ---- Navigation ----

func _on_salon_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)


func _on_next_show_pressed() -> void:
	GameManager.change_state(GameManager.GameState.COMPETITION)
