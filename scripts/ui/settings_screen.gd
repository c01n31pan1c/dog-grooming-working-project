## SettingsScreen — Standalone settings scene.
## Volume sliders + meta info, built with DGC design-system components.
## Saves settings through SaveManager.
extends Node

const AUDIO_BUS_MASTER := "Master"
const AUDIO_BUS_MUSIC := "Music"
const AUDIO_BUS_SFX := "SFX"

var _master_slider: DGCSlider
var _music_slider: DGCSlider
var _sfx_slider: DGCSlider
var _close_button: DGCButton


func _ready() -> void:
	GameManager.current_state = GameManager.GameState.SETTINGS
	_build_ui()
	_load_settings()


func _build_ui() -> void:
	var ui: Control = $UI

	# Main VBox layout filling the screen
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	ui.add_child(main_vbox)

	# --- ScreenHeader: back button + "SETTINGS" title + spacer ---
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
	back_icon.pressed.connect(_on_close_pressed)
	header_hbox.add_child(back_icon)

	var title_label := Label.new()
	title_label.text = "SETTINGS"
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

	# --- Scrollable content ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var scroll_margin := MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 22)
	scroll_margin.add_theme_constant_override("margin_right", 22)
	scroll_margin.add_theme_constant_override("margin_top", 12)
	scroll_margin.add_theme_constant_override("margin_bottom", 0)
	scroll_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_margin.add_child(scroll)
	main_vbox.add_child(scroll_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(content_vbox)

	# --- Audio Panel (DGCPanel) ---
	var audio_panel := DGCPanel.new()
	content_vbox.add_child(audio_panel)

	# We need to add sliders after the panel is ready, so defer
	audio_panel.ready.connect(_build_audio_panel.bind(audio_panel))

	# --- Meta Panel (DGCPanel) ---
	var meta_panel := DGCPanel.new()
	content_vbox.add_child(meta_panel)

	meta_panel.ready.connect(_build_meta_panel.bind(meta_panel))

	# --- Bottom: "Close" button ---
	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 22)
	bottom_margin.add_theme_constant_override("margin_right", 22)
	bottom_margin.add_theme_constant_override("margin_top", 0)
	bottom_margin.add_theme_constant_override("margin_bottom", 28)
	main_vbox.add_child(bottom_margin)

	_close_button = DGCButton.new()
	_close_button.text = "Close"
	_close_button.variant = DGCButton.Variant.PRIMARY
	_close_button.size = DGCButton.Size.MD
	_close_button.block = true
	_close_button.pressed.connect(_on_close_pressed)
	bottom_margin.add_child(_close_button)


func _build_audio_panel(panel: DGCPanel) -> void:
	# The DGCPanel builds an internal ContentVBox; add sliders there
	var content_vbox: VBoxContainer = panel.get_node_or_null("ContentVBox")
	if not content_vbox:
		content_vbox = panel.get_child(0) as VBoxContainer

	var slider_container := VBoxContainer.new()
	slider_container.add_theme_constant_override("separation", 18)
	content_vbox.add_child(slider_container)

	_master_slider = DGCSlider.new()
	_master_slider.label_text = "Master"
	_master_slider.min_val = 0.0
	_master_slider.max_val = 100.0
	_master_slider.step = 5.0
	_master_slider.value = 100.0
	_master_slider.value_changed.connect(_on_master_volume_changed)
	slider_container.add_child(_master_slider)

	_music_slider = DGCSlider.new()
	_music_slider.label_text = "Music"
	_music_slider.min_val = 0.0
	_music_slider.max_val = 100.0
	_music_slider.step = 5.0
	_music_slider.value = 80.0
	_music_slider.value_changed.connect(_on_music_volume_changed)
	slider_container.add_child(_music_slider)

	_sfx_slider = DGCSlider.new()
	_sfx_slider.label_text = "SFX"
	_sfx_slider.min_val = 0.0
	_sfx_slider.max_val = 100.0
	_sfx_slider.step = 5.0
	_sfx_slider.value = 100.0
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	slider_container.add_child(_sfx_slider)

	# Now load saved values into the sliders
	_load_settings()


func _build_meta_panel(panel: DGCPanel) -> void:
	var content_vbox: VBoxContainer = panel.get_node_or_null("ContentVBox")
	if not content_vbox:
		content_vbox = panel.get_child(0) as VBoxContainer

	var meta_label := Label.new()
	meta_label.text = "Controls: coming soon\nVersion 0.1.0\nCredits: placeholder"
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 15)
	meta_label.add_theme_color_override("font_color", DesignTokens.INK_MUTED)
	if DesignTokens.font_body_semibold:
		meta_label.add_theme_font_override("font", DesignTokens.font_body_semibold)
	content_vbox.add_child(meta_label)


func _load_settings() -> void:
	if not _master_slider:
		return
	var settings: Dictionary = SaveManager.data.get("settings", {})
	var master_vol: float = settings.get("master_volume", 1.0)
	var music_vol: float = settings.get("music_volume", 0.8)
	var sfx_vol: float = settings.get("sfx_volume", 1.0)

	_master_slider.value = master_vol * 100.0
	_music_slider.value = music_vol * 100.0
	_sfx_slider.value = sfx_vol * 100.0

	_apply_audio_volumes()


func _apply_audio_volumes() -> void:
	if not _master_slider:
		return
	_set_bus_volume(AUDIO_BUS_MASTER, _master_slider.value / 100.0)
	_set_bus_volume(AUDIO_BUS_MUSIC, _music_slider.value / 100.0)
	_set_bus_volume(AUDIO_BUS_SFX, _sfx_slider.value / 100.0)


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
	if not _master_slider:
		return
	var settings: Dictionary = SaveManager.data.get("settings", {})
	settings["master_volume"] = _master_slider.value / 100.0
	settings["music_volume"] = _music_slider.value / 100.0
	settings["sfx_volume"] = _sfx_slider.value / 100.0
	SaveManager.data["settings"] = settings
	SaveManager.save_game()


func _on_master_volume_changed(_value: float) -> void:
	_apply_audio_volumes()


func _on_music_volume_changed(_value: float) -> void:
	_apply_audio_volumes()


func _on_sfx_volume_changed(_value: float) -> void:
	_apply_audio_volumes()


func _on_close_pressed() -> void:
	_save_settings()
	GameManager.change_state(GameManager.GameState.SALON)
