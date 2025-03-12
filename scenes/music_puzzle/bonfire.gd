class_name Bonfire
extends StaticBody2D

@onready var fire: AnimatedSprite2D = %Fire

func ignite() -> void:
	fire.animation = &"burning"
	fire.play()
