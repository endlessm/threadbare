extends Node2D

@onready var sonido_arma1 = $disparo_arma1
@onready var mira_disparo = $mira_disparo
@onready var recarga_arma1 = $recarga_arma1
@onready var sonido_arma_recarga = $AudioStreamPlayer2D

@export var cargador_max = 12
var disparos_restantes = cargador_max
var recargando = false

var bala_scene = preload("res://scenes/quests/story_quests/spacerage/pruebas/bala.tscn") 

func _ready():
	recarga_arma1.timeout.connect(_on_recarga_arma1_timeout)

func _process(delta):
	look_at(get_global_mouse_position())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if disparos_restantes > 0 and not recargando:
			disparar()
		elif disparos_restantes == 0 and not recargando:
			recargar()

func disparar():
	var bala = bala_scene.instantiate()
	bala.global_position = mira_disparo.global_position
	bala.direccion = (get_global_mouse_position() - bala.global_position).normalized()
	bala.daño = 3 
	get_tree().current_scene.add_child(bala)
	sonido_arma1.play()
	disparos_restantes -= 1

func recargar():
	sonido_arma_recarga.play()
	recargando = true
	recarga_arma1.start() 
	
func _on_recarga_arma1_timeout():
	disparos_restantes = cargador_max
	recargando = false
