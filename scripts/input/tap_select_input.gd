## TapSelectInput — Tap-to-select-tool, tap-zone-to-apply input mode.
## MVP input strategy per ADR-008. Player selects a tool from the toolbar,
## then taps on dog grooming zones to apply it.
class_name TapSelectInput
extends GroomingInput


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventScreenDrag:
		pointer_moved.emit((event as InputEventScreenDrag).position)
	elif event is InputEventMouseMotion:
		pointer_moved.emit((event as InputEventMouseMotion).position)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_try_apply_at(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_apply_at(event.position)


## Attempt to apply the active tool at the given screen position.
## Zone detection will be handled by the GroomingController / zone system;
## this emits the signal with a placeholder zone_id resolved upstream.
func _try_apply_at(screen_position: Vector2) -> void:
	if _active_tool == null:
		return

	# In the full implementation, this will raycast into the 3D scene
	# to determine which grooming zone was tapped. For now, emit with
	# position data so the controller can resolve the zone.
	pointer_moved.emit(screen_position)

	# The zone_id will be resolved by GroomingController via raycasting.
	# For the scaffold, we emit a placeholder that downstream systems
	# will replace with actual zone detection (WS-2/WS-3).
	tool_applied.emit("unresolved", _active_tool)
