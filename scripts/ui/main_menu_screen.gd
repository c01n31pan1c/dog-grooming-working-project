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

	_update_player_info()
	EventBus.currency_changed.connect(_on_currency_changed)


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
