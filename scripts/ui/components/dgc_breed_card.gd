class_name DGCBreedCard
extends PanelContainer

## BreedCard - a Breed-pedia collection tile.
## Shows breed glyph, name, group, difficulty paws. Locked/new states.

signal card_pressed

@export var breed_name: String = "Breed":
	set(value):
		breed_name = value
		_update_content()

@export var group: String = "Group":
	set(value):
		group = value
		_update_content()

@export var glyph: String = "\U0001F429":
	set(value):
		glyph = value
		_update_content()

@export var difficulty: int = 1:
	set(value):
		difficulty = clampi(value, 1, 5)
		_update_content()

@export var locked: bool = false:
	set(value):
		locked = value
		_update_content()

@export var is_new: bool = false:
	set(value):
		is_new = value
		_update_content()

var _glyph_label: Label
var _glyph_panel: PanelContainer
var _name_label: Label
var _group_label: Label
var _difficulty_label: Control
var _new_badge: Label
var _vbox: VBoxContainer
var _is_hovered: bool = false

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Panel styles
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = DesignTokens.BLUE_PANEL
	_style_normal.border_color = DesignTokens.BLUE_LINE
	_style_normal.set_border_width_all(DesignTokens.BORDER_THIN)
	_style_normal.set_corner_radius_all(DesignTokens.RADIUS_PANEL)
	_style_normal.shadow_color = Color(0, 0, 0, 0.06)
	_style_normal.shadow_size = 4
	_style_normal.shadow_offset = Vector2(0, 2)
	_style_normal.set_content_margin_all(DesignTokens.SPACE[5])

	_style_hover = _style_normal.duplicate()
	_style_hover.shadow_size = 8
	_style_hover.shadow_offset = Vector2(0, 4)

	add_theme_stylebox_override("panel", _style_normal)

	# Main VBox
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", DesignTokens.SPACE[2])
	add_child(_vbox)

	# Glyph area
	_glyph_panel = PanelContainer.new()
	_glyph_panel.custom_minimum_size = Vector2(88, 88)
	var glyph_style = StyleBoxFlat.new()
	glyph_style.bg_color = DesignTokens.BLUE_SKY
	glyph_style.set_corner_radius_all(DesignTokens.RADIUS_PANEL)
	_glyph_panel.add_theme_stylebox_override("panel", glyph_style)
	_vbox.add_child(_glyph_panel)

	var glyph_center = CenterContainer.new()
	glyph_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glyph_panel.add_child(glyph_center)

	_glyph_label = Label.new()
	_glyph_label.add_theme_font_size_override("font_size", 48)
	_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if DesignTokens.font_display_bold:
		_glyph_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph_center.add_child(_glyph_label)

	# Name
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", DesignTokens.FS_H3)
	_name_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_bold:
		_name_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_name_label)

	# Group
	_group_label = Label.new()
	_group_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_group_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)
	if DesignTokens.font_body_semibold:
		_group_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
	_group_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_group_label)

	# Difficulty paws
	_difficulty_label = Label.new()
	_difficulty_label.add_theme_font_size_override("font_size", 18)
	_difficulty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_difficulty_label)

	# NEW badge (positioned absolute at top-right)
	_new_badge = Label.new()
	_new_badge.text = "NEW"
	_new_badge.add_theme_font_size_override("font_size", 14)
	_new_badge.add_theme_color_override("font_color", DesignTokens.INK)
	if DesignTokens.font_display_bold:
		_new_badge.add_theme_font_override("font", DesignTokens.font_display_bold)
	_new_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_new_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var badge_panel = PanelContainer.new()
	badge_panel.name = "NewBadge"
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = DesignTokens.GOLD
	badge_style.set_corner_radius_all(DesignTokens.RADIUS_PILL)
	badge_style.content_margin_left = 10
	badge_style.content_margin_right = 10
	badge_style.content_margin_top = 4
	badge_style.content_margin_bottom = 4
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.add_child(_new_badge)
	badge_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge_panel.position = Vector2(-50, 12)
	badge_panel.z_index = 1
	add_child(badge_panel)

	# Start pulse animation for NEW badge
	_start_pulse_animation(badge_panel)

	_update_content()

func _update_content() -> void:
	if not _glyph_label:
		return

	if locked:
		_glyph_label.text = "\U0001F512"
		_glyph_panel.modulate = Color(1, 1, 1, 0.5)
		_glyph_panel.material = null  # grayscale would need a shader
		_name_label.text = "???"
		_group_label.text = "Locked"
		_difficulty_label.visible = false
		var badge_node = get_node_or_null("NewBadge")
		if badge_node:
			badge_node.visible = false
	else:
		_glyph_label.text = glyph
		_glyph_panel.modulate = Color.WHITE
		_name_label.text = breed_name
		_group_label.text = group
		_difficulty_label.visible = true
		# Build paw string with RichTextLabel-style or just use opacity trick
		_difficulty_label.text = "\U0001F43E".repeat(difficulty) + "\U0001F43E".repeat(maxi(0, 5 - difficulty))
		# Can't do per-character opacity in Label easily, so we use a workaround
		_update_difficulty_display()

		var badge_node = get_node_or_null("NewBadge")
		if badge_node:
			badge_node.visible = is_new

func _update_difficulty_display() -> void:
	# Replace difficulty label with RichTextLabel for per-char opacity
	if _difficulty_label:
		_difficulty_label.queue_free()
	var rtl = RichTextLabel.new()
	rtl.name = "DifficultyRTL"
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.add_theme_font_size_override("normal_font_size", 18)
	if DesignTokens.font_display_bold:
		rtl.add_theme_font_override("normal_font", DesignTokens.font_display_bold)

	var filled = "\U0001F43E".repeat(difficulty)
	var empty_count = maxi(0, 5 - difficulty)
	var empty = "\U0001F43E".repeat(empty_count)
	rtl.text = "[color=#000000]" + filled + "[/color][color=#00000040]" + empty + "[/color]"
	_vbox.add_child(rtl)
	_difficulty_label = rtl

func _start_pulse_animation(node: Control) -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(node, "scale", Vector2(DesignTokens.PULSE_SCALE, DesignTokens.PULSE_SCALE), DesignTokens.DUR_PULSE).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2.ONE, DesignTokens.DUR_PULSE).set_trans(Tween.TRANS_SINE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if get_global_rect().has_point(event.global_position):
				card_pressed.emit()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_is_hovered = true
			if not locked:
				add_theme_stylebox_override("panel", _style_hover)
				var tween = create_tween()
				tween.tween_property(self, "position:y", position.y - 3, DesignTokens.DUR_ENTRANCE_SM).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		NOTIFICATION_MOUSE_EXIT:
			if _is_hovered and not locked:
				var tween = create_tween()
				tween.tween_property(self, "position:y", position.y + 3, DesignTokens.DUR_ENTRANCE_SM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_is_hovered = false
			add_theme_stylebox_override("panel", _style_normal)
