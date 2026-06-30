@tool
class_name DGCButton
extends Button
## Chunky pill-rounded action button with press animation.
## Variants: primary (yellow/gold), secondary (light blue), ghost (transparent).

enum Variant { PRIMARY, SECONDARY, GHOST }
enum Size { SM, MD, LG }

@export var variant: Variant = Variant.PRIMARY:
	set(v):
		variant = v
		_apply_style()

@export var button_size: Size = Size.MD:
	set(v):
		button_size = v
		_apply_style()

@export var block: bool = false:
	set(v):
		block = v
		if block:
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			size_flags_horizontal = Control.SIZE_SHRINK_CENTER

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_pressed: StyleBoxFlat
var _style_disabled: StyleBoxFlat
var _press_tween: Tween


func _ready() -> void:
	_build_styles()
	_apply_style()
	pivot_offset = size / 2.0
	button_down.connect(_on_press)
	button_up.connect(_on_release)
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _build_styles() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.border_width_bottom = 2
	_style_normal.border_width_top = 2
	_style_normal.border_width_left = 2
	_style_normal.border_width_right = 2

	_style_hover = _style_normal.duplicate()
	_style_pressed = _style_normal.duplicate()
	_style_disabled = _style_normal.duplicate()


func _apply_style() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	_build_styles()

	# --- Variant colors ---
	match variant:
		Variant.PRIMARY:
			_style_normal.bg_color = Color("#ffe066")
			_style_normal.border_color = Color("#ffd700")
			_style_hover.bg_color = Color("#ffd700")
			_style_hover.border_color = Color("#e6b800")
			_style_pressed.bg_color = Color("#e6b800")
			_style_pressed.border_color = Color("#ccaa00")
		Variant.SECONDARY:
			_style_normal.bg_color = Color("#f0f7ff")
			_style_normal.border_color = Color("#c8d6e4")
			_style_hover.bg_color = Color("#e3eef8")
			_style_hover.border_color = Color("#c8d6e4")
			_style_pressed.bg_color = Color("#c8d6e4")
			_style_pressed.border_color = Color("#c8d6e4")
		Variant.GHOST:
			_style_normal.bg_color = Color(1, 1, 1, 0)
			_style_normal.border_color = Color(1, 1, 1, 0)
			_style_hover.bg_color = Color(1, 1, 1, 0.5)
			_style_hover.border_color = Color(1, 1, 1, 0)
			_style_pressed.bg_color = Color(1, 1, 1, 0.3)
			_style_pressed.border_color = Color(1, 1, 1, 0)

	_style_disabled.bg_color = Color(0.78, 0.84, 0.89, 0.5)
	_style_disabled.border_color = Color(0.78, 0.84, 0.89, 0.6)

	# --- Radius ---
	var radius := 24
	for s in [_style_normal, _style_hover, _style_pressed, _style_disabled]:
		s.corner_radius_top_left = radius
		s.corner_radius_top_right = radius
		s.corner_radius_bottom_left = radius
		s.corner_radius_bottom_right = radius
		s.anti_aliasing = true

	# --- Shadow on normal + hover ---
	_style_normal.shadow_color = Color(0, 0, 0, 0.08)
	_style_normal.shadow_size = 4
	_style_normal.shadow_offset = Vector2(0, 2)
	_style_hover.shadow_color = Color(0, 0, 0, 0.14)
	_style_hover.shadow_size = 6
	_style_hover.shadow_offset = Vector2(0, 4)

	# --- Size: font + padding + min height ---
	var font_size := 28
	var pad_y := 24
	var pad_x := 32
	var min_h := 88
	match button_size:
		Size.SM:
			font_size = 24
			pad_y = 12
			pad_x = 24
			min_h = 48
		Size.MD:
			font_size = 28
			pad_y = 24
			pad_x = 32
			min_h = 88
		Size.LG:
			font_size = 32
			pad_y = 24
			pad_x = 32
			min_h = 96

	for s in [_style_normal, _style_hover, _style_pressed, _style_disabled]:
		s.content_margin_top = pad_y
		s.content_margin_bottom = pad_y
		s.content_margin_left = pad_x
		s.content_margin_right = pad_x

	custom_minimum_size.y = min_h

	add_theme_stylebox_override("normal", _style_normal)
	add_theme_stylebox_override("hover", _style_hover)
	add_theme_stylebox_override("pressed", _style_pressed)
	add_theme_stylebox_override("disabled", _style_disabled)

	# Focus style same as normal
	add_theme_stylebox_override("focus", _style_normal.duplicate())

	add_theme_font_size_override("font_size", font_size)

	# Text color
	var text_color := Color("#3d3d5c")
	match variant:
		Variant.GHOST:
			text_color = Color("#344960")
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", text_color)
	add_theme_color_override("font_pressed_color", text_color)
	add_theme_color_override("font_disabled_color", Color("#8899aa"))

	# Block mode
	if block:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _on_press() -> void:
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	pivot_offset = size / 2.0
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)


func _on_release() -> void:
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	pivot_offset = size / 2.0
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
