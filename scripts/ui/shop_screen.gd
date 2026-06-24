## ShopScreen — UI controller for the shop scene.
## Displays categorized upgrade inventory with purchase functionality.
extends Node

const CATEGORY_ORDER: Array = ["equipment", "consumable", "cosmetic"]

var _currency_manager: CurrencyManager
var _upgrade_system: UpgradeSystem
var _shop_manager: ShopManager

@onready var _balance_label: Label = %BalanceLabel
@onready var _category_tabs: TabContainer = %CategoryTabs
@onready var _message_label: Label = %MessageLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.SHOP

	_currency_manager = CurrencyManager.new()
	_currency_manager.name = "CurrencyManager"
	add_child(_currency_manager)

	_upgrade_system = UpgradeSystem.new()
	_upgrade_system.name = "UpgradeSystem"
	add_child(_upgrade_system)

	_shop_manager = ShopManager.new()
	_shop_manager.name = "ShopManager"
	add_child(_shop_manager)
	_shop_manager.setup(_currency_manager, _upgrade_system)

	_back_button.pressed.connect(_on_back_pressed)
	UIAnimations.setup_button_juice(_back_button)
	EventBus.currency_changed.connect(_on_currency_changed)

	_update_balance_display()
	_populate_shop()


func _update_balance_display() -> void:
	_balance_label.text = "%d coins" % _currency_manager.get_balance()


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_balance_display()
	_populate_shop()


func _populate_shop() -> void:
	var inventory: Dictionary = _shop_manager.get_shop_inventory()

	var tab_index: int = 0
	for category in CATEGORY_ORDER:
		if tab_index >= _category_tabs.get_child_count():
			break
		var scroll: ScrollContainer = _category_tabs.get_child(tab_index) as ScrollContainer
		if scroll == null:
			tab_index += 1
			continue
		var vbox: VBoxContainer = scroll.get_child(0) as VBoxContainer
		if vbox == null:
			tab_index += 1
			continue

		for child in vbox.get_children():
			child.queue_free()

		var items: Array = inventory.get(category, [])
		if items.is_empty():
			var empty_label := Label.new()
			empty_label.text = "No items available."
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(empty_label)
		else:
			for item in items:
				var item_panel := _create_item_panel(item)
				vbox.add_child(item_panel)

		tab_index += 1


func _create_item_panel(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var data: UpgradeData = item["data"]
	var upgrade_id: String = item["id"]

	var name_label := Label.new()
	name_label.text = data.upgrade_name
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color(0.239, 0.239, 0.361))
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = data.effect_description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.204, 0.286, 0.369))
	info_vbox.add_child(desc_label)

	var status_label := Label.new()
	if data.upgrade_type == "consumable":
		status_label.text = "In stock: %d" % item["count"]
	elif item["owned"]:
		status_label.text = "OWNED"
		status_label.add_theme_color_override("font_color", Color(0.71, 0.918, 0.843))
	else:
		status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(status_label)

	var buy_vbox := VBoxContainer.new()
	buy_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(buy_vbox)

	var price_label := Label.new()
	price_label.text = "%d coins" % data.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	buy_vbox.add_child(price_label)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(120, 64)

	if data.upgrade_type != "consumable" and item["owned"]:
		buy_button.disabled = true
		buy_button.text = "Owned"
	elif not item["can_afford"]:
		buy_button.disabled = true

	buy_button.pressed.connect(_on_buy_pressed.bind(upgrade_id))
	UIAnimations.setup_button_juice(buy_button)
	buy_vbox.add_child(buy_button)

	return panel


func _on_buy_pressed(upgrade_id: String) -> void:
	var result: Dictionary = _shop_manager.attempt_purchase(upgrade_id)
	_message_label.text = result["message"]
	if result["success"]:
		_populate_shop()


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)
