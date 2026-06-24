## UpgradeSystem — Manages equipment, cosmetic, and consumable upgrades.
## Tracks ownership and quantities. Persists via SaveManager.
class_name UpgradeSystem
extends Node

## All available upgrade resources, keyed by upgrade_id.
var _catalog: Dictionary = {}

## Path to the upgrades resource folder.
const UPGRADES_DIR := "res://resources/upgrades/"


func _ready() -> void:
	_load_catalog()


## Scan the upgrades directory and load all .tres UpgradeData resources.
func _load_catalog() -> void:
	_catalog.clear()
	var dir := DirAccess.open(UPGRADES_DIR)
	if dir == null:
		push_error("UpgradeSystem: Cannot open upgrades directory at %s" % UPGRADES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := ResourceLoader.load(UPGRADES_DIR + file_name)
			if res is UpgradeData:
				var upgrade_id := file_name.get_basename()
				_catalog[upgrade_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


## Purchase an upgrade by its resource. Returns true on success.
func purchase_upgrade(upgrade_id: String, currency_manager: CurrencyManager) -> bool:
	if not _catalog.has(upgrade_id):
		push_error("UpgradeSystem: Unknown upgrade_id '%s'" % upgrade_id)
		return false

	var upgrade_data: UpgradeData = _catalog[upgrade_id]

	if upgrade_data.upgrade_type != "consumable" and is_owned(upgrade_id):
		return false

	if not currency_manager.spend_currency(upgrade_data.price):
		return false

	var owned: Dictionary = SaveManager.data.get("owned_upgrades", {})
	if upgrade_data.upgrade_type == "consumable":
		var qty: int = int(upgrade_data.stat_modifiers.get("quantity", 1))
		owned[upgrade_id] = owned.get(upgrade_id, 0) + qty
	else:
		owned[upgrade_id] = 1
	SaveManager.data["owned_upgrades"] = owned
	SaveManager.save_game()
	return true


## Check if an upgrade is owned or has stock.
func is_owned(upgrade_id: String) -> bool:
	var owned: Dictionary = SaveManager.data.get("owned_upgrades", {})
	return owned.get(upgrade_id, 0) > 0


## Get remaining quantity of a consumable upgrade.
func get_consumable_count(upgrade_id: String) -> int:
	var owned: Dictionary = SaveManager.data.get("owned_upgrades", {})
	return owned.get(upgrade_id, 0)


## Use one charge of a consumable. Returns false if none remaining.
func use_consumable(upgrade_id: String) -> bool:
	var owned: Dictionary = SaveManager.data.get("owned_upgrades", {})
	var count: int = owned.get(upgrade_id, 0)
	if count <= 0:
		return false
	owned[upgrade_id] = count - 1
	SaveManager.data["owned_upgrades"] = owned
	SaveManager.save_game()
	return true


## Return all upgrades in a given category not yet owned (or consumable).
func get_available_upgrades(category: String) -> Array:
	var result: Array = []
	for upgrade_id in _catalog:
		var data: UpgradeData = _catalog[upgrade_id]
		if data.upgrade_type != category:
			continue
		if data.upgrade_type == "consumable" or not is_owned(upgrade_id):
			result.append({"id": upgrade_id, "data": data})
	return result


## Return all upgrades in the catalog, grouped by category.
func get_all_upgrades() -> Dictionary:
	var grouped: Dictionary = {}
	for upgrade_id in _catalog:
		var data: UpgradeData = _catalog[upgrade_id]
		if not grouped.has(data.upgrade_type):
			grouped[data.upgrade_type] = []
		grouped[data.upgrade_type].append({"id": upgrade_id, "data": data})
	return grouped


## Get a specific upgrade resource by id.
func get_upgrade(upgrade_id: String) -> UpgradeData:
	return _catalog.get(upgrade_id, null)


## Get the cumulative stat modifier value across all owned non-consumable upgrades.
func get_stat_modifier(stat_name: String) -> float:
	var total: float = 0.0
	var owned: Dictionary = SaveManager.data.get("owned_upgrades", {})
	for upgrade_id in owned:
		if not _catalog.has(upgrade_id):
			continue
		var data: UpgradeData = _catalog[upgrade_id]
		if data.upgrade_type == "consumable":
			continue
		if data.stat_modifiers.has(stat_name):
			total += data.stat_modifiers[stat_name]
	return total
