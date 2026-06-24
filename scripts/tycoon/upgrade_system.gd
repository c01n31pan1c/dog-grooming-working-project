## UpgradeSystem — Manages equipment and salon upgrades.
## Stub for WS-5.
class_name UpgradeSystem
extends Node

var active_upgrades: Array[Resource] = []


func apply_upgrade(_upgrade_data: Resource) -> void:
	# WS-5 implements: apply stat modifiers from UpgradeData
	pass


func get_active_upgrades() -> Array[Resource]:
	return active_upgrades
