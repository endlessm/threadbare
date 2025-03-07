class_name Enemy
extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
var is_awake: bool = false

func got_hit():
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
		
