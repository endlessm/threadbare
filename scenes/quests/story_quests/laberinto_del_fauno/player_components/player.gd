@tool
extends Player

const LERP_SPEED: float = 0.15
const ESCALA_NORMAL: float = 6.5
const ESCALA_CORRER: float = 3.5

@onready var light_texture: Light2D = $Light/Light

func _process(delta: float) -> void:
	super._process(delta)

	if is_instance_valid($Light):
		if velocity.x < 0:
			$Light.scale.x = -1
		elif velocity.x > 0:
			$Light.scale.x = 1

	if is_instance_valid(light_texture):
		var target_scale: float
		if is_running():
			target_scale = ESCALA_CORRER
		else:
			target_scale = ESCALA_NORMAL

		light_texture.texture_scale = lerp(light_texture.texture_scale, target_scale, LERP_SPEED)
