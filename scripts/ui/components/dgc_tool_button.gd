class_name DGCToolButton
extends PanelContainer

## ToolButton - a grooming tool in the arena toolbar.
## Square 96x96, glyph + label. Selected state pops yellow with gold ring.

signal tool_selected

@export var glyph: String = "\u2702\uFE0F":
	set(value):
		glyph = value
		if _glyph_label:
			_glyph_label.text = value

@export var label: String = "Tool":
	set(value):
		label = value
		if _text_label:
			_text_label.text = value

@export var selected: bool = false:
	set(value):
		selected = value
		_update_style()

@export var disabled: bool = false:
	set(value):
		disabled = value
		_update_style()

var _glyph_label: Label
var _text_label: Label
var _vbox: VBoxContainer
var _style_normal: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _is_hovered: bool = false
var _is_pressed: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(96, 96)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Build styles
	_style_normal = _create_base_style()
	_style_normal.bg_color = DesignTokens.BLUE_PANEL
	_style_normal.border_color = DesignTokens.BLUE_LINE
	_style_normal.border_width_top = DesignTokens.BORDER_THIN
	_style_normal.border_width_bottom = DesignTokens.BORDER_THIN
	_style_normal.border_width_left = DesignTokens.BORDER_THIN
	_style_normal.border_width_right = DesignTokens.BORDER_THIN

	_style_selected = _create_base_style()
	_style_selected.bg_color = DesignTokens.YELLOW
	_style_selected.border_color = DesignTokens.GOLD
	_style_selected.border_width_top = DesignTokens.BORDER_THICK
	_style_selected.border_width_bottom = DesignTokens.BORDER_THICK
	_style_selected.border_width_left = DesignTokens.BORDER_THICK
	_style_selected.border_width_right = DesignTokens.BORDER_THICK

	_style_hover = _create_base_style()
	_style_hover.bg_color = Color("#e3eef8")
	_style_hover.border_color = DesignTokens.BLUE_LINE
	_style_hover.border_width_top = DesignTokens.BORDER_THIN
	_style_hover.border_width_bottom = DesignTokens.BORDER_THIN
	_style_hover.border_width_left = DesignTokens.BORDER_THIN
	_style_hover.border_width_right = DesignTokens.BORDER_THIN

	add_theme_stylebox_override("panel", _style_normal)

	# VBox layout
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 4)
	_vbox.anchors_preset = Control.PRESET_FULL_RECT
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_vbox)

	# Glyph
	_glyph_label = Label.new()
	_glyph_label.text = glyph
	_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph_label.add_theme_font_size_override("font_size", 34)
	_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_glyph_label)

	# Text label
	_text_label = Label.new()
	_text_label.text = label
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_text_label.add_theme_color_override("font_color", DesignTokens.INK)
	if DesignTokens.font_body_bold:
		_text_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_text_label)

	_update_style()

func _create_base_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = DesignTokens.RADIUS_PANEL
	sb.corner_radius_top_right = DesignTokens.RADIUS_PANEL
	sb.corner_radius_bottom_left = DesignTokens.RADIUS_PANEL
	sb.corner_radius_bottom_right = DesignTokens.RADIUS_PANEL
	return sb

func _update_style() -> void:
	if disabled:
		modulate.a = 0.5
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		modulate.a = 1.0
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if selected:
		add_theme_stylebox_override("panel", _style_selected)
		scale = Vector2(1.05, 1.05)
	elif _is_hovered and not disabled:
		add_theme_stylebox_override("panel", _style_hover)
		scale = Vector2(1.0, 1.0)
	else:
		add_theme_stylebox_override("panel", _style_normal)
		scale = Vector2(1.0, 1.0)

	if _is_pressed and not disabled:
		scale = Vector2(DesignTokens.PRESS_SCALE, DesignTokens.PRESS_SCALE)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_update_style()
			else:
				_is_pressed = false
				_update_style()
				if get_global_rect().has_point(event.global_position):
					tool_selected.emit()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_is_hovered = true
			_update_style()
		NOTIFICATION_MOUSE_EXIT:
			_is_hovered = false
			_is_pressed = false
			_update_style()
