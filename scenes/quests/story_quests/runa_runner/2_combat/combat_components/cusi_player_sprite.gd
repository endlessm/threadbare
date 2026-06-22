extends AnimatedSprite2D

@onready var player: Player = owner

var _last_direction := Vector2.DOWN


func _process(_delta: float) -> void:
	if not player:
		return
	if animation in [&"attack_01", &"attack_02", &"defeated"]:
		return

	var velocity := player.velocity
	if velocity.is_zero_approx():
		_play_directional(&"idle")
		return

	_last_direction = velocity.normalized()
	var movement_animation := &"walk"
	if animation == &"run" or animation == &"run_down" or animation == &"run_up" or animation == &"run_side":
		movement_animation = &"run"
	_play_directional(movement_animation)


func _play_directional(base_animation: StringName) -> void:
	var animation_name := base_animation
	if absf(_last_direction.x) > absf(_last_direction.y):
		animation_name = StringName("%s_side" % base_animation)
		flip_h = _last_direction.x > 0
	elif _last_direction.y < 0:
		animation_name = StringName("%s_up" % base_animation)
		flip_h = false
	else:
		animation_name = StringName("%s_down" % base_animation)
		flip_h = false

	if sprite_frames and sprite_frames.has_animation(animation_name):
		if animation != animation_name:
			play(animation_name)
	elif animation != base_animation:
		play(base_animation)


func look_at_side(side: Enums.LookAtSide) -> void:
	if side == 0:
		return
	_last_direction = Vector2.LEFT if side < 0 else Vector2.RIGHT
	flip_h = side > 0
