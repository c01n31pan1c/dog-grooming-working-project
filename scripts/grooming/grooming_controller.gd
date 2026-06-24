## GroomingController — Connects input strategy to tool system and zone detection.
## Consumes GroomingInput interface only (never concrete input classes).
## Stub for WS-3 to flesh out.
class_name GroomingController
extends Node

var _input_handler: GroomingInput = null


func set_input_handler(handler: GroomingInput) -> void:
	if _input_handler != null:
		_input_handler.tool_applied.disconnect(_on_tool_applied)
		_input_handler.pointer_moved.disconnect(_on_pointer_moved)

	_input_handler = handler
	_input_handler.tool_applied.connect(_on_tool_applied)
	_input_handler.pointer_moved.connect(_on_pointer_moved)


func _on_tool_applied(zone_id: String, tool_data: Resource) -> void:
	# WS-3 implements full tool-zone interaction logic here
	EventBus.zone_groomed.emit(zone_id, tool_data)


func _on_pointer_moved(_position: Vector2) -> void:
	# WS-3 implements hover/highlight feedback here
	pass
