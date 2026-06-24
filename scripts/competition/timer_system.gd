## TimerSystem — Manages competition countdown timer with warnings and time bonus.
class_name TimerSystem
extends Node

signal timer_started(duration: float)
signal timer_tick(seconds_remaining: float)
signal timer_warning(seconds_remaining: float)
signal timer_expired()

## Total duration for the current competition round.
var _duration: float = 120.0
## Seconds remaining on the clock.
var _remaining: float = 0.0
## Whether the timer is actively counting down.
var _running: bool = false
## Whether the timer is paused (distinct from not running — paused can resume).
var _paused: bool = false
## Whether the warning signal has already been emitted this round.
var _warning_emitted: bool = false

## Fraction of total time below which a warning fires.
const WARNING_THRESHOLD: float = 0.3


func _process(delta: float) -> void:
	if not _running or _paused:
		return

	_remaining -= delta

	if _remaining <= 0.0:
		_remaining = 0.0
		_running = false
		timer_tick.emit(_remaining)
		timer_expired.emit()
		return

	timer_tick.emit(_remaining)

	# Emit warning once when remaining time drops below threshold.
	if not _warning_emitted and _remaining / _duration <= WARNING_THRESHOLD:
		_warning_emitted = true
		timer_warning.emit(_remaining)


## Start (or restart) the countdown with the given duration in seconds.
func start_timer(duration: float) -> void:
	_duration = maxf(duration, 1.0)
	_remaining = _duration
	_running = true
	_paused = false
	_warning_emitted = false
	timer_started.emit(_duration)


## Stop the timer entirely. Cannot be resumed — use pause/resume for that.
func stop_timer() -> void:
	_running = false
	_paused = false


## Pause the countdown. Timer can be resumed later.
func pause() -> void:
	if _running:
		_paused = true


## Resume a paused countdown.
func resume() -> void:
	if _running:
		_paused = false


## Returns true if the timer is actively counting down (not paused, not stopped).
func is_running() -> bool:
	return _running and not _paused


## Returns true if the timer is paused.
func is_paused() -> bool:
	return _running and _paused


## Current remaining seconds.
func get_remaining() -> float:
	return _remaining


## Total duration that was set when the timer started.
func get_duration() -> float:
	return _duration


## Calculate the time bonus as a 0-100 score.
## max_time_bonus is the maximum points awardable for finishing with full time left.
func calculate_time_bonus(max_time_bonus: float = 100.0) -> float:
	if _duration <= 0.0:
		return 0.0
	return (_remaining / _duration) * max_time_bonus
