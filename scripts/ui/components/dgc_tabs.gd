@tool
class_name DGCTabs
extends HBoxContainer
## Tab bar with selected/unselected states and gold underline on active tab.

signal tab_changed(index: int)

@export var tabs: PackedStringArray = PackedStringArray(["Tab 1", "Tab 2", "Tab 3"]):
	set(v):
		tabs = v
		_rebuild_tabs()

@export var selected_index: int = 0:
	set(v):
		var old := selected_index
		selected_index = clampi(v, 0, maxi(tabs.size() - 1, 0))
		if old != selected_index:
			_update_selection()
			tab_changed.emit(selected_index)

var _tab_buttons: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	_rebuild_tabs()


func _rebuild_tabs() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	_tab_buttons.clear()

	for i in tabs.size():
		var btn := Button.new()
		btn.text = tabs[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = false
		btn.pressed.connect(_on_tab_pressed.bind(i))
		add_child(btn)
		_tab_buttons.append(btn)

	# Wait a frame for children to be ready
	if is_inside_tree():
		await get_tree().process_frame
	_update_selection()


func _update_selection() -> void:
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i]
		var sel := i == selected_index
		var style := StyleBoxFlat.new()

		if sel:
			style.bg_color = Color("#d4e9f7")
		else:
			style.bg_color = Color("#e8eef3")

		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 0
		style.corner_radius_bottom_right = 0
		style.anti_aliasing = true

		# Gold bottom border on selected
		style.border_width_bottom = 3 if sel else 3
		style.border_color = Color("#ffd700") if sel else Color(1, 1, 1, 0)
		style.border_width_top = 0
		style.border_width_left = 0
		style.border_width_right = 0

		style.content_margin_top = 12
		style.content_margin_bottom = 12
		style.content_margin_left = 16
		style.content_margin_right = 16

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style.duplicate())
		btn.add_theme_stylebox_override("pressed", style.duplicate())
		btn.add_theme_stylebox_override("focus", style.duplicate())

		var text_color := Color("#3d3d5c") if sel else Color("#344960")
		btn.add_theme_color_override("font_color", text_color)
		btn.add_theme_color_override("font_hover_color", text_color)
		btn.add_theme_color_override("font_pressed_color", text_color)

		btn.add_theme_font_size_override("font_size", 24)


func _on_tab_pressed(index: int) -> void:
	selected_index = index
