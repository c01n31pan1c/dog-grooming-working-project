@tool
class_name DGCSlider
extends HBoxContainer
## Styled slider with label, custom track/grabber, and value display.

signal value_changed(new_value: float)

@export var value: float = 50.0:
	set(v):
		value = clampf(v, min_val, max_val)
		_update_slider()
		value_changed.emit(value)

@export var min_val: float = 0.0
@export var max_val: float = 100.0
@export var step: float = 1.0:
	set(v):
		step = v
		if _slider:
			_slider.step = step

@export var label_text: String = "Volume":
	set(v):
		label_text = v
		if _label:
			_label.text = label_text

@export var show_value: bool = true:
	set(v):
		show_value = v
		if _value_label:
			_value_label.visible = show_value

var _label: Label
var _slider: HSlider
var _value_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_build_ui()
	_update_slider()


func _build_ui() -> void:
	# Label
	_label = Label.new()
	_label.name = "SliderLabel"
	_label.text = label_text
	_label.custom_minimum_size.x = 120
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color("#3d3d5c"))
	add_child(_label)

	# HSlider
	_slider = HSlider.new()
	_slider.name = "Slider"
	_slider.min_value = min_val
	_slider.max_value = max_val
	_slider.step = step
	_slider.value = value
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.custom_minimum_size = Vector2(100, 28)
	_style_slider()
	_slider.value_changed.connect(_on_slider_value_changed)
	add_child(_slider)

	# Value label
	_value_label = Label.new()
	_value_label.name = "ValueLabel"
	_value_label.custom_minimum_size.x = 60
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.add_theme_font_size_override("font_size", 26)
	_value_label.add_theme_color_override("font_color", Color("#3d3d5c"))
	_value_label.visible = show_value
	add_child(_value_label)


func _style_slider() -> void:
	# Track (slider background)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color("#d4e9f7")
	track_style.corner_radius_top_left = 6
	track_style.corner_radius_top_right = 6
	track_style.corner_radius_bottom_left = 6
	track_style.corner_radius_bottom_right = 6
	track_style.content_margin_top = 6
	track_style.content_margin_bottom = 6
	_slider.add_theme_stylebox_override("slider", track_style)

	# Fill (the filled portion)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#ffe066")
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	fill_style.content_margin_top = 6
	fill_style.content_margin_bottom = 6
	_slider.add_theme_stylebox_override("grabber_area", fill_style)
	_slider.add_theme_stylebox_override("grabber_area_highlight", fill_style)

	# Grabber
	var grabber_tex := _create_grabber_texture(Color("#ffd700"), 28)
	var grabber_hover := _create_grabber_texture(Color("#e6b800"), 28)
	_slider.add_theme_icon_override("grabber", grabber_tex)
	_slider.add_theme_icon_override("grabber_highlight", grabber_hover)
	_slider.add_theme_icon_override("grabber_disabled", grabber_tex)


func _create_grabber_texture(color: Color, grab_size: int) -> ImageTexture:
	var img := Image.create(grab_size, grab_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(grab_size / 2.0, grab_size / 2.0)
	var radius := grab_size / 2.0
	var border_color := Color.WHITE

	for x in grab_size:
		for y in grab_size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius - 2:
				img.set_pixel(x, y, color)
			elif dist <= radius:
				img.set_pixel(x, y, border_color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)


func _update_slider() -> void:
	if _slider:
		_slider.min_value = min_val
		_slider.max_value = max_val
		_slider.value = value
	if _value_label:
		var pct := ((value - min_val) / maxf(max_val - min_val, 0.001)) * 100.0
		_value_label.text = "%d%%" % int(pct)


func _on_slider_value_changed(new_value: float) -> void:
	value = new_value
