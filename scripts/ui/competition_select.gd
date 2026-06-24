## CompetitionSelect — UI for browsing and entering competitions.
## Displays available competitions for the player's current tier,
## with a scrollable card list and a detail panel.
extends Control

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

## Currently selected competition data.
var _selected_competition: Dictionary = {}

## Placeholder competition data — replaced by real data from resources later.
var _competitions: Array[Dictionary] = [
	{
		"id": "local_poodle_1",
		"name": "Poodle Puppy Cup",
		"tier": 0,
		"breed": "Poodle",
		"time_limit": 180,
		"entry_fee": 50,
		"judges": 3,
		"description": "A beginner-friendly local show. Groom a Standard Poodle to breed standard.",
		"locked": false,
		"lock_reason": "",
	},
	{
		"id": "local_terrier_1",
		"name": "Terrier Trim Trial",
		"tier": 0,
		"breed": "Yorkshire Terrier",
		"time_limit": 150,
		"entry_fee": 75,
		"judges": 3,
		"description": "Show off your terrier trimming skills at this local event.",
		"locked": false,
		"lock_reason": "",
	},
	{
		"id": "regional_golden_1",
		"name": "Golden Gala",
		"tier": 1,
		"breed": "Golden Retriever",
		"time_limit": 240,
		"entry_fee": 150,
		"judges": 5,
		"description": "A prestigious regional competition. Requires Regional tier.",
		"locked": true,
		"lock_reason": "Reach Regional tier to unlock",
	},
]


func _ready() -> void:
	detail_panel.visible = false
	insufficient_funds_label.visible = false

	enter_button.pressed.connect(_on_enter_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_populate_competition_cards()


func _populate_competition_cards() -> void:
	# Clear existing cards
	for child in card_container.get_children():
		child.queue_free()

	var current_tier: int = SaveManager.data.get("current_tier", 0)

	for comp in _competitions:
		var card := _create_competition_card(comp, current_tier)
		card_container.add_child(card)


func _create_competition_card(comp: Dictionary, _current_tier: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	# Left side: tier badge
	var tier_badge := Label.new()
	tier_badge.text = "T%d" % comp.get("tier", 0)
	tier_badge.custom_minimum_size = Vector2(48, 48)
	tier_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(tier_badge)

	# Center: name + breed + time
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = comp.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 28)
	info_vbox.add_child(name_label)

	var breed_label := Label.new()
	breed_label.text = "Breed: %s  |  Time: %ds" % [comp.get("breed", "?"), comp.get("time_limit", 0)]
	breed_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(breed_label)

	hbox.add_child(info_vbox)

	# Right side: entry fee
	var fee_label := Label.new()
	fee_label.text = "%d coins" % comp.get("entry_fee", 0)
	fee_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fee_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(fee_label)

	# Handle locked state
	var is_locked: bool = comp.get("locked", false)
	if is_locked:
		card.modulate = Color(0.5, 0.5, 0.5, 0.7)
		var lock_label := Label.new()
		lock_label.text = comp.get("lock_reason", "Locked")
		lock_label.add_theme_font_size_override("font_size", 16)
		lock_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
		info_vbox.add_child(lock_label)

	# Make card clickable via gui_input
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and not is_locked:
			_on_competition_card_pressed(comp)
	)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not is_locked else Control.CURSOR_ARROW

	return card


func _on_competition_card_pressed(comp: Dictionary) -> void:
	_selected_competition = comp
	_show_detail_panel(comp)


func _show_detail_panel(comp: Dictionary) -> void:
	detail_panel.visible = true
	detail_name_label.text = comp.get("name", "")
	detail_tier_label.text = "Tier: %d" % comp.get("tier", 0)
	detail_breed_label.text = "Breed: %s" % comp.get("breed", "")
	detail_time_label.text = "Time Limit: %ds" % comp.get("time_limit", 0)
	detail_fee_label.text = "Entry Fee: %d coins" % comp.get("entry_fee", 0)

	var judge_count: int = comp.get("judges", 3)
	detail_judges_label.text = "Judges: %s" % ("? " * judge_count).strip_edges()

	detail_description_label.text = comp.get("description", "")

	# Check funds
	var coins: int = SaveManager.data.get("currency", 0)
	var fee: int = comp.get("entry_fee", 0)
	var can_afford := coins >= fee
	enter_button.disabled = not can_afford
	insufficient_funds_label.visible = not can_afford
	if not can_afford:
		insufficient_funds_label.text = "Need %d more coins" % (fee - coins)


func _on_enter_pressed() -> void:
	if _selected_competition.is_empty():
		return

	var fee: int = _selected_competition.get("entry_fee", 0)
	var coins: int = SaveManager.data.get("currency", 0)
	if coins < fee:
		return

	# Deduct entry fee
	SaveManager.modify_currency(-fee)

	# Transition to grooming with competition context
	GameManager.change_state(GameManager.GameState.GROOMING, {
		"competition": _selected_competition,
		"mode": "competition",
	})


func _on_back_pressed() -> void:
	if detail_panel.visible:
		detail_panel.visible = false
	else:
		GameManager.change_state(GameManager.GameState.SALON)
