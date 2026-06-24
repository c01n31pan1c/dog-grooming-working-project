## HUD — In-game overlay during grooming sessions.
## Implemented as a CanvasLayer so it renders above the 3D scene.
## Listens to EventBus signals for reactive updates.
extends CanvasLayer

## Timer
@onready var timer_label: Label = %TimerLabel
## Tool indicator
@onready var tool_name_label: Label = %ToolNameLabel
@onready var tool_icon: TextureRect = %ToolIcon
## Progress
@onready var progress_bar: ProgressBar = %GroomingProgressBar
@onready var progress_label: Label = %ProgressLabel
## Coin balance
@onready var coin_label: Label = %HUDCoinLabel
## Buttons
@onready var guide_toggle_button: Button = %GuideToggleButton
@onready var pause_button: Button = %PauseButton

## Total zones expected in the current grooming session.
var total_zones: int = 1
## Zones completed so far.
var zones_completed: int = 0
## Remaining time in seconds — set by the grooming system.
var time_remaining: float = 0.0
## Total session time for urgency calculation.
var time_total: float = 1.0
## Whether the grooming guide overlay is visible.
var guide_visible: bool = false

## Timer urgency color thresholds (fraction of total time).
const URGENCY_YELLOW_THRESHOLD := 0.4
const URGENCY_RED_THRESHOLD := 0.15
## Colors for timer urgency.
const COLOR_NORMAL := Color.WHITE
const COLOR_YELLOW := Color(1.0, 0.85, 0.1)
const COLOR_RED := Color(1.0, 0.2, 0.2)


func _ready() -> void:
	layer = 10  # Render above most things

	# Connect EventBus signals
	EventBus.zone_groomed.connect(_on_zone_groomed)
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.currency_changed.connect(_on_currency_changed)

	# Button connections
	guide_toggle_button.pressed.connect(_on_guide_toggle_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

	# Initialize display
	_update_coin_display()
	_update_progress_display()
	_update_timer_display()
	tool_name_label.text = "None"


func _process(delta: float) -> void:
	if time_remaining > 0.0:
		time_remaining -= delta
		time_remaining = maxf(time_remaining, 0.0)
		_update_timer_display()


## Called by the grooming system to configure the HUD for a session.
func setup_session(session_time: float, zone_count: int) -> void:
	time_total = session_time
	time_remaining = session_time
	total_zones = maxi(zone_count, 1)
	zones_completed = 0
	_update_timer_display()
	_update_progress_display()


func _update_timer_display() -> void:
	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

	# Urgency coloring
	var fraction := time_remaining / maxf(time_total, 0.01)
	if fraction <= URGENCY_RED_THRESHOLD:
		timer_label.add_theme_color_override("font_color", COLOR_RED)
	elif fraction <= URGENCY_YELLOW_THRESHOLD:
		timer_label.add_theme_color_override("font_color", COLOR_YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", COLOR_NORMAL)


func _update_progress_display() -> void:
	var pct := (float(zones_completed) / float(total_zones)) * 100.0
	progress_bar.value = pct
	progress_label.text = "%d / %d" % [zones_completed, total_zones]


func _update_coin_display() -> void:
	var coins: int = SaveManager.data.get("currency", 0)
	coin_label.text = str(coins)


func _on_zone_groomed(_zone_id: String, _tool_data: Resource) -> void:
	zones_completed += 1
	_update_progress_display()


func _on_tool_selected(tool_data: Resource) -> void:
	if tool_data != null and tool_data is ToolData:
		var td := tool_data as ToolData
		tool_name_label.text = td.tool_name if td.tool_name != "" else "Tool"
	else:
		tool_name_label.text = "None"


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_coin_display()


func _on_guide_toggle_pressed() -> void:
	guide_visible = not guide_visible
	guide_toggle_button.text = "Guide: ON" if guide_visible else "Guide: OFF"
	# Other systems can check this flag or we can emit a signal
	# For now the grooming system should query hud.guide_visible


func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
	pause_button.text = "Resume" if get_tree().paused else "Pause"
