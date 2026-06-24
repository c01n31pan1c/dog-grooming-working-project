## DataLoader — Loads Resource files (.tres) from the resources/ directories.
## Utility class for loading breed, tool, judge, and upgrade data.
class_name DataLoader
extends Node


static func load_all_breeds() -> Array[Resource]:
	return _load_resources_from("res://resources/breeds/", "tres")


static func load_all_tools() -> Array[Resource]:
	return _load_resources_from("res://resources/tools/", "tres")


static func load_all_judges() -> Array[Resource]:
	return _load_resources_from("res://resources/judges/", "tres")


static func load_all_upgrades() -> Array[Resource]:
	return _load_resources_from("res://resources/upgrades/", "tres")


static func load_all_competitions() -> Array[Resource]:
	return _load_resources_from("res://resources/competitions/", "tres")


static func _load_resources_from(dir_path: String, extension: String) -> Array[Resource]:
	var results: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("DataLoader: Could not open directory %s" % dir_path)
		return results

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.get_extension() == extension or file_name.ends_with(".%s.remap" % extension)):
			var res := ResourceLoader.load(dir_path + file_name.replace(".remap", ""))
			if res != null:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results
