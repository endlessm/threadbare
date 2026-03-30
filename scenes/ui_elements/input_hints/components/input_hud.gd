extends CanvasLayer


@onready var normal_controls: HBoxContainer = $TabContainer/NormalControls
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
		or get_tree().current_scene.scene_file_path == "res://scenes/menus/splash/splash.tscn":
		visible = false
	var player: Player = get_tree().get_first_node_in_group("player")
	var sokoban_ruleset: RuleEngine = get_tree().get_first_node_in_group("sokoban_ruleset")
	if player:
		visible = true
		normal_controls.visible = true
		if player.player_repel:
			_connect_player(player)
		else:
			await player.ready
			_connect_player(player)
	elif sokoban_ruleset:
		visible = true
		sokoban_controls.visible = true
		sokoban_ruleset.skip_enabled.connect(display_skip)
	else:
		visible = false
	skip_input_hint.visible = false


func _connect_player(player: Player) -> void:
	player.player_interaction.can_interact.connect(_on_player_interaction_can_interact)
	player.player_repel.visibility_changed.connect(_on_player_repel_visibility_changed.bind(player))
	_on_player_repel_visibility_changed(player)
	player.player_hook.visibility_changed.connect(_on_player_hook_visibility_changed.bind(player))
	_on_player_hook_visibility_changed(player)


func _on_player_interaction_can_interact(can_interact: bool) -> void:
	interact_input_hint.visible = can_interact


func _on_player_repel_visibility_changed(player: Player) -> void:
	if player:
		repel_input_hint.visible = player.player_repel.visible


func _on_player_hook_visibility_changed(player: Player) -> void:
	if player:
		throw_input_hint.visible = player.player_hook.visible
		aim_input_hint.visible = player.player_hook.visible


func display_skip() -> void:
	skip_input_hint.visible = true
