## CompetitionScreen — Manages the full competition flow: pre-show, grooming, and results.
## Drives the UI in scenes/competition.tscn.
extends Node

enum Phase {
	PRE_SHOW,
	GROOMING,
	RESULTS,
}

var current_phase: Phase = Phase.PRE_SHOW

## The active competition data (set via GameManager.transition_context or defaults).
var competition_data: CompetitionData = null

## Which judges have had their preferences revealed (by index).
var revealed_judges: Array[int] = []

## Player coin balance — read from GameManager.transition_context or default.
var player_coins: int = 0

## Grooming results received from GroomingController via EventBus.
var grooming_results: Dictionary = {}

## Style extras applied during grooming.
var style_extras: Dictionary = {"cologne": false, "accessories": [], "medicine": false, "medicine_needed": false}

## Scoring systems (child nodes).
@onready var timer_system: TimerSystem = $TimerSystem
@onready var scoring_engine: ScoringEngine = $ScoringEngine
@onready var judge_ai: JudgeAI = $JudgeAI

## UI references.
@onready var ui: Control = $UI
@onready var pre_show_panel: Control = $UI/PreShowPanel
@onready var grooming_panel: Control = $UI/GroomingPanel
@onready var results_panel: Control = $UI/ResultsPanel

## Pre-show UI elements.
@onready var competition_name_label: Label = $UI/PreShowPanel/CompetitionName
@onready var tier_label: Label = $UI/PreShowPanel/TierLabel
@onready var breed_label: Label = $UI/PreShowPanel/BreedLabel
@onready var time_limit_label: Label = $UI/PreShowPanel/TimeLimitLabel
@onready var entry_fee_label: Label = $UI/PreShowPanel/EntryFeeLabel
@onready var judges_container: VBoxContainer = $UI/PreShowPanel/JudgesContainer
@onready var start_button: Button = $UI/PreShowPanel/StartButton

## Grooming UI elements.
@onready var timer_label: Label = $UI/GroomingPanel/TimerLabel
@onready var timer_warning_indicator: Control = $UI/GroomingPanel/TimerWarningIndicator

## Results UI elements.
@onready var results_container: VBoxContainer = $UI/ResultsPanel/ResultsContainer
@onready var total_score_label: Label = $UI/ResultsPanel/TotalScoreLabel
@onready var placement_label: Label = $UI/ResultsPanel/PlacementLabel
@onready var reward_label: Label = $UI/ResultsPanel/RewardLabel
@onready var continue_button: Button = $UI/ResultsPanel/ContinueButton

## Placement thresholds — panel scores map to placements.
const PLACEMENT_THRESHOLDS := {1: 80.0, 2: 60.0, 3: 40.0}

## Default reward table if competition_data does not specify one.
const DEFAULT_REWARDS := {1: 100, 2: 60, 3: 30}


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.COMPETITION

	# Load competition data from transition context or create a default.
	var context: Dictionary = GameManager.transition_context
	if context.has("competition_data"):
		competition_data = context["competition_data"] as CompetitionData
	player_coins = context.get("player_coins", 0)

	# Connect signals.
	timer_system.timer_tick.connect(_on_timer_tick)
	timer_system.timer_warning.connect(_on_timer_warning)
	timer_system.timer_expired.connect(_on_timer_expired)
	EventBus.grooming_completed.connect(_on_grooming_completed)
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	_show_phase(Phase.PRE_SHOW)


## ── Phase management ────────────────────────────────────────────────────────

func _show_phase(phase: Phase) -> void:
	current_phase = phase
	pre_show_panel.visible = (phase == Phase.PRE_SHOW)
	grooming_panel.visible = (phase == Phase.GROOMING)
	results_panel.visible = (phase == Phase.RESULTS)

	match phase:
		Phase.PRE_SHOW:
			_populate_pre_show()
		Phase.RESULTS:
			_populate_results()


## ── Pre-show ────────────────────────────────────────────────────────────────

func _populate_pre_show() -> void:
	if competition_data == null:
		competition_name_label.text = "No Competition Loaded"
		return

	competition_name_label.text = competition_data.competition_name
	tier_label.text = "Tier: %s" % competition_data.get_tier_name()
	time_limit_label.text = "Time: %ds" % int(competition_data.time_limit_seconds)
	entry_fee_label.text = "Entry Fee: %d coins" % competition_data.entry_fee

	if competition_data.breed != null:
		breed_label.text = "Breed: %s" % competition_data.breed.breed_name
	else:
		breed_label.text = "Breed: TBD"

	_populate_judges_list()


func _populate_judges_list() -> void:
	# Clear existing children.
	for child in judges_container.get_children():
		child.queue_free()

	if competition_data == null:
		return

	for i in range(competition_data.judges.size()):
		var judge: JudgeData = competition_data.judges[i]
		var judge_row := HBoxContainer.new()

		var name_label := Label.new()
		name_label.text = judge.judge_name

		var info_label := Label.new()
		if i in revealed_judges:
			var w: Dictionary = judge.scoring_weights
			info_label.text = " — Accuracy: %.0f%%, Time: %.0f%%, Style: %.0f%% | %s" % [
				w.get("accuracy", 0.0) * 100.0,
				w.get("time", 0.0) * 100.0,
				w.get("style", 0.0) * 100.0,
				judge.preferred_style,
			]
		else:
			info_label.text = " — Preferences hidden"

		judge_row.add_child(name_label)
		judge_row.add_child(info_label)

		# Add reveal button if not yet revealed.
		if i not in revealed_judges:
			var reveal_btn := Button.new()
			reveal_btn.text = "Reveal (%d coins)" % judge.reveal_cost
			reveal_btn.disabled = (player_coins < judge.reveal_cost)
			# Capture index for the lambda.
			var idx := i
			reveal_btn.pressed.connect(func() -> void: _on_reveal_pressed(idx))
			judge_row.add_child(reveal_btn)

		judges_container.add_child(judge_row)


func _on_reveal_pressed(judge_index: int) -> void:
	if competition_data == null:
		return
	var judge: JudgeData = competition_data.judges[judge_index]
	if player_coins >= judge.reveal_cost:
		player_coins -= judge.reveal_cost
		revealed_judges.append(judge_index)
		EventBus.currency_changed.emit(player_coins, -judge.reveal_cost)
		_populate_judges_list()


func _on_start_pressed() -> void:
	if competition_data == null:
		return

	# Deduct entry fee.
	if player_coins >= competition_data.entry_fee:
		player_coins -= competition_data.entry_fee
		EventBus.currency_changed.emit(player_coins, -competition_data.entry_fee)

	# Start grooming phase.
	_show_phase(Phase.GROOMING)
	timer_system.start_timer(competition_data.time_limit_seconds)
	timer_warning_indicator.visible = false

	EventBus.competition_started.emit({
		"competition_name": competition_data.competition_name,
		"breed": competition_data.breed,
		"time_limit": competition_data.time_limit_seconds,
	})


## ── Grooming phase ──────────────────────────────────────────────────────────

func _on_timer_tick(seconds_remaining: float) -> void:
	if current_phase != Phase.GROOMING:
		return
	var minutes := int(seconds_remaining) / 60
	var seconds := int(seconds_remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _on_timer_warning(_seconds_remaining: float) -> void:
	if current_phase != Phase.GROOMING:
		return
	timer_warning_indicator.visible = true


func _on_timer_expired() -> void:
	if current_phase != Phase.GROOMING:
		return
	_finish_grooming()


func _on_grooming_completed(_breed_data: Resource, results: Dictionary) -> void:
	grooming_results = results
	style_extras = results.get("style_extras", style_extras)
	if current_phase == Phase.GROOMING:
		_finish_grooming()


func _finish_grooming() -> void:
	timer_system.stop_timer()
	_show_phase(Phase.RESULTS)


## ── Results phase ───────────────────────────────────────────────────────────

func _populate_results() -> void:
	if competition_data == null:
		return

	# Clear previous results.
	for child in results_container.get_children():
		child.queue_free()

	# Calculate scores.
	var time_bonus := timer_system.calculate_time_bonus(100.0)
	var score_breakdown := scoring_engine.calculate_score(
		grooming_results,
		competition_data.breed,
		time_bonus,
		style_extras,
	)

	# Get panel judgement.
	var panel_result := judge_ai.calculate_panel_score(
		score_breakdown,
		competition_data.judges,
	)

	var panel_score: float = panel_result["panel_score"]
	var judge_results: Array = panel_result["judge_results"]

	# Display per-judge breakdown.
	for jr in judge_results:
		var judge_block := VBoxContainer.new()

		var header := Label.new()
		header.text = "%s — Score: %.1f" % [jr["judge_name"], jr["weighted_score"]]
		judge_block.add_child(header)

		for comment in jr["comments"]:
			var comment_label := Label.new()
			comment_label.text = "  \"%s\"" % comment
			judge_block.add_child(comment_label)

		if not (jr["liked"] as Array).is_empty():
			var liked_label := Label.new()
			liked_label.text = "  Liked: %s" % ", ".join(jr["liked"])
			judge_block.add_child(liked_label)

		if not (jr["disliked"] as Array).is_empty():
			var disliked_label := Label.new()
			disliked_label.text = "  Disliked: %s" % ", ".join(jr["disliked"])
			judge_block.add_child(disliked_label)

		results_container.add_child(judge_block)

	# Determine placement.
	var placement := 4  # No placement by default.
	for rank in [1, 2, 3]:
		if panel_score >= PLACEMENT_THRESHOLDS[rank]:
			placement = rank
			break

	total_score_label.text = "Total Score: %.1f" % panel_score

	if placement <= 3:
		var ordinals := {1: "1st", 2: "2nd", 3: "3rd"}
		placement_label.text = "Placement: %s Place!" % ordinals[placement]
	else:
		placement_label.text = "No placement this time."

	# Award coins.
	var reward: int = competition_data.get_reward(placement)
	if reward > 0:
		player_coins += reward
		EventBus.currency_changed.emit(player_coins, reward)
		reward_label.text = "Earned: %d coins!" % reward
	else:
		reward_label.text = "No coin reward."

	# Emit competition ended.
	EventBus.competition_ended.emit({
		"panel_score": panel_score,
		"placement": placement,
		"reward": reward,
		"judge_results": judge_results,
		"score_breakdown": score_breakdown,
	})


func _on_continue_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)
