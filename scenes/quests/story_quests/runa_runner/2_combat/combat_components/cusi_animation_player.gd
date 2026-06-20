extends AnimationPlayer

var _is_player_running: bool
var _last_direction := Vector2.DOWN

@onready var player: Player = owner
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_repel: PlayerRepel = %PlayerRepel
@onready var player_hook: PlayerHook = %PlayerHook
@onready var original_speed_scale: float = speed_scale


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	player.mode_changed.connect(_on_player_mode_changed)
	player_repel.repelling_changed.connect(_on_player_repel_repelling_changed)
	player_hook.string_thrown.connect(_on_player_hook_string_thrown)


func _process(_delta: float) -> void:
	if player.mode == player.Mode.DEFEATED:
		return
	if current_animation in [&"repel", &"throw_string"]:
		return

	if is_playing():
		stop()

	var movement_animation := &"idle"
	if not player.velocity.is_zero_approx():
		_last_direction = player.velocity.normalized()
		movement_animation = &"run" if _is_player_running else &"walk"

	_play_sprite_direction(movement_animation)
	speed_scale = original_speed_scale


func _play_sprite_direction(base_animation: StringName) -> void:
	var animation_name := base_animation
	if absf(_last_direction.x) > absf(_last_direction.y):
		animation_name = StringName("%s_side" % base_animation)
		player_sprite.flip_h = _last_direction.x > 0
	elif _last_direction.y < 0:
		animation_name = StringName("%s_up" % base_animation)
		player_sprite.flip_h = false
	else:
		animation_name = StringName("%s_down" % base_animation)
		player_sprite.flip_h = false

	if player_sprite.sprite_frames.has_animation(animation_name):
		if player_sprite.animation != animation_name:
			player_sprite.play(animation_name)
	elif player_sprite.animation != base_animation:
		player_sprite.play(base_animation)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"repel" and player_repel.repelling:
		speed_scale = original_speed_scale
		play(&"repel")


func _on_player_mode_changed(_mode: Player.Mode) -> void:
	if player.mode == Player.Mode.DEFEATED:
		speed_scale = original_speed_scale
		play(&"defeated")


func _on_player_repel_repelling_changed(repelling: bool) -> void:
	if not repelling:
		return
	if current_animation == &"repel":
		return
	speed_scale = original_speed_scale
	play(&"repel")
	seek(player_repel.REPEL_ANTICIPATION_TIME, false, false)


func _on_player_hook_string_thrown() -> void:
	if current_animation in [&"repel", &"throw_string"]:
		stop()
	speed_scale = original_speed_scale
	play(&"throw_string")


func _on_input_walk_behavior_running_changed(is_running: bool) -> void:
	_is_player_running = is_running
