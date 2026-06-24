## MainMenuScreen — Main menu UI controller.
## Attached to the MainMenu scene root. Handles button presses
## and displays player info if save data exists.
extends Node

@onready var play_button: Button = %PlayButton
@onready var breedpedia_button: Button = %BreedpediaButton
@onready var settings_button: Button = %SettingsButton
@onready var tier_label: Label = %TierLabel
@onready var coin_label: Label = %CoinLabel
@onready var settings_overlay: Control = %SettingsOverlay

## Scene node references for animations.
@onready var _player_info_bar: PanelContainer = $UI/MainLayout/PlayerInfoBar
@onready var _title_container: CenterContainer = $UI/MainLayout/TitleContainer
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

	play_button.pressed.connect(_on_play_pressed)
	breedpedia_button.pressed.connect(_on_breedpedia_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Wire up button press juice
	UIAnimations.setup_button_juice(play_button)
	UIAnimations.setup_button_juice(breedpedia_button)
	UIAnimations.setup_button_juice(settings_button)

	_update_player_info()
	EventBus.currency_changed.connect(_on_currency_changed)

	# Play entrance animations
	_play_entrance_animations()


func _play_entrance_animations() -> void:
	# Title slides down from above with bounce
	UIAnimations.slide_down_bounce(_title_container, 80.0, 0.6)

	# Player info bar fades in from top
	UIAnimations.fade_from_top(_player_info_bar, 30.0, 0.4)

	# Buttons fade in and slide up sequentially (staggered)
	var buttons := _button_container.get_children()
	for i in buttons.size():
		var btn := buttons[i] as Control
		if btn:
			UIAnimations.fade_slide_up(btn, 40.0, 0.3, 0.3 + i * UIAnimations.DUR_STAGGER)


func _update_player_info() -> void:
	var tier_index: int = SaveManager.data.get("current_tier", 0)
	var tier_name: String = TIER_NAMES[clampi(tier_index, 0, TIER_NAMES.size() - 1)]
	tier_label.text = tier_name

	var coins: int = SaveManager.data.get("currency", 0)
	coin_label.text = str(coins)


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_update_player_info()


func _on_play_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SALON)


func _on_breedpedia_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BREED_PEDIA)


func _on_settings_pressed() -> void:
	if settings_overlay:
		settings_overlay.visible = true
