## CurrencyManager — Tracks and modifies player currency.
## Stub for WS-5. Delegates to SaveManager for persistence.
class_name CurrencyManager
extends Node


func get_balance() -> int:
	return SaveManager.data.get("currency", 0)


func add(amount: int) -> void:
	SaveManager.modify_currency(amount)


func spend(amount: int) -> bool:
	if get_balance() < amount:
		return false
	SaveManager.modify_currency(-amount)
	return true
