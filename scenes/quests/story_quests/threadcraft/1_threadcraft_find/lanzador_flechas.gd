extends Node2D
@export var escena_flecha: PackedScene

func _ready():
	$Timer.timeout.connect(_disparar_flecha)

func _disparar_flecha():
	if escena_flecha:
		var flecha = escena_flecha.instantiate()
		flecha.global_position = global_position
		get_tree().current_scene.add_child(flecha)
