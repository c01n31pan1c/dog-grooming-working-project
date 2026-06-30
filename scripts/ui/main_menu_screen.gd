## MainMenuScreen — Main menu UI controller.
## Attached to the MainMenu scene root. Handles button presses
## and displays player info if save data exists.
## Uses DGC design system components for consistent styling.
extends Node

@onready var play_button: Button = %PlayButton
@onready var breedpedia_button: Button = %BreedpediaButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton
@onready var tier_label: Label = %TierLabel
@onready var coin_balance: DGCCoinBalance = %CoinBalance
## Settings overlay removed — settings is now a standalone scene.

## Scene node references for animations.
@onready var _player_info_bar: PanelContainer = $UI/MainLayout/PlayerInfoBar
@onready var _title_container: VBoxContainer = $UI/MainLayout/TitleContainer
@onready var _button_container: VBoxContainer = $UI/MainLayout/ButtonContainer

## Tier display names — maps tier index to human-readable name.
const TIER_NAMES: Array[String] = [
	"Amateur",
	"Local Circuit",
	"Regional",
	"National",
	"Elite",
]


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MAIN_MENU

	# Set button labels
	play_button.text = "Play"
	breedpedia_button.text = "Breed-pedia"
	shop_button.text = "Shop"
	settings_button.text = "Settings"

	play_button.pressed.connect(_on_play_pressed)
	breedpedia_button.pressed.connect(_on_breedpedia_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Style the info bar
	_style_info_bar()

	# Style the title text
	_style_title()

	_update_player_info()
	EventBus.currency_changed.connect(_on_currency_changed)

	# Play entrance animations
	_play_entrance_animations()


func _style_info_bar() -> void:
	# Info bar: bg=#f0f7ff with borderBottom matching design spec
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = DesignTokens.BLUE_PANEL
	bar_style.border_width_bottom = DesignTokens.BORDER_THIN
	bar_style.border_color = DesignTokens.BLUE_LINE
	bar_style.content_margin_left = 22
	bar_style.content_margin_right = 22
	bar_style.content_margin_top = 16
	bar_style.content_margin_bottom = 16
	_player_info_bar.add_theme_stylebox_override("panel", bar_style)

	# Tier label styling: display font, bold, 22px
	if DesignTokens.font_display_bold:
		tier_label.add_theme_font_override("font", DesignTokens.font_display_bold)
	tier_label.add_theme_font_size_override("font_size", 22)
	tier_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)


func _style_title() -> void:
	# Style title labels with display font
	var title_label: Label = $UI/MainLayout/TitleContainer/TitleWrapper/TitleLabel
	var title_shadow: Label = $UI/MainLayout/TitleContainer/TitleWrapper/TitleShadow
	var subtitle_label: Label = $UI/MainLayout/TitleContainer/SubtitleLabel
	var paw_label: Label = $UI/MainLayout/TitleContainer/PawEmoji

	if DesignTokens.font_display_extrabold:
		title_label.add_theme_font_override("font", DesignTokens.font_display_extrabold)
		title_shadow.add_theme_font_override("font", DesignTokens.font_display_extrabold)

	title_label.add_theme_color_override("font_color", DesignTokens.INK_TITLE)
	# Shadow: yellow with 0.55 alpha, offset 4px (set in .tscn position)
	title_shadow.add_theme_color_override("font_color", Color(1.0, 0.878, 0.4, 0.55))

	if DesignTokens.font_body_bold:
		subtitle_label.add_theme_font_override("font", DesignTokens.font_body_bold)
	subtitle_label.add_theme_font_size_override("font_size", 22)
	subtitle_label.add_theme_color_override("font_color", DesignTokens.INK_SLATE)


func _play_entrance_animations() -> void:
	# Title fades in
	_title_container.modulate.a = 0.0
	var title_tween := _title_container.create_tween()
	title_tween.tween_property(_title_container, "modulate:a", 1.0, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Player info bar fades in
	_player_info_bar.modulate.a = 0.0
	var info_tween := _player_info_bar.create_tween()
	info_tween.tween_property(_player_info_bar, "modulate:a", 1.0, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Buttons fade in sequentially (staggered)
	var button_vbox: VBoxContainer = $UI/MainLayout/ButtonContainer/MarginLeft/ButtonVBox
	var buttons := button_vbox.get_children()
	for i in buttons.size():
		var btn := buttons[i] as Control
		if btn:
			btn.modulate.a = 0.0
			var delay := 0.3 + i * UIAnimations.DUR_STAGGER
			var tween := btn.create_tween()
			if delay > 0.0:
				tween.tween_interval(delay)
			tween.tween_property(btn, "modulate:a", 1.0, 0.3) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _update_player_info() -> void:
	var tier_index: int = SaveManager.data.get("current_tier", 0)
	var tier_name: String = TIER_NAMES[clampi(tier_index, 0, TIER_NAMES.size() - 1)]
	tier_label.text = tier_name

	var coins: int = SaveManager.data.get("currency", 0)
	coin_balance.amount = coins


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_player_info()


func _on_play_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)


func _on_breedpedia_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BREED_PEDIA, {"origin": GameManager.GameState.MAIN_MENU})


func _on_shop_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SHOP)


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)
