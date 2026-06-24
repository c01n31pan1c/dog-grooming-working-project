## PreShowScreen — Intermediate screen between competition select and grooming arena.
## Displays competition details, breed info, and allows players to spend coins
## to reveal judge preferences before committing to groom.
extends Control

## Colors — pastel palette
const COLOR_BG := Color(0.831, 0.914, 0.969, 1.0)          # Light blue #D4E9F7
const COLOR_PANEL := Color(0.941, 0.969, 1.0, 0.95)         # White-blue #F0F7FF
const COLOR_TEXT := Color(0.173, 0.243, 0.314, 1.0)         # Navy #2C3E50
const COLOR_YELLOW := Color(1.0, 0.878, 0.4, 1.0)           # Pastel yellow #FFE066
const COLOR_YELLOW_BORDER := Color(1.0, 0.843, 0.0, 1.0)    # Stronger yellow
const COLOR_MINT := Color(0.71, 0.918, 0.843, 1.0)          # Mint green #B5EAD7
const COLOR_CORAL := Color(1.0, 0.549, 0.486, 1.0)          # Coral for warnings
const COLOR_HIDDEN := Color(0.6, 0.65, 0.7, 1.0)            # Muted for hidden info
const COLOR_SEPARATOR := Color(0.784, 0.839, 0.894, 0.5)

## Competition data loaded from transition context.
var _competition_data: CompetitionData = null

## Which judge indices have been revealed (local tracking).
var _revealed_judges: Array[int] = []

## UI references built in _ready.
var _header_name_label: Label
var _header_tier_label: Label
var _header_breed_label: Label
var _breed_info_panel: PanelContainer
var _time_label: Label
var _fee_label: Label
var _balance_label: Label
var _judge_container: VBoxContainer
var _start_button: Button
var _back_button: Button
var _insufficient_label: Label

## Per-judge UI elements for updating after reveal.
var _judge_cards: Array[Dictionary] = []


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PRE_SHOW

	# Load competition data from transition context
	var context: Dictionary = GameManager.transition_context
	if context.has("competition_data"):
		_competition_data = context["competition_data"] as CompetitionData

	if _competition_data == null:
		push_error("PreShowScreen: No competition_data in transition context.")
		GameManager.change_state(GameManager.GameState.COMPETITION)
		return

	# Listen for currency changes
	EventBus.currency_changed.connect(_on_currency_changed)

	_build_ui()
	_populate()


## ---- UI Construction (programmatic, matching codebase style) ----

func _build_ui() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main scroll container
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40.0
	scroll.offset_right = -40.0
	scroll.offset_top = 20.0
	scroll.offset_bottom = -20.0
	add_child(scroll)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(main_vbox)

	# --- Header ---
	_header_name_label = _make_label("", 36, COLOR_TEXT)
	_header_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_header_name_label)

	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 24)
	main_vbox.add_child(header_row)

	_header_tier_label = _make_label("", 22, COLOR_MINT)
	header_row.add_child(_header_tier_label)

	_header_breed_label = _make_label("", 22, COLOR_TEXT)
	header_row.add_child(_header_breed_label)

	main_vbox.add_child(_make_separator())

	# --- Breed info card ---
	_breed_info_panel = _make_panel()
	main_vbox.add_child(_breed_info_panel)

	# --- Time and fee row ---
	var time_fee_row := HBoxContainer.new()
	time_fee_row.add_theme_constant_override("separation", 40)
	time_fee_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(time_fee_row)

	_time_label = _make_label("", 28, COLOR_TEXT)
	time_fee_row.add_child(_time_label)

	_fee_label = _make_label("", 28, COLOR_TEXT)
	time_fee_row.add_child(_fee_label)

	_balance_label = _make_label("", 22, COLOR_HIDDEN)
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_balance_label)

	main_vbox.add_child(_make_separator())

	# --- Judge panel header ---
	var judge_header := _make_label("Judge Panel", 28, COLOR_TEXT)
	judge_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(judge_header)

	_judge_container = VBoxContainer.new()
	_judge_container.add_theme_constant_override("separation", 12)
	main_vbox.add_child(_judge_container)

	main_vbox.add_child(_make_separator())

	# --- Insufficient funds warning ---
	_insufficient_label = _make_label("", 20, COLOR_CORAL)
	_insufficient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_insufficient_label.visible = false
	main_vbox.add_child(_insufficient_label)

	# --- Bottom buttons ---
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 32)
	main_vbox.add_child(button_row)

	_back_button = _make_button("Back", 24)
	_back_button.custom_minimum_size = Vector2(180, 56)
	_back_button.pressed.connect(_on_back_pressed)
	# Style back button more subtly
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = COLOR_PANEL
	back_style.border_color = COLOR_SEPARATOR
	back_style.set_border_width_all(2)
	back_style.set_corner_radius_all(24)
	back_style.content_margin_left = 24.0
	back_style.content_margin_right = 24.0
	back_style.content_margin_top = 12.0
	back_style.content_margin_bottom = 12.0
	_back_button.add_theme_stylebox_override("normal", back_style)
	button_row.add_child(_back_button)

	_start_button = _make_button("Start Grooming", 28)
	_start_button.custom_minimum_size = Vector2(300, 64)
	_start_button.pressed.connect(_on_start_pressed)
	button_row.add_child(_start_button)

	# Bottom spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer)


## ---- Populate with competition data ----

func _populate() -> void:
	if _competition_data == null:
		return

	# Header
	_header_name_label.text = _competition_data.competition_name
	_header_tier_label.text = _competition_data.get_tier_name()
	var breed_name: String = _competition_data.breed.breed_name if _competition_data.breed else "TBD"
	_header_breed_label.text = breed_name

	# Breed info card
	_populate_breed_card()

	# Time
	var minutes := int(_competition_data.time_limit_seconds) / 60
	var seconds := int(_competition_data.time_limit_seconds) % 60
	_time_label.text = "Time: %d:%02d" % [minutes, seconds]

	# Fee
	if _competition_data.entry_fee > 0:
		_fee_label.text = "Entry Fee: %d coins" % _competition_data.entry_fee
	else:
		_fee_label.text = "Entry Fee: FREE"

	# Balance
	_update_balance_display()

	# Judges
	_populate_judges()

	# Check affordability for start button
	_update_start_button()


func _populate_breed_card() -> void:
	# Clear existing content
	for child in _breed_info_panel.get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_breed_info_panel.add_child(vbox)

	if _competition_data.breed == null:
		var tbd := _make_label("Breed info not available", 20, COLOR_HIDDEN)
		vbox.add_child(tbd)
		return

	var breed: BreedData = _competition_data.breed

	var name_label := _make_label(breed.breed_name, 26, COLOR_TEXT)
	vbox.add_child(name_label)

	# Group and difficulty
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 20)
	vbox.add_child(info_row)

	if breed.get("breed_group") != null and breed.breed_group != "":
		var group_label := _make_label("Group: %s" % breed.breed_group, 20, COLOR_HIDDEN)
		info_row.add_child(group_label)

	# Difficulty stars
	if breed.get("difficulty") != null:
		var diff: int = breed.difficulty if breed.difficulty is int else int(breed.difficulty)
		var stars := ""
		for i in range(diff):
			stars += "★"
		for i in range(5 - diff):
			stars += "☆"
		var diff_label := _make_label("Difficulty: %s" % stars, 20, COLOR_TEXT)
		info_row.add_child(diff_label)

	# Grooming facts / preview
	if breed.get("grooming_facts") != null and breed.grooming_facts is Array:
		var facts: Array = breed.grooming_facts
		var count := mini(facts.size(), 2)
		for i in range(count):
			var fact_label := _make_label("• %s" % str(facts[i]), 18, COLOR_HIDDEN)
			fact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(fact_label)
	elif breed.get("description") != null and breed.description != "":
		var desc_label := _make_label(breed.description, 18, COLOR_HIDDEN)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)

	# Zone count
	if breed.grooming_zones.size() > 0:
		var zones_label := _make_label("%d grooming zones" % breed.grooming_zones.size(), 18, COLOR_MINT)
		vbox.add_child(zones_label)


func _populate_judges() -> void:
	# Clear existing
	for child in _judge_container.get_children():
		child.queue_free()
	_judge_cards.clear()

	for i in range(_competition_data.judges.size()):
		var judge: JudgeData = _competition_data.judges[i]
		var card := _build_judge_card(i, judge)
		_judge_container.add_child(card)


func _build_judge_card(index: int, judge: JudgeData) -> PanelContainer:
	var panel := _make_panel()
	var is_revealed := index in _revealed_judges

	if is_revealed:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(COLOR_MINT.r, COLOR_MINT.g, COLOR_MINT.b, 0.25)
		style.border_color = COLOR_MINT
		style.set_border_width_all(2)
		style.set_corner_radius_all(16)
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 16.0
		style.content_margin_bottom = 16.0
		panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Left side: judge info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	# Judge name
	var name_label := _make_label(judge.judge_name, 24, COLOR_TEXT)
	info_vbox.add_child(name_label)

	# Personality hint (one-liner derived from preferred_style + strictness)
	var hint := _get_personality_hint(judge)
	var hint_label := _make_label(hint, 18, COLOR_HIDDEN)
	info_vbox.add_child(hint_label)

	# Preferences area
	var prefs_label: Label
	if is_revealed:
		# Show scoring weights
		var accuracy_pct := int(judge.scoring_weights.get("accuracy", 0.0) * 100)
		var time_pct := int(judge.scoring_weights.get("time", 0.0) * 100)
		var style_pct := int(judge.scoring_weights.get("style", 0.0) * 100)
		prefs_label = _make_label(
			"Accuracy: %d%%  |  Time: %d%%  |  Style: %d%%" % [accuracy_pct, time_pct, style_pct],
			18, COLOR_MINT
		)
		info_vbox.add_child(prefs_label)

		var style_label := _make_label("Preferred Style: %s" % judge.preferred_style, 18, COLOR_MINT)
		info_vbox.add_child(style_label)
	else:
		prefs_label = _make_label("Preferences: Hidden", 18, COLOR_HIDDEN)
		info_vbox.add_child(prefs_label)

	# Right side: reveal button (or revealed badge)
	var right_vbox := VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)

	if is_revealed:
		var revealed_badge := _make_label("Revealed ✓", 18, COLOR_MINT)
		revealed_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(revealed_badge)
	else:
		var reveal_btn := _make_button("Reveal - %d coins" % judge.reveal_cost, 18)
		reveal_btn.custom_minimum_size = Vector2(200, 44)
		var coins: int = SaveManager.data.get("currency", 0)
		reveal_btn.disabled = coins < judge.reveal_cost
		reveal_btn.pressed.connect(_on_reveal_pressed.bind(index))
		right_vbox.add_child(reveal_btn)

	# Store references for later updates
	_judge_cards.append({
		"panel": panel,
		"index": index,
	})

	return panel


func _get_personality_hint(judge: JudgeData) -> String:
	# Build a short one-liner hint from style and strictness
	var strictness_word: String
	if judge.strictness_level >= 0.7:
		strictness_word = "Strict"
	elif judge.strictness_level >= 0.4:
		strictness_word = "Fair"
	else:
		strictness_word = "Lenient"

	return "%s & %s" % [judge.preferred_style, strictness_word]


## ---- Actions ----

func _on_reveal_pressed(judge_index: int) -> void:
	if judge_index in _revealed_judges:
		return

	var judge: JudgeData = _competition_data.judges[judge_index]
	var coins: int = SaveManager.data.get("currency", 0)

	if coins < judge.reveal_cost:
		_insufficient_label.text = "Not enough coins to reveal %s" % judge.judge_name
		_insufficient_label.visible = true
		return

	# Deduct coins
	var new_amount: int = coins - judge.reveal_cost
	SaveManager.data["currency"] = new_amount
	EventBus.currency_changed.emit(new_amount, -judge.reveal_cost)

	# Track reveal
	_revealed_judges.append(judge_index)

	# Rebuild judge cards to reflect new state
	_populate_judges()
	_update_balance_display()
	_update_start_button()

	# Hide warning if it was showing
	_insufficient_label.visible = false


func _on_start_pressed() -> void:
	if _competition_data == null:
		return

	var coins: int = SaveManager.data.get("currency", 0)
	if coins < _competition_data.entry_fee:
		_insufficient_label.text = "Not enough coins to enter!"
		_insufficient_label.visible = true
		return

	# Deduct entry fee
	if _competition_data.entry_fee > 0:
		var new_amount: int = coins - _competition_data.entry_fee
		SaveManager.data["currency"] = new_amount
		EventBus.currency_changed.emit(new_amount, -_competition_data.entry_fee)

	# Transition to grooming arena with full context
	GameManager.change_state(GameManager.GameState.GROOMING, {
		"competition_data": _competition_data,
		"mode": "competition",
		"revealed_judges": _revealed_judges.duplicate(),
	})


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.COMPETITION)


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_balance_display()
	_update_start_button()


## ---- Helpers ----

func _update_balance_display() -> void:
	var coins: int = SaveManager.data.get("currency", 0)
	_balance_label.text = "Your balance: %d coins" % coins


func _update_start_button() -> void:
	var coins: int = SaveManager.data.get("currency", 0)
	var can_afford := coins >= _competition_data.entry_fee
	_start_button.disabled = not can_afford
	if not can_afford:
		_insufficient_label.text = "Need %d more coins to enter" % (_competition_data.entry_fee - coins)
		_insufficient_label.visible = true
	else:
		_insufficient_label.visible = false


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, font_size: int = 24) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", font_size)
	# Yellow pastel button style
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_YELLOW
	normal.border_color = COLOR_YELLOW_BORDER
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(24)
	normal.content_margin_left = 24.0
	normal.content_margin_right = 24.0
	normal.content_margin_top = 12.0
	normal.content_margin_bottom = 12.0
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_YELLOW_BORDER
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.9, 0.78, 0.0, 1)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.784, 0.839, 0.894, 0.5)
	disabled.border_color = Color(0.784, 0.839, 0.894, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.6, 1))
	return btn


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_SEPARATOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	style.shadow_color = Color(0.784, 0.839, 0.894, 0.2)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SEPARATOR
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	sep.add_theme_stylebox_override("separator", style)
	return sep
