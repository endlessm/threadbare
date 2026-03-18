extends CanvasLayer


@onready var repel_hint: HBoxContainer = $HBoxContainer/RepelHint
@onready var aim_input_hint: Control = $HBoxContainer/AimInputHint
@onready var throw_hint: HBoxContainer = $HBoxContainer/ThrowHint


func _ready() -> void:
	if get_tree().current_scene.scene_file_path in GameState.TRANSIENT_SCENES:
		visible = false
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
	if get_tree().current_scene.scene_file_path in GameState.TRANSIENT_SCENES:
		visible = false
	else:
		visible = true


func _on_player_mode_changed(mode: Player.Mode) -> void:
	if mode == Player.Mode.FIGHTING:
		repel_hint.visible = true
		aim_input_hint.visible = false
		throw_hint.visible = false
	elif mode == Player.Mode.HOOKING:
		repel_hint.visible = false
		aim_input_hint.visible = true
		throw_hint.visible = true
	else:
		repel_hint.visible = false
		aim_input_hint.visible = false
		throw_hint.visible = false
