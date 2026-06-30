class_name DGCShopItem
extends PanelContainer

## ShopItem - a purchasable row in the Shop.
## Glyph tile + name/desc + price/owned badge.

signal buy_pressed

@export var glyph: String = "\U0001FAE7":
	set(value):
		glyph = value
		if _glyph_label:
			_glyph_label.text = value

@export var item_name: String = "Item":
	set(value):
		item_name = value
		if _name_label:
			_name_label.text = value

@export var description: String = "":
	set(value):
		description = value
		if _desc_label:
			_desc_label.text = value
			_desc_label.visible = value != ""

@export var price: int = 0:
	set(value):
		price = value
		if _buy_button:
			_buy_button.text = "\U0001fa99 " + _format_number(value)

@export var owned: bool = false:
	set(value):
		owned = value
		_update_state()

@export var affordable: bool = true:
	set(value):
		affordable = value
		_update_state()

var _glyph_label: Label
var _name_label: Label
var _desc_label: Label
var _buy_button: Button
var _owned_label: Label
var _right_container: Control

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

	# Glyph tile
	var glyph_panel = PanelContainer.new()
	glyph_panel.custom_minimum_size = Vector2(72, 72)
	var glyph_style = StyleBoxFlat.new()
	glyph_style.bg_color = DesignTokens.BLUE_SKY
	glyph_style.set_corner_radius_all(DesignTokens.RADIUS_PANEL)
	glyph_panel.add_theme_stylebox_override("panel", glyph_style)
	hbox.add_child(glyph_panel)

	var glyph_center = CenterContainer.new()
	glyph_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph_panel.add_child(glyph_center)

	_glyph_label = Label.new()
	_glyph_label.text = glyph
	_glyph_label.add_theme_font_size_override("font_size", 38)
	_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph_center.add_child(_glyph_label)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	_name_label = Label.new()
	_name_label.text = item_name
	_name_label.add_theme_font_size_override("font_size", DesignTokens.FS_H3)
	_name_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_bold:
		_name_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	info_vbox.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.text = description
	_desc_label.visible = description != ""
	_desc_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_desc_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)
	if DesignTokens.font_body_semibold:
		_desc_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
	info_vbox.add_child(_desc_label)

	# Right side container
	_right_container = Control.new()
	_right_container.custom_minimum_size = Vector2(120, 40)
	hbox.add_child(_right_container)

	# Owned badge
	_owned_label = Label.new()
	_owned_label.text = "Owned"
	_owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owned_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_owned_label.add_theme_font_size_override("font_size", DesignTokens.FS_LABEL)
	_owned_label.add_theme_color_override("font_color", DesignTokens.INK)
	if DesignTokens.font_display_bold:
		_owned_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	_owned_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_right_container.add_child(_owned_label)

	# Buy button
	_buy_button = Button.new()
	_buy_button.text = "\U0001fa99 " + _format_number(price)
	_buy_button.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_buy_button.add_theme_color_override("font_color", Color.WHITE)
	if DesignTokens.font_display_bold:
		_buy_button.add_theme_font_override("font", DesignTokens.font_display_bold)

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = DesignTokens.GOLD
	btn_normal.set_corner_radius_all(DesignTokens.RADIUS_BUTTON)
	btn_normal.set_content_margin_all(10)
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_right = 20
	_buy_button.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = DesignTokens.GOLD_DEEP
	_buy_button.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = DesignTokens.GOLD_PRESS
	_buy_button.add_theme_stylebox_override("pressed", btn_pressed)

	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color(DesignTokens.GOLD, 0.5)
	_buy_button.add_theme_stylebox_override("disabled", btn_disabled)

	_buy_button.pressed.connect(_on_buy_pressed)
	_buy_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_right_container.add_child(_buy_button)

	_update_state()

func _update_state() -> void:
	if not _buy_button:
		return
	_owned_label.visible = owned
	_buy_button.visible = not owned
	_buy_button.disabled = not affordable

func _on_buy_pressed() -> void:
	buy_pressed.emit()

func _format_number(val: int) -> String:
	var s = str(abs(val))
	var result = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	if val < 0:
		result = "-" + result
	return result
