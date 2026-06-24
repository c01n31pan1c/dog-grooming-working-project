## JudgeAI — Evaluates grooming results based on judge personality and weights.
## Stub for WS-4.
class_name JudgeAI
extends Node

var judge_data: Resource = null


func evaluate(_grooming_results: Dictionary) -> Dictionary:
	# WS-4 implements scoring logic based on judge_data weights
	return {"total_score": 0.0, "breakdown": {}}
