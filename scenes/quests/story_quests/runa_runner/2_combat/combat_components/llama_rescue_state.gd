extends Node

signal progress_changed(rescued_count: int, total_llamas: int)
signal all_llamas_rescued

@export var total_llamas: int = 3

var rescued_ids: Array[StringName] = []


func _ready() -> void:
	add_to_group("llama_rescue_state")
	progress_changed.emit(rescued_ids.size(), total_llamas)


func rescue_llama(llama_id: StringName) -> bool:
	if rescued_ids.has(llama_id):
		return false

	rescued_ids.append(llama_id)
	progress_changed.emit(rescued_ids.size(), total_llamas)

	if has_all_llamas():
		all_llamas_rescued.emit()

	return true


func has_all_llamas() -> bool:
	return rescued_ids.size() >= total_llamas


func get_rescued_count() -> int:
	return rescued_ids.size()


func get_total_llamas() -> int:
	return total_llamas
