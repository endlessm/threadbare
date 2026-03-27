extends CanvasLayer


@onready var normal_controls: HBoxContainer = $TabContainer/NormalControls
@onready var movement_input_hint: HBoxContainer = $TabContainer/NormalControls/MovementInputHint
@onready var run_input_hint: HBoxContainer = $TabContainer/NormalControls/RunInputHint
@onready var repel_input_hint: HBoxContainer = $TabContainer/NormalControls/RepelInputHint
@onready var aim_input_hint: HBoxContainer = $TabContainer/NormalControls/AimInputHint
@onready var throw_input_hint: HBoxContainer = $TabContainer/NormalControls/ThrowInputHint
@onready var sokoban_controls: HBoxContainer = $TabContainer/SokobanControls
@onready var skip_input_hint: HBoxContainer = $TabContainer/SokobanControls/SkiptInputHint
@onready var interact_input_hint: HBoxContainer = $TabContainer/NormalControls/InteractInputHint


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed()


func _on_scene_changed() -> void:
	if get_tree().current_scene.scene_file_path in GameState.TRANSIENT_SCENES \
		or not get_tree().current_scene.scene_file_path == "res://scenes/menus/splash/splash.tscn":
		visible = false
	var player: Player = get_tree().get_first_node_in_group("player")
	var sokoban_ruleset: RuleEngine = get_tree().get_first_node_in_group("sokoban_ruleset")
	if player:
		normal_controls.visible = true
		player.mode_changed.connect(_on_player_mode_changed)
		_on_player_mode_changed(player.mode)
	elif sokoban_ruleset:
		sokoban_controls.visible = true
		sokoban_ruleset.skip_enabled.connect(display_skip)
	else:
		visible = false
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


func display_skip() -> void: 
	skip_input_hint.visible = true
