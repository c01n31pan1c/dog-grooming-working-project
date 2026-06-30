## ShopScreen — UI controller for the shop scene.
## Displays categorized upgrade inventory with purchase functionality.
## Built with DGC design-system components.
extends Node

const CATEGORY_ORDER: Array = ["equipment", "consumable", "cosmetic"]
const CATEGORY_LABELS: Array = ["Equipment", "Consumables", "Salon Decor"]

var _currency_manager: CurrencyManager
var _upgrade_system: UpgradeSystem
var _shop_manager: ShopManager

var _coin_balance: DGCCoinBalance
var _tabs: DGCTabs
var _scroll: ScrollContainer
var _item_list: VBoxContainer
var _message_label: Label
var _back_button: DGCButton
var _message_timer: Timer


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

	EventBus.currency_changed.connect(_on_currency_changed)

	_build_ui()
	_populate_shop()


func _build_ui() -> void:
	var ui: Control = $UI

	# Main VBox layout filling the screen
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	ui.add_child(main_vbox)

	# --- ScreenHeader: back button + "SHOP" title + spacer ---
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 22)
	header_margin.add_theme_constant_override("margin_right", 22)
	header_margin.add_theme_constant_override("margin_top", 16)
	header_margin.add_theme_constant_override("margin_bottom", 0)
	header_margin.add_child(header_hbox)
	main_vbox.add_child(header_margin)

	var back_icon := DGCIconButton.new()
	back_icon.glyph = "\u2039"
	back_icon.variant = DGCIconButton.Variant.SECONDARY
	back_icon.pressed.connect(_on_back_pressed)
	header_hbox.add_child(back_icon)

	var title_label := Label.new()
	title_label.text = "SHOP"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", DesignTokens.FS_H1)
	title_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	if DesignTokens.font_display_bold:
		title_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	header_hbox.add_child(title_label)

	# Spacer to balance the back button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(56, 0)
	header_hbox.add_child(spacer)

	# --- Coin balance row: right-aligned ---
	var coin_margin := MarginContainer.new()
	coin_margin.add_theme_constant_override("margin_left", 22)
	coin_margin.add_theme_constant_override("margin_right", 22)
	coin_margin.add_theme_constant_override("margin_top", 12)
	coin_margin.add_theme_constant_override("margin_bottom", 0)
	main_vbox.add_child(coin_margin)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.alignment = BoxContainer.ALIGNMENT_END
	coin_margin.add_child(coin_hbox)

	_coin_balance = DGCCoinBalance.new()
	_coin_balance.compact = true
	_coin_balance.amount = _currency_manager.get_balance()
	coin_hbox.add_child(_coin_balance)

	# --- DGCTabs ---
	var tabs_margin := MarginContainer.new()
	tabs_margin.add_theme_constant_override("margin_left", 22)
	tabs_margin.add_theme_constant_override("margin_right", 22)
	tabs_margin.add_theme_constant_override("margin_top", 12)
	tabs_margin.add_theme_constant_override("margin_bottom", 0)
	main_vbox.add_child(tabs_margin)

	_tabs = DGCTabs.new()
	_tabs.tabs = PackedStringArray(CATEGORY_LABELS)
	_tabs.selected_index = 0
	_tabs.tab_changed.connect(_on_tab_changed)
	tabs_margin.add_child(_tabs)

	# --- Scrollable item list ---
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var scroll_margin := MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 22)
	scroll_margin.add_theme_constant_override("margin_right", 22)
	scroll_margin.add_theme_constant_override("margin_top", 12)
	scroll_margin.add_theme_constant_override("margin_bottom", 0)
	scroll_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_margin.add_child(_scroll)
	main_vbox.add_child(scroll_margin)

	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_constant_override("separation", 12)
	_scroll.add_child(_item_list)

	# --- Status message area ---
	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 18)
	_message_label.custom_minimum_size = Vector2(0, 30)
	if DesignTokens.font_body_bold:
		_message_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	main_vbox.add_child(_message_label)

	# Message auto-clear timer
	_message_timer = Timer.new()
	_message_timer.wait_time = 1.6
	_message_timer.one_shot = true
	_message_timer.timeout.connect(_clear_message)
	add_child(_message_timer)

	# --- Bottom: "Back to Salon" button ---
	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 22)
	bottom_margin.add_theme_constant_override("margin_right", 22)
	bottom_margin.add_theme_constant_override("margin_top", 0)
	bottom_margin.add_theme_constant_override("margin_bottom", 28)
	main_vbox.add_child(bottom_margin)

	_back_button = DGCButton.new()
	_back_button.text = "Back to Salon"
	_back_button.variant = DGCButton.Variant.SECONDARY
	_back_button.size = DGCButton.Size.MD
	_back_button.block = true
	_back_button.pressed.connect(_on_back_pressed)
	bottom_margin.add_child(_back_button)


func _update_balance_display() -> void:
	if _coin_balance:
		_coin_balance.amount = _currency_manager.get_balance()


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_balance_display()
	_populate_shop()


func _on_tab_changed(_index: int) -> void:
	_populate_shop()


func _populate_shop() -> void:
	var inventory: Dictionary = _shop_manager.get_shop_inventory()
	var cat_index: int = _tabs.selected_index if _tabs else 0
	var category: String = CATEGORY_ORDER[cat_index] if cat_index < CATEGORY_ORDER.size() else "equipment"

	# Clear existing items
	for child in _item_list.get_children():
		child.queue_free()

	var items: Array = inventory.get(category, [])
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items available."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", DesignTokens.FS_BODY)
		empty_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)
		if DesignTokens.font_body_semibold:
			empty_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
		_item_list.add_child(empty_label)
	else:
		for item in items:
			var shop_item := _create_shop_item(item)
			_item_list.add_child(shop_item)


func _create_shop_item(item: Dictionary) -> DGCShopItem:
	var data: UpgradeData = item["data"]
	var upgrade_id: String = item["id"]

	var shop_item := DGCShopItem.new()
	shop_item.item_name = data.upgrade_name
	shop_item.description = data.effect_description
	shop_item.price = data.price
	shop_item.owned = (data.upgrade_type != "consumable" and item["owned"])
	shop_item.affordable = item["can_afford"]
	shop_item.buy_pressed.connect(_on_buy_pressed.bind(upgrade_id))

	return shop_item


func _on_buy_pressed(upgrade_id: String) -> void:
	var result: Dictionary = _shop_manager.attempt_purchase(upgrade_id)
	_show_message(result["message"], result["success"])
	if result["success"]:
		_populate_shop()


func _show_message(msg: String, success: bool) -> void:
	_message_label.text = msg
	if success:
		_message_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)
	else:
		_message_label.add_theme_color_override("font_color", DesignTokens.RED)
	_message_timer.start()


func _clear_message() -> void:
	_message_label.text = ""


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)
