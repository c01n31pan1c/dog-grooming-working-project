## CompetitionScreen — Results display after a competition grooming session.
## Receives results via GameManager.transition_context and shows judge breakdown.
extends Node

## The competition data and results (set via GameManager.transition_context).
var competition_data: CompetitionData = null
var panel_result: Dictionary = {}
var score_breakdown: Dictionary = {}
var placement: int = 4
var reward: int = 0

## UI references.
@onready var results_container: VBoxContainer = $UI/ResultsPanel/ResultsContainer
@onready var total_score_label: Label = $UI/ResultsPanel/TotalScoreLabel
@onready var placement_label: Label = $UI/ResultsPanel/PlacementLabel
@onready var reward_label: Label = $UI/ResultsPanel/RewardLabel
@onready var continue_button: Button = $UI/ResultsPanel/ContinueButton


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.COMPETITION_RESULTS

	# Load results from transition context
	var context: Dictionary = GameManager.transition_context
	if context.has("competition_data"):
		competition_data = context["competition_data"] as CompetitionData
	panel_result = context.get("panel_result", {})
	score_breakdown = context.get("score_breakdown", {})
	placement = context.get("placement", 4)
	reward = context.get("reward", 0)

	continue_button.pressed.connect(_on_continue_pressed)
	UIAnimations.setup_button_juice(continue_button)

	# Hide panels not used in results-only mode
	var pre_show_panel := $UI/PreShowPanel as Control
	var grooming_panel := $UI/GroomingPanel as Control
	var results_panel := $UI/ResultsPanel as Control
	pre_show_panel.visible = false
	grooming_panel.visible = false
	results_panel.visible = true

	_populate_results()


func _populate_results() -> void:
	# Clear previous results.
	for child in results_container.get_children():
		child.queue_free()

	var panel_score: float = panel_result.get("panel_score", 0.0)
	var judge_results: Array = panel_result.get("judge_results", [])

	# Competition header
	if competition_data:
		var header := Label.new()
		header.text = competition_data.competition_name
		header.add_theme_font_size_override("font_size", 28)
		header.add_theme_color_override("font_color", Color(0.239, 0.239, 0.361))
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		results_container.add_child(header)

		var sep := HSeparator.new()
		results_container.add_child(sep)

	# Placement comment
	var placement_comment: String = panel_result.get("placement_comment", "")
	if placement_comment != "":
		var comment_label := Label.new()
		comment_label.text = placement_comment
		comment_label.add_theme_font_size_override("font_size", 20)
		comment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		results_container.add_child(comment_label)

	var sep2 := HSeparator.new()
	results_container.add_child(sep2)

	# Display per-judge breakdown with staggered slide-in
	var judge_index: int = 0
	for jr in judge_results:
		var judge_block := VBoxContainer.new()
		judge_block.add_theme_constant_override("separation", 4)

		var judge_header := Label.new()
		judge_header.text = "%s — Score: %.1f" % [jr.get("judge_name", "Judge"), jr.get("weighted_score", 0.0)]
		judge_header.add_theme_font_size_override("font_size", 22)
		judge_header.add_theme_color_override("font_color", Color(0.239, 0.239, 0.361))
		judge_block.add_child(judge_header)

		var comments: Array = jr.get("comments", [])
		for comment in comments:
			var comment_label := Label.new()
			comment_label.text = "  \"%s\"" % comment
			comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			comment_label.add_theme_font_size_override("font_size", 16)
			judge_block.add_child(comment_label)

		var liked: Array = jr.get("liked", [])
		if not liked.is_empty():
			var liked_label := Label.new()
			liked_label.text = "  Liked: %s" % ", ".join(PackedStringArray(liked))
			liked_label.add_theme_font_size_override("font_size", 16)
			liked_label.add_theme_color_override("font_color", Color(0.44, 0.78, 0.65))
			judge_block.add_child(liked_label)

		var disliked: Array = jr.get("disliked", [])
		if not disliked.is_empty():
			var disliked_label := Label.new()
			disliked_label.text = "  Disliked: %s" % ", ".join(PackedStringArray(disliked))
			disliked_label.add_theme_font_size_override("font_size", 16)
			disliked_label.add_theme_color_override("font_color", Color(1.0, 0.549, 0.486))
			judge_block.add_child(disliked_label)

		results_container.add_child(judge_block)

		# Staggered slide-in from the right for each judge section
		UIAnimations.slide_in_from_right(judge_block, 300.0, 0.5, 0.3 + judge_index * 0.2)
		judge_index += 1

	# Score breakdown
	var sep3 := HSeparator.new()
	results_container.add_child(sep3)

	var breakdown_label := Label.new()
	breakdown_label.text = "Accuracy: %.1f  |  Time: %.1f  |  Style: %.1f" % [
		score_breakdown.get("accuracy", 0.0),
		score_breakdown.get("time", 0.0),
		score_breakdown.get("style", 0.0),
	]
	breakdown_label.add_theme_font_size_override("font_size", 18)
	breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_container.add_child(breakdown_label)

	# Total score — number ticker from 0 to final value
	total_score_label.text = "Total Score: 0.0"
	var score_delay := 0.3 + judge_results.size() * 0.2 + 0.3
	UIAnimations.number_ticker(total_score_label, 0.0, panel_score, UIAnimations.DUR_SCORE_REVEAL, "Total Score: %.1f", score_delay)

	# Placement — scales up from 0 with big bounce
	if placement <= 3:
		var ordinals := {1: "1st", 2: "2nd", 3: "3rd"}
		placement_label.text = "Placement: %s Place!" % ordinals[placement]
	else:
		placement_label.text = "No placement this time."
	UIAnimations.pop_scale(placement_label, 0.5, score_delay + UIAnimations.DUR_SCORE_REVEAL)

	# Reward — gold flash + number ticker
	if reward > 0:
		reward_label.text = "Earned: 0 coins!"
		var reward_delay := score_delay + UIAnimations.DUR_SCORE_REVEAL + 0.3
		UIAnimations.number_ticker(reward_label, 0.0, float(reward), 0.8, "Earned: %d coins!", reward_delay)
		UIAnimations.gold_flash(reward_label)
	else:
		reward_label.text = "No coin reward."

	# 1st place celebration effect
	if placement == 1:
		var celebration_delay := score_delay + UIAnimations.DUR_SCORE_REVEAL + 0.5
		var results_panel := $UI/ResultsPanel as Control
		if results_panel:
			get_tree().create_timer(celebration_delay).timeout.connect(func():
				var center := results_panel.size * 0.5
				UIAnimations.celebration(results_panel, center, 12)
			)


func _on_continue_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)
