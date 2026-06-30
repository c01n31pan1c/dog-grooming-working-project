@tool
class_name DGCBadge
extends PanelContainer
## Small status pill badge with tone-based coloring and optional pulse.

enum Tone { GOLD, MINT, CORAL, BLUE, INK }

@export var label_text: String = "NEW":
	set(v):
		label_text = v
		if _label:
			_label.text = label_text

@export var tone: Tone = Tone.GOLD:
	set(v):
		tone = v
		_apply_style()

@export var pulse: bool = false:
	set(v):
		pulse = v
		_update_pulse()

var _label: Label
var _pulse_tween: Tween


func _ready() -> void:
	_build_ui()
	_apply_style()
	_update_pulse()


func _build_ui() -> void:
	_label = Label.new()
	_label.name = "BadgeLabel"
	_label.text = label_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	if DesignTokens.font_display_bold:
		_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	add_child(_label)


func _apply_style() -> void:
	var style := StyleBoxFlat.new()

	var bg_color := Color("#ffd700")
	var text_color := Color("#3d3d5c")

	match tone:
		Tone.GOLD:
			bg_color = Color("#ffd700")
		Tone.MINT:
			bg_color = Color("#b5ead7")
		Tone.CORAL:
			bg_color = Color("#ff8c7c")
		Tone.BLUE:
			bg_color = Color("#e8eef3")
			text_color = Color("#344960")
		Tone.INK:
			bg_color = Color("#3d3d5c")
			text_color = Color.WHITE

	style.bg_color = bg_color
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.anti_aliasing = true
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 14
	style.content_margin_right = 14

	add_theme_stylebox_override("panel", style)

	if _label:
		_label.add_theme_color_override("font_color", text_color)


func _update_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		scale = Vector2.ONE

	if pulse and is_inside_tree():
		pivot_offset = size / 2.0
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.6).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0
