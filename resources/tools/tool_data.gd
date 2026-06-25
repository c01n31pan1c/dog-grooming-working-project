## ToolData — Custom Resource defining a grooming tool's properties.
## Create .tres instances in resources/tools/ for each tool variant.
class_name ToolData
extends Resource

enum InteractionMode {
	CONTINUOUS,  ## 0 - hold/drag to groom (clippers, brush, dryer, hand_strip)
	SWIPE,       ## 1 - directional swipe across zone (scissors)
	TAP,         ## 2 - single tap to apply (nail_trimmer, shampoo, cologne, medicine)
}

enum ToolType {
	CLIPPER,
	BRUSH,
	DRYER,
	SCISSORS,
	NAIL_TRIMMER,
	SHAMPOO,
	COLOGNE,
	MEDICINE,
	HAND_STRIP,
}

@export var tool_name: String = ""
@export var tool_type: ToolType = ToolType.CLIPPER

## Guard size in inches (relevant for clippers). 0 means no guard / not applicable.
@export var guard_size: float = 0.0

@export var interaction_mode: InteractionMode = InteractionMode.CONTINUOUS

## Quality tier: 0 = basic, 1 = professional, 2 = elite
@export_range(0, 2) var quality_tier: int = 0

@export var price: int = 0
@export_multiline var description: String = ""
@export_multiline var effect_description: String = ""
