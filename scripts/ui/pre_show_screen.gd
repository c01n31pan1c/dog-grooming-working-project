## PreShowScreen -- Pre-show briefing screen using DGC design components.
## Displays competition details, judges, and allows reveal + start grooming.
## Layout: ScreenHeader | Scrollable content (name, badge, details panel,
## judge panel with DGCJudgeCard, hint text) | Start Grooming button.
extends Control

## Competition data loaded from transition context.
var _competition_data: CompetitionData = null

## Which judge indices have been revealed (local tracking).
var _revealed_judges: Array[int] = []

## UI references built in _ready.
var _scroll_container: ScrollContainer
var _details_panel: DGCPanel
var _judge_container: VBoxContainer
var _start_button: DGCButton
var _back_button: DGCIconButton
var _fee_coin_balance: DGCCoinBalance
var _judge_cards: Array[DGCJudgeCard] = []
var _comp_name_label: Label
var _tier_badge: DGCBadge


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

	_build_ui()
	_populate()


## ---- UI Construction ----

func _build_ui() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.color = DesignTokens.BLUE_SKY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Root VBox fills entire screen
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# --- ScreenHeader: back button + "PRE-SHOW" title + spacer ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", DesignTokens.SPACE[4])
	header.custom_minimum_size = Vector2(0, DesignTokens.HIT_LG)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", DesignTokens.PAD_SCREEN_SM)
	header_margin.add_theme_constant_override("margin_right", DesignTokens.PAD_SCREEN_SM)
	header_margin.add_theme_constant_override("margin_top", DesignTokens.SPACE[3])
	header_margin.add_theme_constant_override("margin_bottom", 0)
	header_margin.add_child(header)
	root_vbox.add_child(header_margin)

	_back_button = DGCIconButton.new()
	_back_button.glyph = "\u2039"
	_back_button.variant = DGCIconButton.Variant.GHOST
	_back_button.button_size = DesignTokens.HIT_MD
	_back_button.pressed.connect(_on_back_pressed)
	header.add_child(_back_button)

	var title_label := Label.new()
	title_label.text = "PRE-SHOW"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", DesignTokens.FS_H1)
	title_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_extrabold:
		title_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
	header.add_child(title_label)

	# Spacer to balance back button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(DesignTokens.HIT_MD, 0)
	header.add_child(spacer)

	# --- Scrollable content area ---
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(_scroll_container)

	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", DesignTokens.PAD_SCREEN_SM + 2)
	content_margin.add_theme_constant_override("margin_right", DesignTokens.PAD_SCREEN_SM + 2)
	content_margin.add_theme_constant_override("margin_top", DesignTokens.SPACE[4])
	content_margin.add_theme_constant_override("margin_bottom", DesignTokens.SPACE[4])
	_scroll_container.add_child(content_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", DesignTokens.SPACE[4])
	content_margin.add_child(content_vbox)

	# (a) Competition header -- centered name + tier badge
	var comp_header := VBoxContainer.new()
	comp_header.add_theme_constant_override("separation", DesignTokens.SPACE[2])
	comp_header.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_child(comp_header)

	_comp_name_label = Label.new()
	_comp_name_label.name = "CompNameLabel"
	_comp_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_comp_name_label.add_theme_font_size_override("font_size", 30)
	_comp_name_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_extrabold:
		_comp_name_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
	comp_header.add_child(_comp_name_label)

	var badge_center := CenterContainer.new()
	comp_header.add_child(badge_center)

	_tier_badge = DGCBadge.new()
	_tier_badge.name = "TierBadge"
	_tier_badge.tone = DGCBadge.Tone.BLUE
	badge_center.add_child(_tier_badge)

	# (b) Details Panel
	_details_panel = DGCPanel.new()
	_details_panel.name = "DetailsPanel"
	content_vbox.add_child(_details_panel)

	# (c) Judge Panel section
	var judge_section := VBoxContainer.new()
	judge_section.add_theme_constant_override("separation", DesignTokens.SPACE[3])
	content_vbox.add_child(judge_section)

	var judge_heading := Label.new()
	judge_heading.text = "Judge Panel"
	judge_heading.add_theme_font_size_override("font_size", 22)
	judge_heading.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_bold:
		judge_heading.add_theme_font_override("font", DesignTokens.font_display_bold)
	judge_section.add_child(judge_heading)

	_judge_container = VBoxContainer.new()
	_judge_container.add_theme_constant_override("separation", DesignTokens.SPACE[3])
	judge_section.add_child(_judge_container)

	var hint_label := Label.new()
	hint_label.text = "Reveal a judge's bias to groom for their taste."
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL - 6)
	hint_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)
	if DesignTokens.font_body_semibold:
		hint_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
	judge_section.add_child(hint_label)

	# Bottom spacer in scroll area
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, DesignTokens.SPACE[3])
	content_vbox.add_child(bottom_spacer)

	# --- Bottom: Start Grooming button ---
	var button_margin := MarginContainer.new()
	button_margin.add_theme_constant_override("margin_left", DesignTokens.PAD_SCREEN_SM + 2)
	button_margin.add_theme_constant_override("margin_right", DesignTokens.PAD_SCREEN_SM + 2)
	button_margin.add_theme_constant_override("margin_top", 0)
	button_margin.add_theme_constant_override("margin_bottom", DesignTokens.PAD_SCREEN_LG - 12)
	root_vbox.add_child(button_margin)

	_start_button = DGCButton.new()
	_start_button.text = "Start Grooming"
	_start_button.variant = DGCButton.Variant.PRIMARY
	_start_button.button_size = DGCButton.Size.LG
	_start_button.block = true
	_start_button.pressed.connect(_on_start_pressed)
	button_margin.add_child(_start_button)


## ---- Populate with competition data ----

func _populate() -> void:
	if _competition_data == null:
		return

	# Competition name
	if _comp_name_label:
		_comp_name_label.text = _competition_data.competition_name

	# Tier badge
	if _tier_badge:
		_tier_badge.label_text = _competition_data.get_tier_name()

	# Details panel content
	_populate_details()

	# Judges
	_populate_judges()

	# Start button affordability
	_update_start_button()


func _populate_details() -> void:
	# The DGCPanel auto-creates a ContentVBox in its _ready.
	# We need to wait for that before adding detail rows.
	await _details_panel.ready
	_add_details_content()


func _add_details_content() -> void:
	var content_vbox: VBoxContainer = null
	# DGCPanel wraps children in ContentVBox
	for child in _details_panel.get_children():
		if child is VBoxContainer:
			content_vbox = child as VBoxContainer
			break

	if content_vbox == null:
		content_vbox = VBoxContainer.new()
		_details_panel.add_child(content_vbox)

	content_vbox.add_theme_constant_override("separation", DesignTokens.SPACE[2])

	var breed_name: String = _competition_data.breed.breed_name if _competition_data.breed else "TBD"

	# Breed row
	var breed_row := _make_detail_row("Breed", breed_name)
	content_vbox.add_child(breed_row)

	# Time limit row
	var time_str := "%ds" % int(_competition_data.time_limit_seconds)
	var time_row := _make_detail_row("Time limit", time_str)
	content_vbox.add_child(time_row)

	# Entry fee row (with CoinBalance compact)
	var fee_row := HBoxContainer.new()
	fee_row.add_theme_constant_override("separation", 0)

	var fee_key := Label.new()
	fee_key.text = "Entry fee"
	fee_key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fee_key.add_theme_font_size_override("font_size", DesignTokens.FS_BODY - 8)
	fee_key.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_bold:
		fee_key.add_theme_font_override("font", DesignTokens.font_body_bold)
	fee_row.add_child(fee_key)

	if _competition_data.entry_fee > 0:
		_fee_coin_balance = DGCCoinBalance.new()
		_fee_coin_balance.amount = _competition_data.entry_fee
		_fee_coin_balance.compact = true
		fee_row.add_child(_fee_coin_balance)
	else:
		var free_label := Label.new()
		free_label.text = "FREE"
		free_label.add_theme_font_size_override("font_size", DesignTokens.FS_BODY - 8)
		free_label.add_theme_color_override("font_color", DesignTokens.MINT)
		if DesignTokens.font_body_extrabold:
			free_label.add_theme_font_override("font", DesignTokens.font_body_extrabold)
		fee_row.add_child(free_label)

	content_vbox.add_child(fee_row)


func _make_detail_row(key: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()

	var key_label := Label.new()
	key_label.text = key
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_label.add_theme_font_size_override("font_size", DesignTokens.FS_BODY - 8)
	key_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_bold:
		key_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	row.add_child(key_label)

	var val_label := Label.new()
	val_label.text = value
	val_label.add_theme_font_size_override("font_size", DesignTokens.FS_BODY - 8)
	val_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_body_extrabold:
		val_label.add_theme_font_override("font", DesignTokens.font_body_extrabold)
	row.add_child(val_label)

	return row


func _populate_judges() -> void:
	# Clear existing
	for child in _judge_container.get_children():
		child.queue_free()
	_judge_cards.clear()

	for i in range(_competition_data.judges.size()):
		var judge: JudgeData = _competition_data.judges[i]
		var card := DGCJudgeCard.new()
		card.judge_name = judge.judge_name
		card.reveal_cost = judge.reveal_cost

		var is_revealed := i in _revealed_judges
		if is_revealed:
			card.revealed = true
			card.preference = judge.preferred_style

		# Connect reveal signal
		var judge_index := i
		card.reveal_pressed.connect(_on_reveal_pressed.bind(judge_index))

		_judge_container.add_child(card)
		_judge_cards.append(card)


## ---- Actions ----

func _on_reveal_pressed(judge_index: int) -> void:
	if judge_index in _revealed_judges:
		return

	var judge: JudgeData = _competition_data.judges[judge_index]
	var coins: int = SaveManager.data.get("currency", 0)

	if coins < judge.reveal_cost:
		return

	# Deduct coins
	var new_amount: int = coins - judge.reveal_cost
	SaveManager.data["currency"] = new_amount
	EventBus.currency_changed.emit(new_amount, -judge.reveal_cost)

	# Track reveal
	_revealed_judges.append(judge_index)

	# Update the specific card
	if judge_index < _judge_cards.size():
		_judge_cards[judge_index].revealed = true
		_judge_cards[judge_index].preference = judge.preferred_style

	_update_start_button()


func _on_start_pressed() -> void:
	if _competition_data == null:
		return

	var coins: int = SaveManager.data.get("currency", 0)
	if coins < _competition_data.entry_fee:
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


## ---- Helpers ----

func _update_start_button() -> void:
	var coins: int = SaveManager.data.get("currency", 0)
	var can_afford := coins >= _competition_data.entry_fee
	_start_button.disabled = not can_afford
