extends Node2D

@export var enemigo_escena: PackedScene
@export var tiempo_entre_oleadas: float = 30.0
@export var radio_min: float = 150.0
@export var radio_max: float = 300.0

@onready var jugador = get_tree().get_first_node_in_group("player")

func _ready():
	spawn_enemigos()
	$Timer.wait_time = tiempo_entre_oleadas
	$Timer.start()

func _on_Timer_timeout():
	spawn_enemigos()

func spawn_enemigos():
	if jugador == null:
		return
	
	var cantidad = randi_range(2, 3)
	if randf() < 0.05:
		cantidad = 5
	
	print("🌑 Generando %d enemigos" % cantidad)
	
	for i in range(cantidad):
		var enemigo = enemigo_escena.instantiate()
		var angulo = randf() * TAU
		var distancia = randf_range(radio_min, radio_max)
		var offset = Vector2.RIGHT.rotated(angulo) * distancia
		enemigo.global_position = jugador.global_position + offset
		get_tree().current_scene.call_deferred("add_child", enemigo)
		print("👾 Enemigo generado en:", enemigo.global_position)


func _on_timer_timeout() -> void:
	spawn_enemigos()
