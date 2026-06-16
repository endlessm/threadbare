extends Node
@onready var tiempo = %BalderPresente
var mi_timer: Timer
@onready var is_stopped =false
@export var tiempo_detenido = 3
func _ready() -> void:
	mi_timer = Timer.new()
	mi_timer.wait_time = 10.0
	mi_timer.one_shot = false
	mi_timer.timeout.connect(_on_timer)
	get_parent().call_deferred("add_child", mi_timer)
	mi_timer.call_deferred("start")

func _on_timer() -> void:
	mi_timer.stop()
	if is_stopped:
		return;
	tiempo._parar_tiempo()
	var tiempo_a_parar = 3+tiempo_detenido
	await get_tree().create_timer(tiempo_a_parar).timeout
	mi_timer.start()
	tiempo._reanudar_mundo()

func _reset_animacion():
	print("reseteando animacion...")
	await get_tree().create_timer(2.5).timeout
	print("animacion reseteada")
	%AnimadorEfectos.play("RESET")

func _esta_detenido(estado:bool):
	is_stopped = estado;
