## GroomingInput — Base class for grooming input strategies (ADR-008).
## Subclasses implement specific input modes (tap-select, gesture, etc.).
## GroomingController consumes this interface, never concrete implementations.
class_name GroomingInput
extends Node

## Emitted when the player applies a tool to a grooming zone.
signal tool_applied(zone_id: String, tool_data: Resource)

## Emitted when the player's pointer (finger/mouse) moves.
signal pointer_moved(position: Vector2)

## The currently selected tool.
var _active_tool: Resource = null


## Set which tool is currently active for application.
func set_active_tool(tool: Resource) -> void:
	_active_tool = tool


## Get the currently active tool.
func get_active_tool() -> Resource:
	return _active_tool
