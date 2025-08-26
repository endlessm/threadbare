extends Node2D # o KinematicBody2D según sea tu nodo padre

func _ready():
	$AnimatedSprite2D.play("walk")
