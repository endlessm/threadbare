@tool
extends Talker

@export var advance_after_dialogue: bool = false
@export_file("*.tscn") var next_scene: String = ""
@export var rescue_state_path: NodePath
@export var incomplete_dialogue: DialogueResource

var _can_advance := false

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	if advance_after_dialogue:
		talk_behavior.before_dialogue = Callable(self, "_prepare_final_dialogue")
		interact_area.interaction_ended.connect(_advance_to_next_scene)


func _prepare_final_dialogue() -> void:
	_can_advance = _has_all_llamas()
	talk_behavior.dialogue = dialogue if _can_advance or incomplete_dialogue == null else incomplete_dialogue


func _advance_to_next_scene() -> void:
	if not _can_advance or next_scene.is_empty():
		return

	if GameState.quest:
		GameState.quest.challenge_start_scene = next_scene

	SceneSwitcher.change_to_file_with_transition(
		next_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)


func _has_all_llamas() -> bool:
	var rescue_state := _get_rescue_state()
	if not rescue_state or not rescue_state.has_method("has_all_llamas"):
		return false

	return rescue_state.call("has_all_llamas") == true


func _get_rescue_state() -> Node:
	if not rescue_state_path.is_empty():
		var state := get_node_or_null(rescue_state_path)
		if state:
			return state

	return get_tree().get_first_node_in_group("llama_rescue_state")
