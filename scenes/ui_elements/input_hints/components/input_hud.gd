extends CanvasLayer


@onready var movement_input_hint: HBoxContainer = $TabContainer/NormalControls/MovementInputHint
@onready var run_input_hint: HBoxContainer = $TabContainer/NormalControls/RunInputHint
@onready var repel_input_hint: HBoxContainer = $TabContainer/NormalControls/RepelInputHint
@onready var aim_input_hint: HBoxContainer = $TabContainer/NormalControls/AimInputHint
@onready var throw_input_hint: HBoxContainer = $TabContainer/NormalControls/ThrowInputHint
@onready var sokoban_controls: HBoxContainer = $TabContainer/SokobanControls
@onready var skip_input_hint: HBoxContainer = $TabContainer/SokobanControls/SkiptInputHint
@onready var interact_input_hint: HBoxContainer = $TabContainer/NormalControls/InteractInputHint


func _ready() -> void:
	if get_tree().current_scene.scene_file_path in GameState.TRANSIENT_SCENES:
		visible = false
	get_tree().scene_changed.connect(_on_scene_changed)
	if _is_sakoban_level(get_tree().current_scene.scene_file_path):
		sokoban_controls.visible = true
	else: 
		sokoban_controls.visible = false
	skip_input_hint.visible = false


func _on_scene_changed() -> void:
	if get_tree().current_scene.scene_file_path in GameState.TRANSIENT_SCENES:
		visible = false
	else:
		visible = true
	if _is_sakoban_level(get_tree().current_scene.scene_file_path):
		sokoban_controls.visible = true
	else: 
		sokoban_controls.visible = false
	skip_input_hint.visible = false


func _on_player_mode_changed(mode: Player.Mode) -> void:
	if mode == Player.Mode.FIGHTING:
		repel_input_hint.visible = true
		aim_input_hint.visible = false
		throw_input_hint.visible = false
	elif mode == Player.Mode.HOOKING:
		repel_input_hint.visible = false
		aim_input_hint.visible = true
		throw_input_hint.visible = true
	else:
		repel_input_hint.visible = false
		aim_input_hint.visible = false
		throw_input_hint.visible = false


func _is_sakoban_level(scene_path: String) -> bool:
	return scene_path.begins_with("res://scenes/eternal_loom_sokoban/")


func display_skip() -> void: 
	skip_input_hint.visible = true
