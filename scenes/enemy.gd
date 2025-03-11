class_name Enemy
extends CharacterBody2D

const FX = preload("res://scenes/fx.tscn")
const FX_FRAMES_02 = preload("res://scenes/fx_frames_02.tres")

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
var is_awake: bool = false

func got_hit(bullet_global_position: Vector2, hit_vector: Vector2):
	var fx = FX.instantiate()
	# fx.frames = FX_FRAMES_02
	Engine.get_main_loop().current_scene.add_child(fx)
	fx.global_position = bullet_global_position

	if not is_awake:
		is_awake = true
		animated_sprite_2d.play(&"first hit")
		await animated_sprite_2d.animation_finished
		animated_sprite_2d.play(&"idle 2")
	else:
		is_awake = false
		animated_sprite_2d.play(&"second hit")
		await animated_sprite_2d.animation_finished
		animated_sprite_2d.play(&"idle")
		
