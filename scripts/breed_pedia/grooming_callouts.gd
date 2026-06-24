## GroomingCallouts — Displays contextual breed facts during grooming sessions.
## Shows non-intrusive text popups in the corner of the screen that auto-dismiss.
## Facts cycle without repeating within a single grooming session.
class_name GroomingCallouts
extends CanvasLayer

## How long each callout stays visible (seconds).
const DISPLAY_DURATION: float = 4.0
## Fade animation duration (seconds).
const FADE_DURATION: float = 0.5
## Minimum time between callouts (seconds).
const COOLDOWN: float = 8.0

var _current_breed: Resource = null
var _shown_indices: Array[int] = []
var _callout_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _is_showing: bool = false

@onready var _panel: PanelContainer = $Panel
@onready var _label: Label = $Panel/MarginContainer/FactLabel
@onready var _tween: Tween = null


func _ready() -> void:
	layer = 10
	_panel.modulate.a = 0.0
	_panel.visible = false

	EventBus.grooming_started.connect(_on_grooming_started)
	EventBus.grooming_completed.connect(_on_grooming_completed)
	EventBus.zone_groomed.connect(_on_zone_groomed)


func _process(delta: float) -> void:
	if _is_showing:
		_callout_timer -= delta
		if _callout_timer <= 0.0:
			_hide_callout()
	elif _cooldown_timer > 0.0:
		_cooldown_timer -= delta


func _on_grooming_started(breed_data: Resource) -> void:
	_current_breed = breed_data
	_shown_indices.clear()


func _on_grooming_completed(_breed_data: Resource, _results: Dictionary) -> void:
	_current_breed = null
	_shown_indices.clear()
	_hide_callout()


func _on_zone_groomed(_zone_id: String, _tool_data: Resource) -> void:
	if _current_breed == null:
		return
	if _is_showing or _cooldown_timer > 0.0:
		return
	_show_random_fact()


## Show a random fact from the current breed that hasn't been shown this session.
func _show_random_fact() -> void:
	if _current_breed == null:
		return

	var facts: Array = _current_breed.grooming_facts
	if facts.is_empty():
		return

	# Build list of unshown indices
	var available: Array[int] = []
	for i in range(facts.size()):
		if i not in _shown_indices:
			available.append(i)

	# If all facts shown, reset cycle
	if available.is_empty():
		_shown_indices.clear()
		for i in range(facts.size()):
			available.append(i)

	var idx: int = available[randi() % available.size()]
	_shown_indices.append(idx)

	_display_callout(facts[idx])


## The original X position of the panel (cached for slide animations).
var _panel_origin_x: float = 0.0
var _panel_origin_cached: bool = false

## Display a fact string as a callout popup with slide-in + bounce.
func _display_callout(fact_text: String) -> void:
	_label.text = fact_text
	_panel.visible = true
	_is_showing = true
	_callout_timer = DISPLAY_DURATION

	# Cache origin position on first use
	if not _panel_origin_cached:
		_panel_origin_x = _panel.position.x
		_panel_origin_cached = true

	# Slide in from the left with bounce + fade in
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_panel.position.x = _panel_origin_x - 300.0
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "position:x", _panel_origin_x, FADE_DURATION + 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_panel, "modulate:a", 1.0, FADE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## Hide the current callout with slide out + fade.
func _hide_callout() -> void:
	_is_showing = false
	_cooldown_timer = COOLDOWN

	if not _panel_origin_cached:
		_panel_origin_x = _panel.position.x
		_panel_origin_cached = true

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "position:x", _panel_origin_x - 300.0, FADE_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.chain().tween_callback(_panel.set.bind("visible", false))


## Manually trigger a callout for a specific fact string.
func show_specific_fact(fact_text: String) -> void:
	_display_callout(fact_text)


## Force show a fact for the current breed (used by external systems).
func trigger_fact() -> void:
	_show_random_fact()
