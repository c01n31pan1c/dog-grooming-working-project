## BreedViewer — Displays breed information in the Breed-pedia.
## Stub for WS-6.
class_name BreedViewer
extends Node

var _current_breed: Resource = null


func show_breed(breed_data: Resource) -> void:
	_current_breed = breed_data
	# WS-6 implements: populate UI with breed info, facts, grooming guide


func get_current_breed() -> Resource:
	return _current_breed
