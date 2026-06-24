## ScoringEngine — Calculates accuracy, time, and style scores for a grooming session.
## Produces a ScoreBreakdown dictionary consumed by JudgeAI.
class_name ScoringEngine
extends Node


## Calculate the full score breakdown for a grooming session.
##
## grooming_results: Dictionary of zone_id -> { tool_used: String, guard_size: float, completed: bool }
## breed_data: BreedData resource defining the breed standard.
## time_bonus: float 0-100 from TimerSystem.calculate_time_bonus().
## style_extras: Dictionary { cologne: bool, accessories: Array[String], medicine: bool, medicine_needed: bool }
func calculate_score(
	grooming_results: Dictionary,
	breed_data: Resource,
	time_bonus: float,
	style_extras: Dictionary
) -> Dictionary:
	var zone_details := _calculate_zone_details(grooming_results, breed_data)
	var accuracy := _calculate_accuracy_score(zone_details, breed_data)
	var time_score := clampf(time_bonus, 0.0, 100.0)
	var style := _calculate_style_score(style_extras)

	var total_raw := (accuracy + time_score + style) / 3.0

	var breakdown := {
		"accuracy": accuracy,
		"time": time_score,
		"style": style,
		"zone_details": zone_details,
		"total_raw": total_raw,
	}

	EventBus.score_calculated.emit(breakdown)
	return breakdown


## Calculate per-zone accuracy details.
## Returns Dictionary of zone_id -> { correct_tool: bool, correct_guard: bool, completed: bool, zone_score: float }
func _calculate_zone_details(grooming_results: Dictionary, breed_data: Resource) -> Dictionary:
	var details := {}
	var breed_zones: Dictionary = breed_data.grooming_zones

	for zone_id in breed_zones:
		var standard: Dictionary = breed_zones[zone_id]
		var result: Dictionary = grooming_results.get(zone_id, {})

		var completed: bool = result.get("completed", false)
		var correct_tool: bool = false
		var correct_guard: bool = false
		var zone_score: float = 0.0

		if completed:
			# Check if the right tool was used.
			var required_tool: String = standard.get("required_tool", "")
			var used_tool: String = result.get("tool_used", "")
			correct_tool = (used_tool == required_tool)

			# Check guard size — allow small tolerance (0.25 inch).
			var required_guard: float = standard.get("guard_size", 0.0)
			var used_guard: float = result.get("guard_size", 0.0)
			correct_guard = absf(used_guard - required_guard) <= 0.25

			# Zone score: 50% for completing, 30% for right tool, 20% for right guard.
			zone_score = 50.0
			if correct_tool:
				zone_score += 30.0
			if correct_guard:
				zone_score += 20.0

		details[zone_id] = {
			"correct_tool": correct_tool,
			"correct_guard": correct_guard,
			"completed": completed,
			"zone_score": zone_score,
		}

	return details


## Average all zone scores into a single 0-100 accuracy score.
func _calculate_accuracy_score(zone_details: Dictionary, breed_data: Resource) -> float:
	var breed_zones: Dictionary = breed_data.grooming_zones
	if breed_zones.is_empty():
		return 0.0

	var total_score := 0.0
	var zone_count := breed_zones.size()

	for zone_id in breed_zones:
		if zone_details.has(zone_id):
			total_score += zone_details[zone_id].get("zone_score", 0.0)

	return total_score / float(zone_count)


## Calculate style score (0-100) from extras applied.
func _calculate_style_score(style_extras: Dictionary) -> float:
	var score := 0.0

	# Cologne: +30 points
	if style_extras.get("cologne", false):
		score += 30.0

	# Accessories: up to +40 points (10 per accessory, max 4 counted)
	var accessories: Array = style_extras.get("accessories", [])
	var accessory_count := mini(accessories.size(), 4)
	score += accessory_count * 10.0

	# Medicine: +30 if needed and applied, -10 penalty if needed but not applied, 0 if not needed
	var medicine_needed: bool = style_extras.get("medicine_needed", false)
	var medicine_applied: bool = style_extras.get("medicine", false)
	if medicine_needed:
		if medicine_applied:
			score += 30.0
		else:
			score -= 10.0

	return clampf(score, 0.0, 100.0)
