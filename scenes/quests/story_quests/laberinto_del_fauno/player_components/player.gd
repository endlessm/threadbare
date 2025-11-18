@tool
extends Player

var life: int= 3
const LERP_SPEED: float = 0.15
const ESCALA_NORMAL: float = 6.5
const ESCALA_CORRER: float = 3.5
@onready var pos: Vector2 = $"../Checkpoint/Zona1".global_position
@onready var light_texture: Light2D = $Light/Light

var knockback:Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

func _process(delta: float) -> void:
	super._process(delta)
	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer-= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
		move_and_slide()
	else:
		mode = Mode.COZY
	if velocity.x < 0:
		$Light.scale.x = -1
	elif velocity.x > 0:
		$Light.scale.x = 1

	var target_scale: float
	if is_running():
		target_scale = ESCALA_CORRER
	else:
		target_scale = ESCALA_NORMAL

	light_texture.texture_scale = lerp(light_texture.texture_scale, target_scale, LERP_SPEED)

	if life == 0:
		global_position = pos
		life = 3

func apply_knockback(direcion:Vector2, force: float, knockback_duration:float) -> void:
	print("1")
	mode = Mode.DEFEATED
	knockback = direcion * force
	knockback_timer = knockback_duration
