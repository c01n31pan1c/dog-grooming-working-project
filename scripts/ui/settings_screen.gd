## SettingsScreen — Overlay panel for game settings.
## Not a full scene change — toggled visible/invisible on top of current scene.
## Saves settings through SaveManager.
extends Control

@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var master_value_label: Label = %MasterValueLabel
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SFXValueLabel
@onready var version_label: Label = %VersionLabel
@onready var close_button: Button = %SettingsCloseButton

const AUDIO_BUS_MASTER := "Master"
const AUDIO_BUS_MUSIC := "Music"
const AUDIO_BUS_SFX := "SFX"


func _ready() -> void:
	visible = false

	close_button.pressed.connect(_on_close_pressed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	# Configure sliders
	for slider: HSlider in [master_volume_slider, music_volume_slider, sfx_volume_slider]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(300, 44)

	# Load current settings
	_load_settings()

	# Version display
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_label.text = "Version: %s" % version


func _load_settings() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	var master_vol: float = settings.get("master_volume", 1.0)
	var music_vol: float = settings.get("music_volume", 0.8)
	var sfx_vol: float = settings.get("sfx_volume", 1.0)

	master_volume_slider.value = master_vol
	music_volume_slider.value = music_vol
	sfx_volume_slider.value = sfx_vol

	_update_value_labels()
	_apply_audio_volumes()


func _update_value_labels() -> void:
	master_value_label.text = "%d%%" % int(master_volume_slider.value * 100)
	music_value_label.text = "%d%%" % int(music_volume_slider.value * 100)
	sfx_value_label.text = "%d%%" % int(sfx_volume_slider.value * 100)


func _apply_audio_volumes() -> void:
	_set_bus_volume(AUDIO_BUS_MASTER, master_volume_slider.value)
	_set_bus_volume(AUDIO_BUS_MUSIC, music_volume_slider.value)
	_set_bus_volume(AUDIO_BUS_SFX, sfx_volume_slider.value)


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		# Bus doesn't exist yet — skip silently (buses will be set up later)
		return
	if linear_volume <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_volume))


func _save_settings() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	settings["master_volume"] = master_volume_slider.value
	settings["music_volume"] = music_volume_slider.value
	settings["sfx_volume"] = sfx_volume_slider.value
	SaveManager.data["settings"] = settings
	SaveManager.save_game()


func _on_master_volume_changed(_value: float) -> void:
	_update_value_labels()
	_apply_audio_volumes()


func _on_music_volume_changed(_value: float) -> void:
	_update_value_labels()
	_apply_audio_volumes()


func _on_sfx_volume_changed(_value: float) -> void:
	_update_value_labels()
	_apply_audio_volumes()


func _on_close_pressed() -> void:
	_save_settings()
	visible = false
