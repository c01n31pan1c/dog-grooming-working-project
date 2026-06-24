## JudgeAI — Evaluates grooming results through the lens of individual judge personalities.
## Takes a ScoreBreakdown from ScoringEngine + JudgeData and produces weighted, personality-flavored results.
class_name JudgeAI
extends Node

# ── Comment templates per judge personality ──────────────────────────────────

## Formal / traditional comments (Mrs. Pemberton style)
const COMMENTS_TRADITIONAL := {
	"accuracy_high": [
		"Exemplary adherence to the breed standard. This is what we expect.",
		"The grooming is precise and correct. Well done.",
		"Every zone groomed to specification. Most satisfactory.",
	],
	"accuracy_low": [
		"I'm afraid the breed standard has not been met. Quite disappointing.",
		"Significant deviations from the standard. This simply won't do.",
		"One must study the breed guide more carefully before competing.",
	],
	"time_high": [
		"Completed with admirable efficiency, though speed should never compromise quality.",
		"A prompt finish. Time well managed.",
	],
	"time_low": [
		"The clock is not your friend today. One must practise more.",
		"Terribly slow. A professional should work more briskly.",
	],
	"style_high": [
		"A polished presentation. The finishing touches are appreciated.",
		"The extras complement the grooming nicely. Tasteful.",
	],
	"style_low": [
		"The presentation lacks polish. A little cologne goes a long way.",
		"No finishing touches? Rather bare, I must say.",
	],
}

## Enthusiastic / flashy comments (Carlos Rivera style)
const COMMENTS_FLASHY := {
	"accuracy_high": [
		"Now THAT is how you groom a dog! Perfection!",
		"Every cut is on point — this dog is a star!",
		"Technical brilliance! The crowd loves it!",
	],
	"accuracy_low": [
		"Hmm, the technique needs work, but don't give up!",
		"A few rough spots — tighten up the cuts next time!",
		"The basics need attention, amigo. Study the breed!",
	],
	"time_high": [
		"Speed AND style? You're a natural showman!",
		"Fast work! The audience barely had time to blink!",
	],
	"time_low": [
		"A bit slow on the draw — the crowd was getting restless!",
		"Time management, my friend! The show must go on!",
	],
	"style_high": [
		"YES! The accessories, the cologne — MAGNIFICENT!",
		"This dog is READY for the runway! Stunning presentation!",
		"The style! The flair! This is what I live for!",
	],
	"style_low": [
		"Where's the pizzazz? This dog deserves to SHINE!",
		"No accessories? No cologne? The dog looks underdressed!",
	],
}

## Methodical / balanced comments (Dr. Tanaka style)
const COMMENTS_BALANCED := {
	"accuracy_high": [
		"Technically sound work. Each zone meets the standard.",
		"Accurate and methodical grooming. Good fundamentals.",
		"The data speaks for itself — excellent accuracy scores.",
	],
	"accuracy_low": [
		"Several zones fall short of the breed standard. Review the guide.",
		"The accuracy metrics are below acceptable thresholds.",
		"Inconsistent technique across zones. More practice recommended.",
	],
	"time_high": [
		"Efficient time utilisation. Well-paced throughout.",
		"Good time management — an important professional skill.",
	],
	"time_low": [
		"Time efficiency was suboptimal. Consider your workflow order.",
		"Slow pace. Efficiency is as important as accuracy.",
	],
	"style_high": [
		"Presentation extras properly applied. Complete package.",
		"Finishing touches demonstrate professional thoroughness.",
	],
	"style_low": [
		"Presentation could be improved with finishing products.",
		"Incomplete presentation. Don't overlook the final details.",
	],
}

## Map preferred_style to comment bank.
var _comment_banks := {
	"Traditional": COMMENTS_TRADITIONAL,
	"Flashy": COMMENTS_FLASHY,
	"Balanced": COMMENTS_BALANCED,
}


## Evaluate a single judge's reaction to a score breakdown.
##
## score_breakdown: Dictionary from ScoringEngine { accuracy, time, style, zone_details, total_raw }
## judge: JudgeData resource
## Returns: { judge_name, weighted_score, comments, liked, disliked }
func evaluate(score_breakdown: Dictionary, judge: JudgeData) -> Dictionary:
	var weights: Dictionary = judge.scoring_weights
	var strictness: float = judge.strictness_level

	# Apply weights.
	var w_accuracy: float = weights.get("accuracy", 0.33)
	var w_time: float = weights.get("time", 0.33)
	var w_style: float = weights.get("style", 0.34)

	var raw_accuracy: float = score_breakdown.get("accuracy", 0.0)
	var raw_time: float = score_breakdown.get("time", 0.0)
	var raw_style: float = score_breakdown.get("style", 0.0)

	# Strictness penalty: stricter judges penalise imperfect scores more heavily.
	# Formula: for any score below 100, reduce it proportionally to strictness.
	# A perfectly lenient judge (0.0) applies no penalty. A strict judge (1.0) doubles the deficit.
	var adj_accuracy := _apply_strictness(raw_accuracy, strictness)
	var adj_time := _apply_strictness(raw_time, strictness)
	var adj_style := _apply_strictness(raw_style, strictness)

	var weighted_score := (adj_accuracy * w_accuracy + adj_time * w_time + adj_style * w_style)

	# Generate comments, likes, and dislikes.
	var comments: Array[String] = []
	var liked: Array[String] = []
	var disliked: Array[String] = []

	var bank: Dictionary = _comment_banks.get(judge.preferred_style, COMMENTS_BALANCED)

	# Accuracy feedback
	if raw_accuracy >= 70.0:
		comments.append(_pick_comment(bank, "accuracy_high"))
		liked.append("Accuracy")
	else:
		comments.append(_pick_comment(bank, "accuracy_low"))
		disliked.append("Accuracy")

	# Time feedback
	if raw_time >= 50.0:
		comments.append(_pick_comment(bank, "time_high"))
		liked.append("Time management")
	else:
		comments.append(_pick_comment(bank, "time_low"))
		disliked.append("Time management")

	# Style feedback
	if raw_style >= 50.0:
		comments.append(_pick_comment(bank, "style_high"))
		liked.append("Presentation")
	else:
		comments.append(_pick_comment(bank, "style_low"))
		disliked.append("Presentation")

	return {
		"judge_name": judge.judge_name,
		"weighted_score": weighted_score,
		"comments": comments,
		"liked": liked,
		"disliked": disliked,
	}


## Calculate the panel's combined result across multiple judges.
##
## score_breakdown: Dictionary from ScoringEngine.
## judges: Array of JudgeData resources.
## Returns: { panel_score, judge_results: Array[Dictionary], placement_comment }
func calculate_panel_score(score_breakdown: Dictionary, judges: Array) -> Dictionary:
	var judge_results: Array[Dictionary] = []
	var score_sum := 0.0

	for judge in judges:
		var result := evaluate(score_breakdown, judge as JudgeData)
		judge_results.append(result)
		score_sum += result["weighted_score"]

	var panel_score := 0.0
	if judges.size() > 0:
		panel_score = score_sum / float(judges.size())

	var placement_comment := ""
	if panel_score >= 90.0:
		placement_comment = "Outstanding performance! A clear winner!"
	elif panel_score >= 75.0:
		placement_comment = "Very strong showing. A top competitor."
	elif panel_score >= 60.0:
		placement_comment = "Solid work with room for improvement."
	elif panel_score >= 40.0:
		placement_comment = "Below expectations. Keep practising."
	else:
		placement_comment = "A rough outing. Study the breed standards."

	return {
		"panel_score": panel_score,
		"judge_results": judge_results,
		"placement_comment": placement_comment,
	}


## Apply strictness to a raw score. Stricter judges amplify the deficit from 100.
func _apply_strictness(raw_score: float, strictness: float) -> float:
	var deficit := 100.0 - raw_score
	# Strictness multiplies the penalty: 0.0 strictness = no extra penalty, 1.0 = double the deficit.
	var penalty := deficit * strictness
	return clampf(raw_score - penalty, 0.0, 100.0)


## Pick a random comment from the given bank category.
func _pick_comment(bank: Dictionary, category: String) -> String:
	var options: Array = bank.get(category, ["No comment."])
	if options.is_empty():
		return "No comment."
	return options[randi() % options.size()]
