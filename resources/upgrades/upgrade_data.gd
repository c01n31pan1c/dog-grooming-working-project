## UpgradeData — Custom Resource defining a purchasable upgrade.
## Create .tres instances in resources/upgrades/ for each upgrade.
class_name UpgradeData
extends Resource

@export var upgrade_name: String = ""
@export var upgrade_type: String = ""

## Tier: 0 = basic, 1 = mid, 2 = elite
@export_range(0, 2) var tier: int = 0

@export var price: int = 0
@export_multiline var effect_description: String = ""

## Maps stat name (String) -> modifier value (float). E.g., {"grooming_speed": 1.2, "accuracy_bonus": 0.05}
@export var stat_modifiers: Dictionary = {}
