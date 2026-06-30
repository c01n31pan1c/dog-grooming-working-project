@tool
class_name DGCPanel
extends PanelContainer
## Frosted light-blue card panel with optional title.

@export var title: String = "":
	set(v):
		title = v
		_update_title()

@export var padded: bool = true:
	set(v):
		padded = v
		_apply_style()

var _title_label: Label
var _content_vbox: VBoxContainer


func _ready() -> void:
	_build_structure()
	_apply_style()


func _build_structure() -> void:
	# Internal layout: VBox with optional title label, then content flows into it
	_content_vbox = VBoxContainer.new()
	_content_vbox.name = "ContentVBox"
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color("#3d3d5c"))
	_title_label.visible = not title.is_empty()
	_title_label.text = title

	# Reparent existing children into the vbox
	var children: Array[Node] = []
	for child in get_children():
		children.append(child)
	for child in children:
		remove_child(child)

	add_child(_content_vbox)
	_content_vbox.add_child(_title_label)
	for child in children:
		_content_vbox.add_child(child)


func _update_title() -> void:
	if _title_label:
		_title_label.text = title
		_title_label.visible = not title.is_empty()


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f0f7ff")
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color("#c8d6e4")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.anti_aliasing = true

	# Faint shadow
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)

	var margin := 24 if padded else 0
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	style.content_margin_left = margin
	style.content_margin_right = margin

	add_theme_stylebox_override("panel", style)
