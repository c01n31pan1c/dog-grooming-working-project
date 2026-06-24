## SceneTransition — Fade-to-black transition between scenes.
## Implemented as a CanvasLayer with a ColorRect that tweens alpha.
## Autoloaded or added to the persistent scene tree.
##
## Usage:
##   SceneTransition.transition_out() — fade to black
##   SceneTransition.transition_in() — fade from black to clear
extends CanvasLayer

## Duration of each fade direction in seconds.
@export var fade_duration: float = 0.3

## The overlay ColorRect used for fading.
var _overlay: ColorRect
## Active tween reference.
var _tween: Tween

## Emitted when transition_out completes (screen fully black).
signal transition_out_completed()
## Emitted when transition_in completes (screen fully visible).
signal transition_in_completed()


func _ready() -> void:
	layer = 100  # Render above everything
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create the overlay programmatically so this script works standalone
	_overlay = ColorRect.new()
	_overlay.color = Color(0.831, 0.914, 0.969, 0)  # Start transparent — pastel blue fade
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Full-screen anchoring
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.size = Vector2(1920, 1080)

	# Connect to SceneManager so we auto-play transitions
	SceneManager.scene_unloading.connect(_on_scene_unloading)
	SceneManager.scene_loaded.connect(_on_scene_loaded)


## Fade the screen to black. Await this to know when it completes.
func transition_out() -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during transition
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, fade_duration)
	_tween.tween_callback(func() -> void:
		transition_out_completed.emit()
	)
	await _tween.finished


## Fade from black back to visible. Await this to know when it completes.
## Includes a subtle zoom effect (1.02 -> 1.0) on the new scene for smoothness.
func transition_in() -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	# Apply subtle zoom-in on the scene root if available
	var scene_root := get_tree().current_scene
	if scene_root:
		var ui_node := scene_root.get_node_or_null("UI") as Control
		if ui_node:
			UIAnimations.scene_entrance_zoom(ui_node, fade_duration)

	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 0.0, fade_duration)
	_tween.tween_callback(func() -> void:
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Re-enable input
		transition_in_completed.emit()
	)
	await _tween.finished


func _on_scene_unloading(_old_scene_path: String) -> void:
	# Scene is about to be freed — ensure we're black
	_overlay.color.a = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_scene_loaded(_new_scene_path: String) -> void:
	# New scene is ready — fade in
	transition_in()
