## CurrencyManager — Tracks and modifies player currency.
## Delegates to SaveManager for persistence, emits signals via EventBus.
class_name CurrencyManager
extends Node


## Returns the current coin balance.
func get_balance() -> int:
	return SaveManager.data.get("currency", 0)


## Returns total coins earned across all sessions (lifetime stat).
func get_total_earned() -> int:
	return SaveManager.data.get("total_coins_earned", 0)


## Add coins to balance. Also tracks lifetime total earned.
func add_currency(amount: int) -> void:
	if amount <= 0:
		push_warning("CurrencyManager: add_currency called with non-positive amount %d" % amount)
		return
	SaveManager.modify_currency(amount)
	var total: int = SaveManager.data.get("total_coins_earned", 0) + amount
	SaveManager.data["total_coins_earned"] = total
	SaveManager.save_game()


## Spend coins from balance. Returns false if insufficient funds.
func spend_currency(amount: int) -> bool:
	if amount <= 0:
		push_warning("CurrencyManager: spend_currency called with non-positive amount %d" % amount)
		return false
	if get_balance() < amount:
		return false
	SaveManager.modify_currency(-amount)
	SaveManager.save_game()
	return true
