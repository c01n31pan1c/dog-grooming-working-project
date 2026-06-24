## Toolbar — Displays available grooming tools as selectable buttons.
## Positioned at the bottom of the screen for mobile-friendly thumb reach.
## Listens to ToolSystem for available tools, calls GroomingInput.set_active_tool()
## when a tool is tapped.
class_name Toolbar
extends PanelContainer

## Reference to the ToolSystem (set via setup()).
var _tool_system: ToolSystem = null

## Reference to the GroomingInput handler (set via setup()).
var _input_handler: GroomingInput = null

## Container for tool buttons.
var _button_container: HBoxContainer = null

## Map of tool resource path -> Button node for highlighting.
var _tool_buttons: Dictionary = {}

## The currently highlighted button.
var _active_button: Button = null

## Style constants.
const BUTTON_MIN_SIZE := Vector2(80, 80)
const ACTIVE_COLOR := Color(1.0, 0.878, 0.4, 1.0)
const INACTIVE_COLOR := Color(0.941, 0.969, 1.0, 1.0)


func _ready() -> void:
	# Anchor to bottom of screen.
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -100.0
	offset_bottom = 0.0
	offset_left = 0.0
	offset_right = 0.0

	# Create internal layout.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_button_container = HBoxContainer.new()
	_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_button_container)

	# Listen for tool selection events from EventBus.
	EventBus.tool_selected.connect(_on_tool_selected)


## Initialize with references to the systems this toolbar interacts with.
func setup(tool_system: ToolSystem, input_handler: GroomingInput) -> void:
	_tool_system = tool_system
	_input_handler = input_handler
	_rebuild_buttons()


## Rebuild tool buttons from the ToolSystem's available tools.
func _rebuild_buttons() -> void:
	# Clear existing buttons.
	for child in _button_container.get_children():
		child.queue_free()
	_tool_buttons.clear()
	_active_button = null

	if _tool_system == null:
		return

	var tools := _tool_system.get_available_tools()

	# Sort tools by type for consistent ordering.
	tools.sort_custom(_sort_tools)

	for tool_data in tools:
		var btn := Button.new()
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.text = _get_button_label(tool_data)
		btn.tooltip_text = tool_data.description

		# Store tool reference on the button for the callback.
		btn.set_meta("tool_data", tool_data)
		btn.pressed.connect(_on_tool_button_pressed.bind(btn))

		_button_container.add_child(btn)
		_tool_buttons[tool_data.resource_path] = btn


## Generate a short label for a tool button.
func _get_button_label(tool_data: ToolData) -> String:
	match tool_data.tool_type:
		ToolData.ToolType.CLIPPER:
			# Show guard size for clippers.
			return "Clip\n%s\"" % str(tool_data.guard_size)
		ToolData.ToolType.BRUSH:
			return "Brush"
		ToolData.ToolType.DRYER:
			return "Dryer"
		ToolData.ToolType.SCISSORS:
			return "Scissors"
		ToolData.ToolType.NAIL_TRIMMER:
			return "Nails"
		ToolData.ToolType.SHAMPOO:
			return "Shampoo"
		ToolData.ToolType.COLOGNE:
			return "Cologne"
		ToolData.ToolType.MEDICINE:
			return "Meds"
	return tool_data.tool_name


## Sort tools by type enum value, then by guard size.
func _sort_tools(a: ToolData, b: ToolData) -> bool:
	if a.tool_type != b.tool_type:
		return a.tool_type < b.tool_type
	return a.guard_size < b.guard_size


## Called when a tool button is pressed.
func _on_tool_button_pressed(button: Button) -> void:
	var tool_data: ToolData = button.get_meta("tool_data") as ToolData
	if tool_data == null:
		return

	if _tool_system != null:
		_tool_system.select_tool(tool_data)

	if _input_handler != null:
		_input_handler.set_active_tool(tool_data)

	_highlight_button(button)


## Highlight the active tool button, un-highlight others.
func _highlight_button(button: Button) -> void:
	# Reset previous active button.
	if _active_button != null and is_instance_valid(_active_button):
		_active_button.modulate = INACTIVE_COLOR

	_active_button = button
	button.modulate = ACTIVE_COLOR


## Called when a tool is selected via EventBus (e.g., from code, not UI).
func _on_tool_selected(tool_data: Resource) -> void:
	if tool_data == null:
		return
	var td: ToolData = tool_data as ToolData
	if td == null:
		return
	if _tool_buttons.has(td.resource_path):
		var btn: Button = _tool_buttons[td.resource_path] as Button
		_highlight_button(btn)
		if _input_handler != null:
			_input_handler.set_active_tool(td)
