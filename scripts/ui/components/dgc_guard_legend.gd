class_name DGCGuardLegend
extends PanelContainer

## GuardLegend - the guard-size guide overlay legend from the grooming arena.
## Maps seven clip guard sizes to their fixed guide colors.

const GUARDS = [
	{"label": "Close clip (0\")", "color": DesignTokens.GUARD_0},
	{"label": "1/4 inch", "color": DesignTokens.GUARD_025},
	{"label": "1/2 inch", "color": DesignTokens.GUARD_05},
	{"label": "1 inch", "color": DesignTokens.GUARD_1},
	{"label": "2 inch", "color": DesignTokens.GUARD_2},
	{"label": "4 inch", "color": DesignTokens.GUARD_4},
	{"label": "6 inch (long)", "color": DesignTokens.GUARD_6},
]

@export var compact: bool = false:
	set(value):
		compact = value
		_rebuild()

var _title_label: Label
var _items_container: Container

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

	_rebuild()

func _rebuild() -> void:
	# Clear children
	for child in get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", DesignTokens.SPACE[3])
	add_child(main_vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "Guard Size Legend"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
	_title_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_bold:
		_title_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	main_vbox.add_child(_title_label)

	# Items container - FlowContainer for compact (horizontal wrap), VBox for normal
	if compact:
		_items_container = HFlowContainer.new()
		_items_container.add_theme_constant_override("h_separation", DesignTokens.SPACE[2])
		_items_container.add_theme_constant_override("v_separation", DesignTokens.SPACE[2])
	else:
		_items_container = VBoxContainer.new()
		_items_container.add_theme_constant_override("separation", DesignTokens.SPACE[2])
	main_vbox.add_child(_items_container)

	# Build items
	for guard in GUARDS:
		var item_hbox = HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", DesignTokens.SPACE[2])
		item_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Color swatch
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(18, 18)
		swatch.color = guard["color"]
		# We can't easily do rounded ColorRect, so wrap in a PanelContainer
		var swatch_panel = PanelContainer.new()
		swatch_panel.custom_minimum_size = Vector2(18, 18)
		var swatch_style = StyleBoxFlat.new()
		swatch_style.bg_color = guard["color"]
		swatch_style.set_corner_radius_all(5)
		# Subtle inner shadow
		swatch_style.border_color = Color(0, 0, 0, 0.08)
		swatch_style.set_border_width_all(1)
		swatch_panel.add_theme_stylebox_override("panel", swatch_style)
		item_hbox.add_child(swatch_panel)

		# Label
		var guard_label = Label.new()
		guard_label.text = guard["label"]
		guard_label.add_theme_font_size_override("font_size", DesignTokens.FS_SMALL)
		guard_label.add_theme_color_override("font_color", DesignTokens.INK)
		if DesignTokens.font_body_semibold:
			guard_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
		item_hbox.add_child(guard_label)

		_items_container.add_child(item_hbox)
