## SalonScreen — Hub screen between competitions.
## Shows tier progress, balance, quick stats, and navigation buttons.
## Uses DGC design system components for consistent styling.
extends Node

var _currency_manager: CurrencyManager
var _progression_manager: ProgressionManager

@onready var _coin_balance: DGCCoinBalance = %CoinBalance
@onready var _tier_label: Label = %TierLabel
@onready var _progress_bar: DGCProgressBar = %TierProgressBar
@onready var _progress_hint: Label = %ProgressHint
@onready var _wins_value: Label = %WinsValue
@onready var _shows_value: Label = %ShowsValue
@onready var _breeds_value: Label = %BreedsValue
@onready var _header_title: Label = %HeaderTitle

@onready var _compete_button: Button = %CompeteButton
@onready var _free_groom_button: Button = %FreeGroomButton
@onready var _shop_button: Button = %ShopButton
@onready var _breedpedia_button: Button = %BreedpediaButton
@onready var _back_button: Button = %BackButton

@onready var _screen_header: PanelContainer = $UI/MainLayout/ScreenHeader
@onready var _scroll_container: ScrollContainer = $UI/MainLayout/ScrollContainer


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.SALON

	_currency_manager = CurrencyManager.new()
	_currency_manager.name = "CurrencyManager"
	add_child(_currency_manager)

	_progression_manager = ProgressionManager.new()
	_progression_manager.name = "ProgressionManager"
	add_child(_progression_manager)

	_compete_button.pressed.connect(_on_compete_pressed)
	_free_groom_button.pressed.connect(_on_free_groom_pressed)
	_shop_button.pressed.connect(_on_shop_pressed)
	_breedpedia_button.pressed.connect(_on_breedpedia_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.tier_advanced.connect(_on_tier_advanced)

	_style_header()
	_style_panels()
	_refresh_display()
	_play_entrance_animations()


func _style_header() -> void:
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = DesignTokens.BLUE_PANEL
	header_style.border_width_bottom = DesignTokens.BORDER_THIN
	header_style.border_color = DesignTokens.BLUE_LINE
	header_style.content_margin_left = 18
	header_style.content_margin_right = 18
	header_style.content_margin_top = 14
	header_style.content_margin_bottom = 14
	_screen_header.add_theme_stylebox_override("panel", header_style)

	if DesignTokens.font_display_bold:
		_header_title.add_theme_font_override("font", DesignTokens.font_display_bold)
	_header_title.add_theme_font_size_override("font_size", 28)
	_header_title.add_theme_color_override("font_color", DesignTokens.INK_TITLE)


func _style_panels() -> void:
	var balance_panel: PanelContainer = $UI/MainLayout/ScrollContainer/ContentVBox/ContentMargin/PanelsVBox/BalancePanel
	_apply_panel_style(balance_panel)

	var tier_panel: PanelContainer = $UI/MainLayout/ScrollContainer/ContentVBox/ContentMargin/PanelsVBox/TierPanel
	_apply_panel_style(tier_panel)

	if DesignTokens.font_display_bold:
		_tier_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	_tier_label.add_theme_font_size_override("font_size", 24)
	_tier_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)

	if DesignTokens.font_body_semibold:
		_progress_hint.add_theme_font_override("font", DesignTokens.font_body_semibold)
	_progress_hint.add_theme_font_size_override("font_size", 16)
	_progress_hint.add_theme_color_override("font_color", DesignTokens.INK_SLATE)

	var stats_panel: PanelContainer = $UI/MainLayout/ScrollContainer/ContentVBox/ContentMargin/PanelsVBox/StatsPanel
	_apply_panel_style(stats_panel)

	for val_label in [_wins_value, _shows_value, _breeds_value]:
		if DesignTokens.font_display_extrabold:
			val_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
		val_label.add_theme_font_size_override("font_size", 32)
		val_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)

	var wins_label: Label = $UI/MainLayout/ScrollContainer/ContentVBox/ContentMargin/PanelsVBox/StatsPanel/StatsHBox/WinsColumn/WinsLabel
	var shows_label: Label = $UI/MainLayout/ScrollContainer/ContentVBox/ContentMargin/PanelsVBox/StatsPanel/StatsHBox/ShowsColumn/ShowsLabel
	var breeds_label: Label = $UI/MainLayout/ScrollContainer/ContentVBox/ContentMargin/PanelsVBox/StatsPanel/StatsHBox/BreedsColumn/BreedsLabel
	for cat_label in [wins_label, shows_label, breeds_label]:
		if DesignTokens.font_body_bold:
			cat_label.add_theme_font_override("font", DesignTokens.font_body_bold)
		cat_label.add_theme_font_size_override("font_size", 14)
		cat_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)


func _apply_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = DesignTokens.BLUE_PANEL
	style.border_width_bottom = DesignTokens.BORDER_THIN
	style.border_width_top = DesignTokens.BORDER_THIN
	style.border_width_left = DesignTokens.BORDER_THIN
	style.border_width_right = DesignTokens.BORDER_THIN
	style.border_color = DesignTokens.BLUE_LINE
	style.corner_radius_top_left = DesignTokens.RADIUS_PANEL
	style.corner_radius_top_right = DesignTokens.RADIUS_PANEL
	style.corner_radius_bottom_left = DesignTokens.RADIUS_PANEL
	style.corner_radius_bottom_right = DesignTokens.RADIUS_PANEL
	style.anti_aliasing = true
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_top = DesignTokens.PAD_PANEL
	style.content_margin_bottom = DesignTokens.PAD_PANEL
	style.content_margin_left = DesignTokens.PAD_PANEL
	style.content_margin_right = DesignTokens.PAD_PANEL
	panel.add_theme_stylebox_override("panel", style)


func _play_entrance_animations() -> void:
	_screen_header.modulate.a = 0.0
	var header_tween := _screen_header.create_tween()
	header_tween.tween_property(_screen_header, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	_scroll_container.modulate.a = 0.0
	var content_tween := _scroll_container.create_tween()
	content_tween.tween_interval(0.15)
	content_tween.tween_property(_scroll_container, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	var buttons: Array[Button] = [_compete_button, _free_groom_button, _breedpedia_button, _shop_button]
	for i in buttons.size():
		var btn := buttons[i]
		btn.modulate.a = 0.0
		var tween := btn.create_tween()
		tween.tween_interval(0.25 + i * 0.08)
		tween.tween_property(btn, "modulate:a", 1.0, 0.3) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _refresh_display() -> void:
	_coin_balance.amount = _currency_manager.get_balance()

	var tier: int = _progression_manager.get_current_tier()
	_tier_label.text = "Tier: %s" % _progression_manager.get_tier_name(tier)

	var progress: Dictionary = _progression_manager.get_advancement_progress()
	if progress.get("at_max", false):
		_progress_bar.value = 100.0
		_progress_bar.label_text = "Maximum tier reached!"
		_progress_hint.text = "You've reached the top!"
	else:
		_progress_bar.value = progress["progress_pct"] * 100.0
		_progress_bar.label_text = "Wins %d/%d · %d/%d coins" % [
			progress["wins_current"], progress["wins_required"],
			progress["coins_current"], progress["coins_required"],
		]
		var wins_needed: int = progress["wins_required"] - progress["wins_current"]
		var next_tier_name: String = _progression_manager.get_tier_name(tier + 1) if tier + 1 < 5 else ""
		if not next_tier_name.is_empty():
			_progress_hint.text = "Win %d more shows to reach %s" % [wins_needed, next_tier_name]
		else:
			_progress_hint.text = ""

	_wins_value.text = str(_progression_manager.get_total_wins())
	_shows_value.text = str(_progression_manager.get_competitions_completed())
	_breeds_value.text = str(_progression_manager.get_breeds_groomed_count())


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_refresh_display()


func _on_tier_advanced(_new_tier: int) -> void:
	_refresh_display()


func _on_compete_pressed() -> void:
	GameManager.change_state(GameManager.GameState.COMPETITION)


func _on_free_groom_pressed() -> void:
	GameManager.change_state(GameManager.GameState.GROOMING, {"mode": "free_groom"})


func _on_shop_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SHOP)


func _on_breedpedia_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BREED_PEDIA, {"origin": GameManager.GameState.SALON})


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
