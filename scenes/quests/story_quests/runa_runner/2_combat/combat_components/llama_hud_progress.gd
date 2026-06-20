extends PanelContainer

@export var rescue_state_path: NodePath
@export var default_story_progress_path: NodePath
@export var empty_texture: Texture2D
@export var filled_texture: Texture2D

@onready var slots: HBoxContainer = %Slots


func _ready() -> void:
	call_deferred("_hide_default_story_progress")

	var rescue_state: Node = _get_rescue_state()
	if rescue_state:
		if rescue_state.has_signal("progress_changed"):
			rescue_state.connect("progress_changed", Callable(self, "_on_progress_changed"))

		var rescued_count: int = 0
		var total_llamas: int = slots.get_child_count()
		if rescue_state.has_method("get_rescued_count"):
			rescued_count = int(rescue_state.call("get_rescued_count"))
		if rescue_state.has_method("get_total_llamas"):
			total_llamas = int(rescue_state.call("get_total_llamas"))
		_on_progress_changed(rescued_count, total_llamas)
	else:
		_on_progress_changed(0, slots.get_child_count())


func _on_progress_changed(rescued_count: int, total_llamas: int) -> void:
	var visible_slots: int = mini(total_llamas, slots.get_child_count())
	for index in range(slots.get_child_count()):
		var slot: TextureRect = slots.get_child(index) as TextureRect
		slot.visible = index < visible_slots
		slot.texture = filled_texture if index < rescued_count else empty_texture
		slot.modulate = Color.WHITE


func _hide_default_story_progress() -> void:
	if default_story_progress_path.is_empty():
		return

	var default_story_progress: CanvasItem = get_node_or_null(default_story_progress_path) as CanvasItem
	if default_story_progress:
		default_story_progress.visible = false


func _get_rescue_state() -> Node:
	if not rescue_state_path.is_empty():
		var state: Node = get_node_or_null(rescue_state_path)
		if state:
			return state

	return get_tree().get_first_node_in_group("llama_rescue_state")
