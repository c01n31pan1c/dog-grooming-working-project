@tool
class_name DGCProgressBar
extends Control
## Custom progress bar with pastel track and colored fill.

enum Tone { MINT, GOLD, CORAL }

@export var value: float = 50.0:
	set(v):
		var old := value
		value = clampf(v, 0.0, max_value)
		if not is_equal_approx(old, value):
			_animate_fill()

@export var max_value: float = 100.0:
	set(v):
		max_value = maxf(v, 0.001)
		_update_fill_immediate()

@export var label_text: String = "":
	set(v):
		label_text = v
		if _label:
			_label.text = label_text
			_label.visible = not label_text.is_empty()

@export var tone: Tone = Tone.MINT:
	set(v):
		tone = v
		_apply_fill_color()

@export var bar_height: int = 36:
	set(v):
		bar_height = v
		custom_minimum_size.y = bar_height
		if _track:
			_track.custom_minimum_size.y = bar_height
		if _fill:
			_fill.custom_minimum_size.y = bar_height

var _track: Panel
var _fill: Panel
var _label: Label
var _fill_tween: Tween


func _ready() -> void:
	custom_minimum_size.y = bar_height
	_build_ui()
	_update_fill_immediate()


func _build_ui() -> void:
	# Track
	_track = Panel.new()
	_track.name = "Track"
	_track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_track.custom_minimum_size.y = bar_height
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color("#d4e9f7")
	track_style.corner_radius_top_left = 8
	track_style.corner_radius_top_right = 8
	track_style.corner_radius_bottom_left = 8
	track_style.corner_radius_bottom_right = 8
	track_style.anti_aliasing = true
	_track.add_theme_stylebox_override("panel", track_style)
	add_child(_track)

	# Fill
	_fill = Panel.new()
	_fill.name = "Fill"
	_fill.custom_minimum_size.y = bar_height
	_fill.anchor_top = 0
	_fill.anchor_bottom = 1
	_fill.anchor_left = 0
	_fill.anchor_right = 0
	_fill.offset_top = 0
	_fill.offset_bottom = 0
	_fill.offset_left = 0
	_fill.clip_contents = true
	_apply_fill_color()
	_track.add_child(_fill)

	# Label
	_label = Label.new()
	_label.name = "BarLabel"
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color("#3d3d5c"))
	_label.text = label_text
	_label.visible = not label_text.is_empty()
	_track.add_child(_label)


func _apply_fill_color() -> void:
	if not _fill:
		return
	var fill_style := StyleBoxFlat.new()
	match tone:
		Tone.MINT:
			fill_style.bg_color = Color("#b5ead7")
		Tone.GOLD:
			fill_style.bg_color = Color("#ffd700")
		Tone.CORAL:
			fill_style.bg_color = Color("#ff8c7c")
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8
	fill_style.anti_aliasing = true
	_fill.add_theme_stylebox_override("panel", fill_style)


func _get_fill_ratio() -> float:
	return clampf(value / max_value, 0.0, 1.0)


func _update_fill_immediate() -> void:
	if not _fill or not _track:
		return
	await get_tree().process_frame
	var target_width := _track.size.x * _get_fill_ratio()
	_fill.size.x = target_width
	_fill.custom_minimum_size.x = target_width


func _animate_fill() -> void:
	if not _fill or not _track or not is_inside_tree():
		_update_fill_immediate()
		return
	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()
	var target_width := _track.size.x * _get_fill_ratio()
	_fill_tween = create_tween()
	_fill_tween.tween_property(_fill, "custom_minimum_size:x", target_width, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fill_tween.parallel().tween_property(_fill, "size:x", target_width, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_fill_immediate()
