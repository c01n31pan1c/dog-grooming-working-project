## BreedPediaScreen — Main screen for the Breed-pedia feature.
## Shows a collection grid of DGCBreedCard components and switches to a
## DGC-component detail view on tap. Uses DesignTokens for all styling.
extends Node

## Persistent set of breed names the player has encountered (groomed at least once).
var _encountered_breeds: Dictionary = {}

## All loaded breed data resources.
var _all_breeds: Array[Resource] = []

## Currently selected breed for detail view (null = show grid).
var _selected_breed: Resource = null

## The state to return to when the back button is pressed.
var _origin_state: int = GameManager.GameState.MAIN_MENU

@onready var _ui: Control = $UI

## Programmatically built views
var _collection_view: Control
var _detail_view: Control
var _discovery_label: Label
var _breed_grid: GridContainer


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.BREED_PEDIA
	var context: Dictionary = GameManager.transition_context
	if context.has("origin"):
		_origin_state = context["origin"]
	_load_breeds()
	_build_collection_view()
	_build_detail_view()
	_show_collection()

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


## === COLLECTION GRID VIEW ===

func _build_collection_view() -> void:
	_collection_view = Control.new()
	_collection_view.name = "CollectionView"
	_collection_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_collection_view)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_collection_view.add_child(vbox)

	# --- Screen Header: back + title + spacer ---
	var header := _build_screen_header("BREED-PEDIA", _on_back_to_menu)
	vbox.add_child(header)

	# --- Discovery counter ---
	var counter_margin := MarginContainer.new()
	counter_margin.add_theme_constant_override("margin_left", 22)
	counter_margin.add_theme_constant_override("margin_right", 22)
	counter_margin.add_theme_constant_override("margin_top", 12)
	counter_margin.add_theme_constant_override("margin_bottom", 0)
	vbox.add_child(counter_margin)

	_discovery_label = Label.new()
	_discovery_label.add_theme_font_size_override("font_size", 16)
	_discovery_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_bold:
		_discovery_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	counter_margin.add_child(_discovery_label)

	# --- Scrollable 2-column grid ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var scroll_margin := MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 22)
	scroll_margin.add_theme_constant_override("margin_right", 22)
	scroll_margin.add_theme_constant_override("margin_top", 12)
	scroll_margin.add_theme_constant_override("margin_bottom", 22)
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_margin)

	_breed_grid = GridContainer.new()
	_breed_grid.name = "BreedGrid"
	_breed_grid.columns = 2
	_breed_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_breed_grid.add_theme_constant_override("h_separation", 14)
	_breed_grid.add_theme_constant_override("v_separation", 14)
	scroll_margin.add_child(_breed_grid)

	_populate_grid()


func _populate_grid() -> void:
	# Clear existing cards
	for child in _breed_grid.get_children():
		child.queue_free()

	var unlocked_count: int = 0
	var card_index: int = 0
	for breed in _all_breeds:
		var is_unlocked := _is_breed_unlocked(breed)
		if is_unlocked:
			unlocked_count += 1
		var is_new := is_unlocked and breed.breed_name not in _encountered_breeds

		var card := DGCBreedCard.new()
		card.breed_name = breed.breed_name if is_unlocked else "???"
		card.group = breed.breed_group if is_unlocked else _get_unlock_hint(breed.unlock_requirement)
		card.glyph = "\U0001F429"  # Default dog glyph
		card.difficulty = breed.difficulty_tier + 1  # BreedData uses 0-2, DGCBreedCard uses 1-5
		card.locked = not is_unlocked
		card.is_new = is_new
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.card_pressed.connect(_on_breed_card_pressed.bind(breed, card))
		_breed_grid.add_child(card)

		# Staggered entrance animation
		UIAnimations.fade_slide_up(card, 30.0, 0.3, card_index * 0.06)
		card_index += 1

	# Update discovery counter
	_update_discovery_counter(unlocked_count)


func _update_discovery_counter(unlocked_count: int = -1) -> void:
	if not _discovery_label:
		return
	if unlocked_count < 0:
		unlocked_count = 0
		for breed in _all_breeds:
			if _is_breed_unlocked(breed):
				unlocked_count += 1
	_discovery_label.text = "%d of %d breeds discovered" % [unlocked_count, _all_breeds.size()]


## === BREED DETAIL VIEW ===

var _detail_glyph_label: Label
var _detail_group_badge: DGCBadge
var _detail_difficulty_badge: DGCBadge
var _detail_about_panel: DGCPanel
var _detail_about_text: Label
var _detail_guide_panel: DGCPanel
var _detail_guide_text: Label
var _detail_guard_legend: DGCGuardLegend
var _detail_header_title: Label

func _build_detail_view() -> void:
	_detail_view = Control.new()
	_detail_view.name = "DetailView"
	_detail_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_view.visible = false
	_ui.add_child(_detail_view)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_view.add_child(vbox)

	# --- Screen Header: back + breed name ---
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", DesignTokens.SPACE[3])

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_top", 14)
	header_margin.add_theme_constant_override("margin_bottom", 8)
	header_margin.add_child(header_hbox)
	vbox.add_child(header_margin)

	var back_btn := DGCIconButton.new()
	back_btn.glyph = "\u2039"
	back_btn.variant = DGCIconButton.Variant.SECONDARY
	back_btn.button_size = 48
	back_btn.pressed.connect(_on_detail_back)
	header_hbox.add_child(back_btn)

	_detail_header_title = Label.new()
	_detail_header_title.text = "Breed Name"
	_detail_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_header_title.add_theme_font_size_override("font_size", DesignTokens.FS_H1)
	_detail_header_title.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_extrabold:
		_detail_header_title.add_theme_font_override("font", DesignTokens.font_display_extrabold)
	_detail_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hbox.add_child(_detail_header_title)

	# --- Scrollable content ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 22)
	content_margin.add_theme_constant_override("margin_right", 22)
	content_margin.add_theme_constant_override("margin_top", 8)
	content_margin.add_theme_constant_override("margin_bottom", 22)
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 16)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_child(content_vbox)

	# --- Large glyph (96px centered) ---
	var glyph_center := CenterContainer.new()
	content_vbox.add_child(glyph_center)

	_detail_glyph_label = Label.new()
	_detail_glyph_label.add_theme_font_size_override("font_size", 96)
	_detail_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if DesignTokens.font_display_bold:
		_detail_glyph_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	glyph_center.add_child(_detail_glyph_label)

	# --- Two badges: group (blue) + difficulty (mint) ---
	var badge_center := CenterContainer.new()
	content_vbox.add_child(badge_center)

	var badge_hbox := HBoxContainer.new()
	badge_hbox.add_theme_constant_override("separation", 8)
	badge_center.add_child(badge_hbox)

	_detail_group_badge = DGCBadge.new()
	_detail_group_badge.tone = DGCBadge.Tone.BLUE
	badge_hbox.add_child(_detail_group_badge)

	_detail_difficulty_badge = DGCBadge.new()
	_detail_difficulty_badge.tone = DGCBadge.Tone.MINT
	badge_hbox.add_child(_detail_difficulty_badge)

	# --- "About" DGCPanel ---
	_detail_about_panel = DGCPanel.new()
	_detail_about_panel.title = "About"
	content_vbox.add_child(_detail_about_panel)

	_detail_about_text = Label.new()
	_detail_about_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_about_text.add_theme_font_size_override("font_size", 16)
	_detail_about_text.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_semibold:
		_detail_about_text.add_theme_font_override("font", DesignTokens.font_body_semibold)
	# Will be added as child of the panel's content vbox after _ready
	_detail_about_panel.add_child(_detail_about_text)

	# --- "Grooming Guide" DGCPanel ---
	_detail_guide_panel = DGCPanel.new()
	_detail_guide_panel.title = "Grooming Guide"
	content_vbox.add_child(_detail_guide_panel)

	_detail_guide_text = Label.new()
	_detail_guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_guide_text.add_theme_font_size_override("font_size", 16)
	_detail_guide_text.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	if DesignTokens.font_body_semibold:
		_detail_guide_text.add_theme_font_override("font", DesignTokens.font_body_semibold)
	_detail_guide_panel.add_child(_detail_guide_text)

	_detail_guard_legend = DGCGuardLegend.new()
	_detail_guard_legend.compact = false
	_detail_guide_panel.add_child(_detail_guard_legend)


## === VIEW TOGGLING ===

func _show_collection() -> void:
	_collection_view.visible = true
	_detail_view.visible = false
	_selected_breed = null


func _show_detail(breed_data: Resource) -> void:
	_selected_breed = breed_data
	_collection_view.visible = false
	_detail_view.visible = true

	# Populate detail view
	_detail_header_title.text = breed_data.breed_name
	_detail_glyph_label.text = "\U0001F429"  # Default dog glyph
	_detail_group_badge.label_text = breed_data.breed_group
	var paw_text := "\U0001F43E".repeat(breed_data.difficulty_tier + 1) + " difficulty"
	_detail_difficulty_badge.label_text = paw_text

	# About text - use description
	_detail_about_text.text = breed_data.description if breed_data.description != "" else "No description available."

	# Grooming guide text - build from zones
	var guide_parts: PackedStringArray = PackedStringArray()
	var zone_entries: Array = []
	for zone_id in breed_data.grooming_zones:
		var zone_data: Dictionary = breed_data.grooming_zones[zone_id]
		zone_entries.append({"id": zone_id, "data": zone_data})
	zone_entries.sort_custom(func(a, b): return a.data.get("suggested_order", 99) < b.data.get("suggested_order", 99))

	for entry in zone_entries:
		var zone_id: String = entry.id
		var zone_data: Dictionary = entry.data
		var tool_name: String = zone_data.get("required_tool", "UNKNOWN")
		var guard: float = zone_data.get("guard_size", 0.0)
		var display_name := zone_id.replace("_", " ").capitalize()
		var line := "%s: %s" % [display_name, tool_name.capitalize()]
		if tool_name == "CLIPPER" and guard > 0.0:
			line += " (guard %.2g\")" % guard
		var notes: String = zone_data.get("notes", "")
		if notes != "":
			line += " - " + notes
		guide_parts.append(line)

	_detail_guide_text.text = "\n".join(guide_parts) if guide_parts.size() > 0 else "No grooming guide available."

	# Slide in animation
	UIAnimations.slide_in_from_right(_detail_view, 400.0, 0.4)


## === SCREEN HEADER BUILDER ===

func _build_screen_header(title_text: String, back_callback: Callable) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 8)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", DesignTokens.SPACE[3])
	margin.add_child(hbox)

	var back_btn := DGCIconButton.new()
	back_btn.glyph = "\u2039"
	back_btn.variant = DGCIconButton.Variant.SECONDARY
	back_btn.button_size = 48
	back_btn.pressed.connect(back_callback)
	UIAnimations.setup_button_juice(back_btn)
	hbox.add_child(back_btn)

	var title_label := Label.new()
	title_label.text = title_text
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", DesignTokens.FS_H1)
	title_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_extrabold:
		title_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title_label)

	# Spacer to balance the header
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(48, 0)
	hbox.add_child(spacer)

	return margin


## === EVENT HANDLERS ===

func _on_breed_card_pressed(breed_data: Resource, card: DGCBreedCard) -> void:
	if not _is_breed_unlocked(breed_data):
		return
	# Tap bounce on the card before navigating
	if card:
		UIAnimations._ensure_center_pivot(card)
		var tween := card.create_tween()
		tween.tween_property(card, "scale", Vector2(0.95, 0.95), 0.08) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "scale", Vector2.ONE, 0.12) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await tween.finished
	_show_detail(breed_data)


func _on_detail_back() -> void:
	# Back from detail returns to grid (not to previous screen)
	_show_collection()


func _on_back_to_menu() -> void:
	GameManager.change_state(_origin_state)


func _on_grooming_completed(breed_data: Resource, _results: Dictionary) -> void:
	if breed_data == null:
		return
	var breed_name: String = breed_data.breed_name
	if breed_name not in _encountered_breeds:
		_encountered_breeds[breed_name] = true
		EventBus.breed_unlocked.emit(breed_data)
		# Refresh grid to show encountered badge
		_populate_grid()


## === UNLOCK LOGIC ===

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
	_populate_grid()


## Returns encountered breed names for saving.
func get_encountered_list() -> Array:
	return _encountered_breeds.keys()
