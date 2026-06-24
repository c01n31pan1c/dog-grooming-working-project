## TimerSystem — Manages competition countdown timer.
## Stub for WS-4.
class_name TimerSystem
extends Node

signal time_updated(remaining: float)
signal time_expired()

var _duration: float = 120.0
var _remaining: float = 0.0
var _running: bool = false


func _process(delta: float) -> void:
	if not _running:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = 0.0
		_running = false
		time_expired.emit()
	time_updated.emit(_remaining)


func start_timer(duration: float) -> void:
	_duration = duration
	_remaining = duration
	_running = true


func stop_timer() -> void:
	_running = false


func get_remaining() -> float:
	return _remaining
