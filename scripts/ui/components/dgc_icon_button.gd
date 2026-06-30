@tool
class_name DGCIconButton
extends Button
## Compact square icon button for single glyphs (back, close, settings).
## Same press animation as DGCButton.

enum Variant { PRIMARY, SECONDARY, GHOST }

@export var variant: Variant = Variant.SECONDARY:
	set(v):
		variant = v
		_apply_style()

@export var button_size: int = 56:
	set(v):
		button_size = v
		_apply_style()

@export var glyph: String = "\u2039":
	set(v):
		glyph = v
		text = glyph

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_pressed: StyleBoxFlat
var _press_tween: Tween


func _ready() -> void:
	text = glyph
	clip_text = false
	_apply_style()
	pivot_offset = Vector2(button_size / 2.0, button_size / 2.0)
	button_down.connect(_on_press)
	button_up.connect(_on_release)
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _apply_style() -> void:
	custom_minimum_size = Vector2(button_size, button_size)
	size = Vector2(button_size, button_size)

	_style_normal = StyleBoxFlat.new()
	_style_hover = StyleBoxFlat.new()
	_style_pressed = StyleBoxFlat.new()

	for s in [_style_normal, _style_hover, _style_pressed]:
		s.border_width_bottom = 2
		s.border_width_top = 2
		s.border_width_left = 2
		s.border_width_right = 2
		s.corner_radius_top_left = 24
		s.corner_radius_top_right = 24
		s.corner_radius_bottom_left = 24
		s.corner_radius_bottom_right = 24
		s.anti_aliasing = true

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

	_style_normal.shadow_color = Color(0, 0, 0, 0.08)
	_style_normal.shadow_size = 4
	_style_normal.shadow_offset = Vector2(0, 2)
	_style_hover.shadow_color = Color(0, 0, 0, 0.14)
	_style_hover.shadow_size = 6
	_style_hover.shadow_offset = Vector2(0, 4)

	add_theme_stylebox_override("normal", _style_normal)
	add_theme_stylebox_override("hover", _style_hover)
	add_theme_stylebox_override("pressed", _style_pressed)
	add_theme_stylebox_override("focus", _style_normal.duplicate())

	var font_sz := int(button_size * 0.42)
	add_theme_font_size_override("font_size", font_sz)

	var text_color := Color("#3d3d5c")
	if variant == Variant.GHOST:
		text_color = Color("#344960")
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", text_color)
	add_theme_color_override("font_pressed_color", text_color)


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
