## BreedPediaScreen — Main screen for the Breed-pedia feature.
## Shows a collection grid of breed cards and switches to detail view on tap.
## Tracks encountered breeds and signals first encounters.
extends Node

## Persistent set of breed names the player has encountered (groomed at least once).
var _encountered_breeds: Dictionary = {}

## All loaded breed data resources.
var _all_breeds: Array[Resource] = []

## Currently unlocked breed names (determined by progression state).
var _unlocked_breeds: Dictionary = {}

@onready var _collection_view: Control = $UI/CollectionView
@onready var _breed_grid: GridContainer = $UI/CollectionView/ScrollContainer/BreedGrid
@onready var _detail_view: BreedViewer = $UI/DetailView
@onready var _title_label: Label = $UI/CollectionView/TitleBar/TitleLabel
@onready var _back_to_menu_button: Button = $UI/CollectionView/TitleBar/BackButton


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.BREED_PEDIA
	_load_breeds()
	_build_collection_grid()

	_detail_view.back_pressed.connect(_on_detail_back)
	_back_to_menu_button.pressed.connect(_on_back_to_menu)

	# Listen for grooming completions to track encounters
	EventBus.grooming_completed.connect(_on_grooming_completed)


func _load_breeds() -> void:
	_all_breeds = DataLoader.load_all_breeds()
	# Sort by difficulty then name
	_all_breeds.sort_custom(func(a, b):
		if a.difficulty_tier != b.difficulty_tier:
			return a.difficulty_tier < b.difficulty_tier
		return a.breed_name < b.breed_name
	)


func _build_collection_grid() -> void:
	# Clear existing cards
	for child in _breed_grid.get_children():
		child.queue_free()

	for breed in _all_breeds:
		var card := _create_breed_card(breed)
		_breed_grid.add_child(card)


func _create_breed_card(breed_data: Resource) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 160)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(inner_vbox)

	var is_unlocked: bool = _is_breed_unlocked(breed_data)

	# Breed name
	var name_label := Label.new()
	if is_unlocked:
		name_label.text = breed_data.breed_name
	else:
		name_label.text = "???"
		name_label.modulate = Color(0.5, 0.5, 0.5, 1.0)
	name_label.add_theme_font_size_override("font_size", 20)
	inner_vbox.add_child(name_label)

	# Group
	var group_label := Label.new()
	if is_unlocked:
		group_label.text = breed_data.breed_group
	else:
		group_label.text = _get_unlock_hint(breed_data.unlock_requirement)
	group_label.add_theme_font_size_override("font_size", 14)
	group_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	inner_vbox.add_child(group_label)

	# Difficulty stars
	var stars_label := Label.new()
	var star_text := ""
	for i in range(3):
		star_text += "★" if i <= breed_data.difficulty_tier else "☆"
	stars_label.text = star_text
	stars_label.add_theme_font_size_override("font_size", 18)
	inner_vbox.add_child(stars_label)

	# Encountered badge
	if breed_data.breed_name in _encountered_breeds:
		var badge := Label.new()
		badge.text = "GROOMED"
		badge.add_theme_font_size_override("font_size", 12)
		badge.modulate = Color(0.3, 1.0, 0.3, 1.0)
		inner_vbox.add_child(badge)

	# Click handler
	var button := Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_breed_card_pressed.bind(breed_data))
	card.add_child(button)

	return card


func _on_breed_card_pressed(breed_data: Resource) -> void:
	var is_unlocked: bool = _is_breed_unlocked(breed_data)
	_collection_view.visible = false
	_detail_view.show_breed(breed_data, is_unlocked)


func _on_detail_back() -> void:
	_detail_view.hide_viewer()
	_collection_view.visible = true


func _on_back_to_menu() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)


func _on_grooming_completed(breed_data: Resource, _results: Dictionary) -> void:
	if breed_data == null:
		return
	var breed_name: String = breed_data.breed_name
	if breed_name not in _encountered_breeds:
		_encountered_breeds[breed_name] = true
		EventBus.breed_unlocked.emit(breed_data)
		# Refresh grid to show encountered badge
		_build_collection_grid()


## Check if a breed is unlocked based on its requirement.
## Queries SaveManager / progression state for real unlock checks.
func _is_breed_unlocked(breed_data: Resource) -> bool:
	match breed_data.unlock_requirement:
		"available_at_start":
			return true
		"tier_regional":
			return SaveManager.data.get("current_tier", 0) >= 1
		"tier_national":
			return SaveManager.data.get("current_tier", 0) >= 2
		"competition_wins_3":
			return SaveManager.data.get("total_wins", 0) >= 3
		"competition_wins_5":
			return SaveManager.data.get("total_wins", 0) >= 5
		"competition_wins_10":
			return SaveManager.data.get("total_wins", 0) >= 10
		_:
			return false


func _get_unlock_hint(requirement: String) -> String:
	match requirement:
		"available_at_start":
			return "Available"
		"tier_regional":
			return "Reach Regional tier"
		"competition_wins_3":
			return "Win 3 competitions"
		_:
			return requirement.replace("_", " ").capitalize()


## Called by SaveManager to restore encountered breeds from save data.
func restore_encountered(breed_names: Array) -> void:
	for breed_name in breed_names:
		_encountered_breeds[breed_name] = true
	_build_collection_grid()


## Returns encountered breed names for saving.
func get_encountered_list() -> Array:
	return _encountered_breeds.keys()
