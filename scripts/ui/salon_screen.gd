## SalonScreen — Hub screen between competitions.
## Shows tier progress, balance, quick stats, and navigation buttons.
extends Node

var _currency_manager: CurrencyManager
var _progression_manager: ProgressionManager

@onready var _balance_label: Label = %BalanceLabel
@onready var _tier_label: Label = %TierLabel
@onready var _progress_bar: ProgressBar = %TierProgressBar
@onready var _progress_detail: Label = %ProgressDetail
@onready var _stats_label: Label = %StatsLabel

@onready var _compete_button: Button = %CompeteButton
@onready var _shop_button: Button = %ShopButton
@onready var _breedpedia_button: Button = %BreedpediaButton
@onready var _settings_button: Button = %SettingsButton


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.SALON

	_currency_manager = CurrencyManager.new()
	_currency_manager.name = "CurrencyManager"
	add_child(_currency_manager)

	_progression_manager = ProgressionManager.new()
	_progression_manager.name = "ProgressionManager"
	add_child(_progression_manager)

	_compete_button.pressed.connect(_on_compete_pressed)
	_shop_button.pressed.connect(_on_shop_pressed)
	_breedpedia_button.pressed.connect(_on_breedpedia_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)

	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.tier_advanced.connect(_on_tier_advanced)

	_refresh_display()


func _refresh_display() -> void:
	_balance_label.text = "%d coins" % _currency_manager.get_balance()

	var tier: int = _progression_manager.get_current_tier()
	_tier_label.text = _progression_manager.get_tier_name(tier)

	var progress: Dictionary = _progression_manager.get_advancement_progress()
	if progress.get("at_max", false):
		_progress_bar.value = 100.0
		_progress_detail.text = "Maximum tier reached!"
	else:
		_progress_bar.value = progress["progress_pct"] * 100.0
		_progress_detail.text = "Wins: %d/%d | Coins earned: %d/%d" % [
			progress["wins_current"], progress["wins_required"],
			progress["coins_current"], progress["coins_required"],
		]

	_stats_label.text = "Wins: %d | Competitions: %d | Breeds groomed: %d" % [
		_progression_manager.get_total_wins(),
		_progression_manager.get_competitions_completed(),
		_progression_manager.get_breeds_groomed_count(),
	]


func _on_currency_changed(_new_amount: int, _delta: int) -> void:
	_refresh_display()


func _on_tier_advanced(_new_tier: int) -> void:
	_refresh_display()


func _on_compete_pressed() -> void:
	GameManager.change_state(GameManager.GameState.COMPETITION)


func _on_shop_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SHOP)


func _on_breedpedia_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BREED_PEDIA)


func _on_settings_pressed() -> void:
	# Settings is handled as an overlay on the main menu.
	# From salon, navigate to main menu for now.
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
