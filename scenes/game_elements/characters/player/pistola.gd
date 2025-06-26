extends Node2D
class_name pistola

@export var move_speed: float = 150.0
@onready var pistola: Node2D = $pistola
@export var escena_bala: PackedScene
@onready var sprite_personaje: Sprite2D = $pistola/Sprite2D


func _ready():
	configurar_inputs()

func configurar_inputs():
	if not InputMap.has_action("disparar"):
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.add_action("disparar")
		InputMap.action_add_event("disparar", mouse_event)
func _physics_process(_delta):
	actualizar_pistola()
	if Input.is_action_just_pressed("disparar"):
		disparar()

func actualizar_pistola():
	var direccion = (get_global_mouse_position() - global_position).normalized()
	var angulo = direccion.angle()
	pistola.rotation = angulo
	var radio = 20.0
	pistola.position = Vector2.RIGHT.rotated(angulo) * radio
	var angulo_grados = rad_to_deg(angulo)

	if angulo_grados > 90 or angulo_grados < -90:
		sprite_personaje.flip_v = true  
	else:
		sprite_personaje.flip_v = false

func disparar():
	var bala = escena_bala.instantiate()
	bala.global_position =$pistola/Marker2D.global_position
	print("Marker pos local: ", $pistola/Marker2D.position)
	print("Marker pos global: ", $pistola/Marker2D.global_position)
	bala.direction = Vector2.RIGHT.rotated($pistola.global_rotation)
	get_tree().current_scene.add_child(bala)
