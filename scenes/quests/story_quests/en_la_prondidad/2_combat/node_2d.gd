extends Node2D

@export var patrones: Array[Node] = []
@export var tiempo_entre_patrones: float = 5.0
@export var tiempo_antes_de_iniciar: float = 2.0
@export var autostart: bool = true

@export var corazon: Node

var activo: bool = false
var estado_final: bool = false
var vida_anterior_corazon: int = -1


func _ready() -> void:
	if corazon != null:
		if corazon.has_signal("murio"):
			corazon.connect("murio", Callable(self, "_on_corazon_murio"))

		if corazon.has_signal("vida_cambio"):
			corazon.connect("vida_cambio", Callable(self, "_on_corazon_vida_cambio"))

		var vida_actual_corazon = corazon.get("vida_actual")
		if vida_actual_corazon != null:
			vida_anterior_corazon = vida_actual_corazon

	if autostart:
		iniciar_con_delay()


func iniciar_con_delay() -> void:
	await get_tree().create_timer(tiempo_antes_de_iniciar).timeout
	start_controller()


func start_controller() -> void:
	if activo or patrones.is_empty() or estado_final:
		return

	activo = true
	loop_patrones()


func stop_controller() -> void:
	activo = false
	detener_todos_los_patrones()


func loop_patrones() -> void:
	var total_patrones = patrones.size()
	
	for i in total_patrones:
		if not activo or estado_final:
			return

		var patron = patrones[i]

		patron.start_pattern()

		await patron.pattern_finished

		if not activo or estado_final:
			return

		patron.stop_pattern()

		if corazon != null and corazon.has_method("reproducir_ataque"):
			corazon.reproducir_ataque()

		if i < total_patrones - 1:
			await get_tree().create_timer(tiempo_entre_patrones).timeout

	stop_controller()


func detener_todos_los_patrones() -> void:
	for p in patrones:
		if is_instance_valid(p) and p.has_method("stop_pattern"):
			p.stop_pattern()


func _on_corazon_vida_cambio(vida_actual: int, _vida_maxima: int) -> void:
	if estado_final:
		return

	if vida_anterior_corazon == -1:
		vida_anterior_corazon = vida_actual
		return

	vida_anterior_corazon = vida_actual


func _on_corazon_murio() -> void:
	estado_final = true
	stop_controller()


func _on_jefe_muerto() -> void:
	estado_final = true
	stop_controller()
