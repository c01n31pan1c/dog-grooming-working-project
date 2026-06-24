## SceneManager — Handles scene loading and unloading with transition support.
## Autoloaded singleton. Manages swapping the current scene tree's active scene.
extends Node

## Emitted just before the old scene is freed.
signal scene_unloading(old_scene_path: String)
## Emitted after the new scene is added to the tree.
signal scene_loaded(new_scene_path: String)

var _current_scene: Node = null
var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Grab the initial scene from the tree (set by project.godot main_scene)
	var root := get_tree().root
	_current_scene = root.get_child(root.get_child_count() - 1)


## Switch to a new scene by file path.
## This is a deferred call to avoid issues mid-frame.
func goto_scene(scene_path: String) -> void:
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring request for %s" % scene_path)
		return
	_is_transitioning = true
	# Defer the actual swap to end of frame
	call_deferred("_deferred_goto_scene", scene_path)


func _deferred_goto_scene(scene_path: String) -> void:
	EventBus.loading_started.emit()

	# Free old scene
	if _current_scene != null:
		var old_path := _current_scene.scene_file_path if _current_scene.scene_file_path else ""
		scene_unloading.emit(old_path)
		_current_scene.free()
		_current_scene = null

	# Load new scene
	var packed_scene := ResourceLoader.load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("SceneManager: Failed to load scene at %s" % scene_path)
		_is_transitioning = false
		return

	_current_scene = packed_scene.instantiate()
	get_tree().root.add_child(_current_scene)

	# Make it the active scene for get_tree().current_scene
	get_tree().current_scene = _current_scene

	scene_loaded.emit(scene_path)
	EventBus.loading_finished.emit()
	_is_transitioning = false
