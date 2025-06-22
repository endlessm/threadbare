extends Node2D
@export var escena_flecha: PackedScene
@export var direccion_flecha: Vector2 = Vector2.DOWN

func _ready():
	$Timer.wait_time = 1.0
	$Timer.one_shot = false
	$Timer.start()
	$Timer.timeout.connect(_disparar_flecha)

func _disparar_flecha():
	var flecha = escena_flecha.instantiate()
	flecha.global_position = global_position
	flecha.direccion = direccion_flecha
	get_parent().add_child(flecha)
