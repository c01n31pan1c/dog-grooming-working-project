## ShopManager — Coordinates purchases between CurrencyManager and UpgradeSystem.
## Provides a unified API for the shop UI.
class_name ShopManager
extends Node

var _currency_manager: CurrencyManager = null
var _upgrade_system: UpgradeSystem = null


## Initialize with references to sibling managers.
func setup(currency_manager: CurrencyManager, upgrade_system: UpgradeSystem) -> void:
	_currency_manager = currency_manager
	_upgrade_system = upgrade_system


## Get the full shop inventory, grouped by category.
func get_shop_inventory() -> Dictionary:
	var inventory: Dictionary = {}
	var all_upgrades: Dictionary = _upgrade_system.get_all_upgrades()
	var balance: int = _currency_manager.get_balance()

	for category in all_upgrades:
		inventory[category] = []
		for entry in all_upgrades[category]:
			var upgrade_id: String = entry["id"]
			var data: UpgradeData = entry["data"]
			inventory[category].append({
				"id": upgrade_id,
				"data": data,
				"owned": _upgrade_system.is_owned(upgrade_id),
				"count": _upgrade_system.get_consumable_count(upgrade_id),
				"can_afford": balance >= data.price,
			})
	return inventory


## Attempt to purchase an upgrade. Returns {success: bool, message: String}.
func attempt_purchase(upgrade_id: String) -> Dictionary:
	if _upgrade_system == null or _currency_manager == null:
		return {"success": false, "message": "Shop not initialized."}

	var data: UpgradeData = _upgrade_system.get_upgrade(upgrade_id)
	if data == null:
		return {"success": false, "message": "Item not found."}

	if data.upgrade_type != "consumable" and _upgrade_system.is_owned(upgrade_id):
		return {"success": false, "message": "Already owned."}

	if _currency_manager.get_balance() < data.price:
		return {"success": false, "message": "Not enough coins. Need %d." % data.price}

	var success: bool = _upgrade_system.purchase_upgrade(upgrade_id, _currency_manager)
	if success:
		return {"success": true, "message": "Purchased %s!" % data.upgrade_name}
	else:
		return {"success": false, "message": "Purchase failed."}
