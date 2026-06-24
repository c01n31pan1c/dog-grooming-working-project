## ToolSystem — Manages available tools and tool selection.
## Stub for WS-3.
class_name ToolSystem
extends Node

var available_tools: Array[Resource] = []
var selected_tool: Resource = null


func select_tool(tool_data: Resource) -> void:
	selected_tool = tool_data
	EventBus.tool_selected.emit(tool_data)


func get_available_tools() -> Array[Resource]:
	return available_tools
