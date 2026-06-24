## CompetitionSelect — UI for browsing and entering competitions.
## Loads real CompetitionData .tres resources from resources/competitions/.
## Displays available competitions filtered by player tier, with detail panel.
extends Control

const COMPETITIONS_DIR := "res://resources/competitions/"

@onready var card_container: VBoxContainer = %CardContainer
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_tier_label: Label = %DetailTierLabel
@onready var detail_breed_label: Label = %DetailBreedLabel
@onready var detail_time_label: Label = %DetailTimeLabel
@onready var detail_fee_label: Label = %DetailFeeLabel
@onready var detail_judges_label: Label = %DetailJudgesLabel
@onready var detail_description_label: Label = %DetailDescriptionLabel
@onready var enter_button: Button = %EnterButton
@onready var back_button: Button = %BackButton
@onready var insufficient_funds_label: Label = %InsufficientFundsLabel

## Currently selected CompetitionData resource.
var _selected_competition: CompetitionData = null

## All loaded competition resources.
var _competitions: Array[CompetitionData] = []


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.COMPETITION
	detail_panel.visible = false
	insufficient_funds_label.visible = false

	enter_button.pressed.connect(_on_enter_pressed)
	back_button.pressed.connect(_on_back_pressed)
	UIAnimations.setup_button_juice(enter_button)
	UIAnimations.setup_button_juice(back_button)

	_load_competitions()
	_populate_competition_cards()


func _load_competitions() -> void:
	_competitions.clear()
	var dir := DirAccess.open(COMPETITIONS_DIR)
	if dir == null:
		push_warning("CompetitionSelect: Could not open competitions directory: %s" % COMPETITIONS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var res_path := COMPETITIONS_DIR + file_name.replace(".remap", "")
			var res := ResourceLoader.load(res_path)
			if res is CompetitionData:
				_competitions.append(res as CompetitionData)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by tier then name
	_competitions.sort_custom(func(a: CompetitionData, b: CompetitionData) -> bool:
		if a.tier != b.tier:
			return a.tier < b.tier
		return a.competition_name < b.competition_name
	)


func _populate_competition_cards() -> void:
	# Clear existing cards
	for child in card_container.get_children():
		child.queue_free()

	var current_tier: int = SaveManager.data.get("current_tier", 0)

	for comp in _competitions:
		var card := _create_competition_card(comp, current_tier)
		card_container.add_child(card)


func _create_competition_card(comp: CompetitionData, current_tier: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	# Left side: tier badge
	var tier_badge := Label.new()
	tier_badge.text = comp.get_tier_name()
	tier_badge.custom_minimum_size = Vector2(80, 48)
	tier_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Color-code tier badges
	match comp.tier:
		0: tier_badge.add_theme_color_override("font_color", Color(0.71, 0.918, 0.843))  # Local = mint
		1: tier_badge.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))  # Regional = blue
		2: tier_badge.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))  # National = gold
		_: tier_badge.add_theme_color_override("font_color", Color(0.239, 0.239, 0.361))
	hbox.add_child(tier_badge)

	# Center: name + breed + time
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = comp.competition_name
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.239, 0.239, 0.361))
	info_vbox.add_child(name_label)

	var breed_name: String = comp.breed.breed_name if comp.breed else "TBD"
	var breed_label := Label.new()
	breed_label.text = "Breed: %s  |  Time: %ds" % [breed_name, int(comp.time_limit_seconds)]
	breed_label.add_theme_font_size_override("font_size", 20)
	breed_label.add_theme_color_override("font_color", Color(0.204, 0.286, 0.369))
	info_vbox.add_child(breed_label)

	hbox.add_child(info_vbox)

	# Right side: entry fee
	var fee_label := Label.new()
	if comp.entry_fee > 0:
		fee_label.text = "%d coins" % comp.entry_fee
		fee_label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	else:
		fee_label.text = "FREE"
		fee_label.add_theme_color_override("font_color", Color(0.71, 0.918, 0.843))
	fee_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fee_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(fee_label)

	# Handle locked state (tier too high)
	var is_locked: bool = comp.tier > current_tier
	if is_locked:
		card.modulate = Color(0.7, 0.75, 0.8, 0.6)
		var lock_label := Label.new()
		lock_label.text = "Requires %s tier" % comp.get_tier_name()
		lock_label.add_theme_font_size_override("font_size", 16)
		lock_label.add_theme_color_override("font_color", Color(1.0, 0.549, 0.486))
		info_vbox.add_child(lock_label)

	# Make card clickable via gui_input
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and not is_locked:
			_on_competition_card_pressed(comp)
	)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not is_locked else Control.CURSOR_ARROW

	return card


func _on_competition_card_pressed(comp: CompetitionData) -> void:
	_selected_competition = comp
	_show_detail_panel(comp)


func _show_detail_panel(comp: CompetitionData) -> void:
	detail_panel.visible = true
	detail_name_label.text = comp.competition_name
	detail_tier_label.text = "Tier: %s" % comp.get_tier_name()

	if comp.breed:
		detail_breed_label.text = "Breed: %s" % comp.breed.breed_name
	else:
		detail_breed_label.text = "Breed: TBD"

	detail_time_label.text = "Time Limit: %ds" % int(comp.time_limit_seconds)

	if comp.entry_fee > 0:
		detail_fee_label.text = "Entry Fee: %d coins" % comp.entry_fee
	else:
		detail_fee_label.text = "Entry Fee: FREE"

	# Show judge names
	var judge_names: PackedStringArray = PackedStringArray()
	for judge in comp.judges:
		judge_names.append(judge.judge_name)
	detail_judges_label.text = "Judges: %s" % ", ".join(judge_names)

	# Build description from breed info
	if comp.breed:
		detail_description_label.text = "Groom a %s to breed standard. %d zones to complete." % [
			comp.breed.breed_name,
			comp.breed.grooming_zones.size(),
		]
	else:
		detail_description_label.text = ""

	# Check funds
	var coins: int = SaveManager.data.get("currency", 0)
	var can_afford := coins >= comp.entry_fee
	enter_button.disabled = not can_afford
	insufficient_funds_label.visible = not can_afford
	if not can_afford:
		insufficient_funds_label.text = "Need %d more coins" % (comp.entry_fee - coins)


func _on_enter_pressed() -> void:
	if _selected_competition == null:
		return

	# Transition to pre-show screen with competition context
	GameManager.change_state(GameManager.GameState.PRE_SHOW, {
		"competition_data": _selected_competition,
	})


func _on_back_pressed() -> void:
	if detail_panel.visible:
		detail_panel.visible = false
	else:
		GameManager.change_state(GameManager.GameState.SALON)
