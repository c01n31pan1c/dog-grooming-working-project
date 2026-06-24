## BreedViewer — Displays breed information in the Breed-pedia detail view.
## Shows breed name, group, description, grooming facts, zone map, and difficulty.
class_name BreedViewer
extends Control

signal back_pressed

var _current_breed: Resource = null

@onready var _breed_name_label: Label = $VBoxContainer/Header/HBox/BreedNameLabel
@onready var _breed_group_label: Label = $VBoxContainer/Header/HBox/BreedGroupLabel
@onready var _difficulty_container: HBoxContainer = $VBoxContainer/Header/HBox/DifficultyContainer
@onready var _description_label: RichTextLabel = $VBoxContainer/ScrollContainer/Content/DescriptionLabel
@onready var _facts_container: VBoxContainer = $VBoxContainer/ScrollContainer/Content/FactsContainer
@onready var _zones_container: VBoxContainer = $VBoxContainer/ScrollContainer/Content/ZonesContainer
@onready var _back_button: Button = $VBoxContainer/Header/HBox/BackButton
@onready var _lock_overlay: Control = $LockOverlay
@onready var _lock_label: Label = $LockOverlay/LockLabel


func _ready() -> void:
	_back_button.pressed.connect(func(): back_pressed.emit())
	visible = false


## Display detailed information for a breed. is_unlocked controls lock overlay.
func show_breed(breed_data: Resource, is_unlocked: bool = true) -> void:
	_current_breed = breed_data
	visible = true

	_breed_name_label.text = breed_data.breed_name
	_breed_group_label.text = breed_data.breed_group

	# Difficulty stars
	_populate_difficulty(breed_data.difficulty_tier)

	# Lock overlay
	if is_unlocked:
		_lock_overlay.visible = false
		_description_label.text = breed_data.description
		_populate_facts(breed_data.grooming_facts)
		_populate_zones(breed_data.grooming_zones)
	else:
		_lock_overlay.visible = true
		_lock_label.text = _get_unlock_text(breed_data.unlock_requirement)
		_description_label.text = "???"
		_clear_container(_facts_container)
		_clear_container(_zones_container)


func get_current_breed() -> Resource:
	return _current_breed


func hide_viewer() -> void:
	visible = false
	_current_breed = null


func _populate_difficulty(tier: int) -> void:
	_clear_container(_difficulty_container)
	for i in range(3):
		var star := Label.new()
		star.text = "★" if i <= tier else "☆"
		star.add_theme_font_size_override("font_size", 28)
		_difficulty_container.add_child(star)


func _populate_facts(facts: Array) -> void:
	_clear_container(_facts_container)

	var header := Label.new()
	header.text = "Grooming Facts"
	header.add_theme_font_size_override("font_size", 28)
	_facts_container.add_child(header)

	for fact in facts:
		var fact_label := Label.new()
		fact_label.text = "• " + fact
		fact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fact_label.add_theme_font_size_override("font_size", 22)
		_facts_container.add_child(fact_label)


func _populate_zones(zones: Dictionary) -> void:
	_clear_container(_zones_container)

	var header := Label.new()
	header.text = "Grooming Zone Guide"
	header.add_theme_font_size_override("font_size", 28)
	_zones_container.add_child(header)

	# Sort zones by suggested_order
	var zone_entries: Array = []
	for zone_id in zones:
		var zone_data: Dictionary = zones[zone_id]
		zone_entries.append({"id": zone_id, "data": zone_data})
	zone_entries.sort_custom(func(a, b): return a.data.get("suggested_order", 99) < b.data.get("suggested_order", 99))

	for entry in zone_entries:
		var zone_id: String = entry.id
		var zone_data: Dictionary = entry.data

		var zone_panel := PanelContainer.new()
		var zone_vbox := VBoxContainer.new()
		zone_panel.add_child(zone_vbox)

		# Zone name + tool
		var zone_header := Label.new()
		var tool_name: String = zone_data.get("required_tool", "UNKNOWN")
		var guard: float = zone_data.get("guard_size", 0.0)
		var guard_text := ""
		if guard > 0.0:
			guard_text = " | Guard: %.1f mm" % guard
		zone_header.text = "%s — %s%s" % [_format_zone_name(zone_id), tool_name, guard_text]
		zone_header.add_theme_font_size_override("font_size", 24)
		zone_vbox.add_child(zone_header)

		# Notes
		var notes: String = zone_data.get("notes", "")
		if notes != "":
			var notes_label := Label.new()
			notes_label.text = notes
			notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			notes_label.add_theme_font_size_override("font_size", 20)
			notes_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
			zone_vbox.add_child(notes_label)

		# Steps
		var steps: Array = zone_data.get("steps", [])
		if not steps.is_empty():
			var steps_label := Label.new()
			var step_names: PackedStringArray = PackedStringArray()
			for s in steps:
				step_names.append(s.replace("_", " ").capitalize())
			steps_label.text = "Steps: " + " → ".join(step_names)
			steps_label.add_theme_font_size_override("font_size", 20)
			steps_label.modulate = Color(0.7, 0.85, 1.0, 1.0)
			zone_vbox.add_child(steps_label)

		_zones_container.add_child(zone_panel)


func _format_zone_name(zone_id: String) -> String:
	return zone_id.replace("_", " ").capitalize()


func _get_unlock_text(requirement: String) -> String:
	match requirement:
		"available_at_start":
			return "Available from the start!"
		"tier_regional":
			return "Unlock: Reach Regional competition tier"
		"competition_wins_3":
			return "Unlock: Win 3 competitions"
		_:
			return "Unlock: " + requirement.replace("_", " ").capitalize()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


## Returns the guard-size-based color for the grooming guide overlay.
## Smaller guard = warmer color (closer cut), larger/zero = cooler color.
static func get_zone_color(guard_size: float) -> Color:
	if guard_size <= 0.0:
		# No clipper guard — scissors/brush/hand-strip work (blue)
		return Color(0.3, 0.5, 1.0, 0.6)
	elif guard_size <= 1.0:
		# Very close cut (red)
		return Color(1.0, 0.2, 0.2, 0.6)
	elif guard_size <= 3.0:
		# Short cut (orange)
		return Color(1.0, 0.6, 0.1, 0.6)
	elif guard_size <= 10.0:
		# Medium cut (yellow)
		return Color(1.0, 1.0, 0.2, 0.6)
	else:
		# Long/full coat (green)
		return Color(0.2, 0.8, 0.3, 0.6)
