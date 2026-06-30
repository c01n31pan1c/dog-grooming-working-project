class_name DGCJudgeCard
extends PanelContainer

## JudgeCard - a competition judge on the pre-show panel.
## Avatar + name + preference (revealed/hidden) + reveal button.

signal reveal_pressed

@export var judge_name: String = "Judge":
	set(value):
		judge_name = value
		if _name_label:
			_name_label.text = value

@export var glyph: String = "\U0001F9D1\u200D\u2696\uFE0F":
	set(value):
		glyph = value
		if _avatar_label:
			_avatar_label.text = value

@export var preference: String = "":
	set(value):
		preference = value
		_update_state()

@export var revealed: bool = false:
	set(value):
		revealed = value
		_update_state()

@export var reveal_cost: int = 50:
	set(value):
		reveal_cost = value
		if _reveal_button:
			_reveal_button.text = "\U0001F441 Reveal \u00B7 \U0001fa99 " + str(value)

var _avatar_label: Label
var _name_label: Label
var _preference_label: Label
var _hidden_label: Label
var _reveal_button: Button
var _info_vbox: VBoxContainer
var _pref_container: Control

func _ready() -> void:
	# Panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DesignTokens.BLUE_PANEL
	panel_style.border_color = DesignTokens.BLUE_LINE
	panel_style.set_border_width_all(DesignTokens.BORDER_THIN)
	panel_style.set_corner_radius_all(DesignTokens.RADIUS_PANEL)
	panel_style.shadow_color = Color(0, 0, 0, 0.06)
	panel_style.shadow_size = 4
	panel_style.shadow_offset = Vector2(0, 2)
	panel_style.set_content_margin_all(DesignTokens.SPACE[4])
	add_theme_stylebox_override("panel", panel_style)

	# Main HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", DesignTokens.SPACE[4])
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	# Avatar circle
	var avatar_panel = PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(64, 64)
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = DesignTokens.BLUE_SKY
	avatar_style.set_corner_radius_all(DesignTokens.RADIUS_PILL)
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)
	hbox.add_child(avatar_panel)

	var avatar_center = CenterContainer.new()
	avatar_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar_panel.add_child(avatar_center)

	_avatar_label = Label.new()
	_avatar_label.text = glyph
	_avatar_label.add_theme_font_size_override("font_size", 34)
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_center.add_child(_avatar_label)

	# Info VBox
	_info_vbox = VBoxContainer.new()
	_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(_info_vbox)

	# Name
	_name_label = Label.new()
	_name_label.text = judge_name
	_name_label.add_theme_font_size_override("font_size", DesignTokens.FS_H3)
	_name_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_bold:
		_name_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	_info_vbox.add_child(_name_label)

	# Preference container
	_pref_container = HBoxContainer.new()
	_info_vbox.add_child(_pref_container)

	# Revealed preference (mint pill)
	_preference_label = Label.new()
	_preference_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_preference_label.add_theme_color_override("font_color", DesignTokens.INK)
	if DesignTokens.font_body_bold:
		_preference_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	_pref_container.add_child(_preference_label)

	# Hidden label
	_hidden_label = Label.new()
	_hidden_label.text = "Preference hidden"
	_hidden_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_hidden_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)
	if DesignTokens.font_body_semibold:
		_hidden_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
	_pref_container.add_child(_hidden_label)

	# Reveal button
	_reveal_button = Button.new()
	_reveal_button.text = "\U0001F441 Reveal \u00B7 \U0001fa99 " + str(reveal_cost)
	_reveal_button.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_reveal_button.add_theme_color_override("font_color", DesignTokens.INK)
	if DesignTokens.font_display_bold:
		_reveal_button.add_theme_font_override("font", DesignTokens.font_display_bold)

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = DesignTokens.YELLOW
	btn_normal.border_color = DesignTokens.GOLD
	btn_normal.set_border_width_all(DesignTokens.BORDER_THICK)
	btn_normal.set_corner_radius_all(DesignTokens.RADIUS_BUTTON)
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	_reveal_button.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = DesignTokens.GOLD
	_reveal_button.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = DesignTokens.GOLD_PRESS
	_reveal_button.add_theme_stylebox_override("pressed", btn_pressed)

	_reveal_button.pressed.connect(_on_reveal_pressed)
	hbox.add_child(_reveal_button)

	_update_state()

func _update_state() -> void:
	if not _preference_label:
		return

	if revealed:
		_preference_label.text = "Favors: " + preference
		_preference_label.visible = true
		_hidden_label.visible = false
		_reveal_button.visible = false

		# Apply mint pill background via a PanelContainer wrapper if not done
		# We'll use a stylebox on the label's parent
		if not _preference_label.get_parent() is PanelContainer:
			_apply_mint_pill()
	else:
		_preference_label.visible = false
		_hidden_label.visible = true
		_reveal_button.visible = true

func _apply_mint_pill() -> void:
	# Wrap preference label in a mint pill
	var parent = _preference_label.get_parent()
	parent.remove_child(_preference_label)

	var pill = PanelContainer.new()
	var pill_style = StyleBoxFlat.new()
	pill_style.bg_color = DesignTokens.MINT
	pill_style.set_corner_radius_all(DesignTokens.RADIUS_PILL)
	pill_style.content_margin_left = 14
	pill_style.content_margin_right = 14
	pill_style.content_margin_top = 6
	pill_style.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", pill_style)
	pill.add_child(_preference_label)
	parent.add_child(pill)
	parent.move_child(pill, 0)

func _on_reveal_pressed() -> void:
	reveal_pressed.emit()
