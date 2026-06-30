## SettingsStandalone — Full-screen settings scene.
## Navigated to via GameManager.GameState.SETTINGS.
## Reuses the same save/load logic as the old overlay.
extends Node

@onready var _back_button: Button = %BackButton
@onready var _master_slider: HSlider = %MasterVolumeSlider
@onready var _music_slider: HSlider = %MusicVolumeSlider
@onready var _sfx_slider: HSlider = %SFXVolumeSlider
@onready var _master_value: Label = %MasterValueLabel
@onready var _music_value: Label = %MusicValueLabel
@onready var _sfx_value: Label = %SFXValueLabel
@onready var _version_label: Label = %VersionLabel
@onready var _screen_header: PanelContainer = $UI/MainLayout/ScreenHeader
@onready var _header_title: Label = $UI/MainLayout/ScreenHeader/HeaderHBox/HeaderTitle

const AUDIO_BUS_MASTER := "Master"
const AUDIO_BUS_MUSIC := "Music"
const AUDIO_BUS_SFX := "SFX"


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.SETTINGS

	_back_button.pressed.connect(_on_back_pressed)
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	for slider: HSlider in [_master_slider, _music_slider, _sfx_slider]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(300, 44)

	_style_header()
	_load_settings()

	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	_version_label.text = "Version: %s" % version


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


func _load_settings() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	_master_slider.value = settings.get("master_volume", 1.0)
	_music_slider.value = settings.get("music_volume", 0.8)
	_sfx_slider.value = settings.get("sfx_volume", 1.0)
	_update_labels()
	_apply_audio()


func _update_labels() -> void:
	_master_value.text = "%d%%" % int(_master_slider.value * 100)
	_music_value.text = "%d%%" % int(_music_slider.value * 100)
	_sfx_value.text = "%d%%" % int(_sfx_slider.value * 100)


func _apply_audio() -> void:
	_set_bus_volume(AUDIO_BUS_MASTER, _master_slider.value)
	_set_bus_volume(AUDIO_BUS_MUSIC, _music_slider.value)
	_set_bus_volume(AUDIO_BUS_SFX, _sfx_slider.value)


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	if linear_volume <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_volume))


func _save_settings() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	settings["master_volume"] = _master_slider.value
	settings["music_volume"] = _music_slider.value
	settings["sfx_volume"] = _sfx_slider.value
	SaveManager.data["settings"] = settings
	SaveManager.save_game()


func _on_master_changed(_value: float) -> void:
	_update_labels()
	_apply_audio()


func _on_music_changed(_value: float) -> void:
	_update_labels()
	_apply_audio()


func _on_sfx_changed(_value: float) -> void:
	_update_labels()
	_apply_audio()


func _on_back_pressed() -> void:
	_save_settings()
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
