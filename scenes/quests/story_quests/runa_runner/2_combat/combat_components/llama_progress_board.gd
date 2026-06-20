extends Node2D

@export var rescue_state_path: NodePath

@onready var slots: Node2D = %Slots


func _ready() -> void:
	var rescue_state := _get_rescue_state()
	if rescue_state:
		if rescue_state.has_signal("progress_changed"):
			rescue_state.connect("progress_changed", Callable(self, "_on_progress_changed"))

		var rescued_count := 0
		var total_llamas := slots.get_child_count()
		if rescue_state.has_method("get_rescued_count"):
			rescued_count = int(rescue_state.call("get_rescued_count"))
		if rescue_state.has_method("get_total_llamas"):
			total_llamas = int(rescue_state.call("get_total_llamas"))
		_on_progress_changed(rescued_count, total_llamas)
	else:
		_on_progress_changed(0, slots.get_child_count())


func _on_progress_changed(rescued_count: int, _total_llamas: int) -> void:
	for index in range(slots.get_child_count()):
		slots.get_child(index).visible = index < rescued_count


func _get_rescue_state() -> Node:
	if not rescue_state_path.is_empty():
		var state := get_node_or_null(rescue_state_path)
		if state:
			return state

	return get_tree().get_first_node_in_group("llama_rescue_state")
