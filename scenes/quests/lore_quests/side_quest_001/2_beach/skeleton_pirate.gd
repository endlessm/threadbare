extends Area2D

var got_hat: bool = false
@export var exit_blocker: StaticBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func put_hat_on() -> void:
	got_hat = true
	animated_sprite.play("Skeleton_withhat")
	
func remove_exit_blocker() -> void:
	if exit_blocker != null:
		exit_blocker.queue_free()
