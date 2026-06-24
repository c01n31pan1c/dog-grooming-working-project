## ToolSystem — Manages available tools, ownership, and tool selection.
## Loads tool resources from resources/tools/, tracks player-owned tools,
## and emits selection events through EventBus.
class_name ToolSystem
extends Node

const TOOLS_DIR := "res://resources/tools/"

## All tool resources loaded from disk.
var _all_tools: Array[ToolData] = []

## Tools the player currently owns (keyed by resource path for dedup).
var _owned_tool_paths: Dictionary = {}

## Currently selected tool.
var _selected_tool: ToolData = null


func _ready() -> void:
	_load_tools()
	_grant_starter_tools()


## Load all .tres ToolData resources from the tools directory.
func _load_tools() -> void:
	var dir := DirAccess.open(TOOLS_DIR)
	if dir == null:
		push_warning("ToolSystem: Could not open tools directory: %s" % TOOLS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var path := TOOLS_DIR + file_name.replace(".remap", "")
			var res := ResourceLoader.load(path)
			if res is ToolData:
				_all_tools.append(res as ToolData)
		file_name = dir.get_next()
	dir.list_dir_end()


## Grant all tier-0 / price-0 tools as starter tools.
## Consumables (price > 0) are also granted for MVP so the player
## has a complete toolkit from the start.
func _grant_starter_tools() -> void:
	for tool_res in _all_tools:
		var td: ToolData = tool_res as ToolData
		_owned_tool_paths[td.resource_path] = td


## Check if the player owns a specific tool.
func owns_tool(tool_data: ToolData) -> bool:
	return _owned_tool_paths.has(tool_data.resource_path)


## Add a tool to the player's inventory.
func grant_tool(tool_data: ToolData) -> void:
	_owned_tool_paths[tool_data.resource_path] = tool_data


## Remove a tool from the player's inventory.
func revoke_tool(tool_data: ToolData) -> void:
	_owned_tool_paths.erase(tool_data.resource_path)


## Return all tools the player owns.
func get_available_tools() -> Array[ToolData]:
	var result: Array[ToolData] = []
	for path in _owned_tool_paths:
		result.append(_owned_tool_paths[path] as ToolData)
	return result


## Return owned tools filtered by ToolType.
func get_tools_by_type(type: ToolData.ToolType) -> Array[ToolData]:
	var result: Array[ToolData] = []
	for path in _owned_tool_paths:
		var td: ToolData = _owned_tool_paths[path] as ToolData
		if td.tool_type == type:
			result.append(td)
	return result


## Select a tool as active. Emits EventBus.tool_selected.
func select_tool(tool_data: ToolData) -> void:
	if tool_data != null and not owns_tool(tool_data):
		push_warning("ToolSystem: Tried to select unowned tool: %s" % tool_data.tool_name)
		return
	_selected_tool = tool_data
	EventBus.tool_selected.emit(tool_data)


## Get the currently selected tool.
func get_selected_tool() -> ToolData:
	return _selected_tool
