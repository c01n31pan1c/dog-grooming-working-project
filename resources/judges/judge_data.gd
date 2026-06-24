## JudgeData — Custom Resource defining a competition judge's profile.
## Create .tres instances in resources/judges/ for each judge.
class_name JudgeData
extends Resource

@export var judge_name: String = ""
@export_multiline var personality: String = ""
@export var preferred_style: String = ""

## Maps scoring category (String) -> weight (float). E.g., {"accuracy": 0.5, "time": 0.3, "style": 0.2}
@export var scoring_weights: Dictionary = {}

## How strict the judge is: 0.0 = lenient, 1.0 = extremely strict
@export_range(0.0, 1.0, 0.05) var strictness_level: float = 0.5

## Cost in coins to reveal this judge's preferences before a competition.
@export var reveal_cost: int = 50
