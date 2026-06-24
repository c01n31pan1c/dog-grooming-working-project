## ScoringEngine — Combines judge evaluations into final competition score.
## Stub for WS-4.
class_name ScoringEngine
extends Node


func calculate_score(_grooming_results: Dictionary, _judges: Array) -> Dictionary:
	# WS-4 implements: accuracy + time bonus + style points
	var score := {"total": 0.0, "accuracy": 0.0, "time_bonus": 0.0, "style": 0.0}
	EventBus.score_calculated.emit(score)
	return score
