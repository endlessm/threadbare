extends Node2D

signal jefe_muerto

@export var patrones: Array[Node] = []
@export var vida_jefe: int = 2
@export var barra: TextureProgressBar
@export var animacionPlayer: AnimatedSprite2D
@export var animacionEnemy: AnimatedSprite2D
@export var corazon: Node
@export var tiempoEntrePatrones: float = 5.0

@export var tiempoAnimacionDano: float = 0.6
@export var tiempoAnimacionAtaque: float = 0.6

@export var tiempo_antes_pelea: float = 2.0

var indice_actual: int = 0
var vida_total: int = 0
var activo: bool = false
var estado_final: bool = false
var vida_anterior_corazon: int = -1
var enemigo_en_accion: bool = false

func _ready() -> void:
	vida_total = vida_jefe
	
	if barra != null:
		barra.max_value = vida_total
		barra.value = vida_jefe

	if animacionEnemy != null:
		animacionEnemy.play("idle")

	if corazon != null:
		if corazon.has_signal("murio"):
			corazon.connect("murio", Callable(self, "_on_corazon_murio"))

		if corazon.has_signal("vida_cambio"):
			corazon.connect("vida_cambio", Callable(self, "_on_corazon_vida_cambio"))

		var vida_actual_corazon = corazon.get("vida_actual")
		if vida_actual_corazon != null:
			vida_anterior_corazon = vida_actual_corazon

	iniciar_con_delay()

func iniciar_con_delay() -> void:
	if animacionEnemy != null:
		animacionEnemy.play("transformacion")

	await get_tree().create_timer(tiempo_antes_pelea).timeout
	if animacionEnemy !=null:
		animacionEnemy.play("idle")

	iniciar()

func iniciar() -> void:
	if activo:
		return

	if patrones.is_empty():
		return

	activo = true
	loop_patrones()

func loop_patrones() -> void:
	while activo and vida_jefe > 0:
		var patron = patrones[indice_actual]

		patron.start_pattern()

		await patron.pattern_finished

		if not activo:
			return

		patron.stop_pattern()

		if corazon != null and corazon.has_method("reproducir_ataque"):
			corazon.reproducir_ataque()
		else:
			if animacionPlayer != null:
				animacionPlayer.play("atack")

		reproducir_dano_enemigo()

		await get_tree().create_timer(tiempoEntrePatrones).timeout

		if not activo:
			return

		vida_jefe -= 1

		if vida_jefe < 0:
			vida_jefe = 0

		if barra != null:
			barra.value = vida_jefe

		if vida_jefe <= 0:
			morir_jefe()
			return

		indice_actual += 1

		if indice_actual >= patrones.size():
			indice_actual = 0

func reproducir_dano_enemigo() -> void:
	if estado_final:
		return

	enemigo_en_accion = true

	if animacionEnemy != null:
		animacionEnemy.play("dead")

	await get_tree().create_timer(tiempoAnimacionDano).timeout

	enemigo_en_accion = false

	if not estado_final and vida_jefe > 1:
		if animacionEnemy != null:
			animacionEnemy.play("idle")

func _on_corazon_vida_cambio(vida_actual: int, vida_maxima: int) -> void:
	if estado_final:
		return

	if vida_anterior_corazon == -1:
		vida_anterior_corazon = vida_actual
		return

	if vida_actual < vida_anterior_corazon:
		reproducir_ataque_enemigo()

	vida_anterior_corazon = vida_actual

func reproducir_ataque_enemigo() -> void:
	if estado_final:
		return

	enemigo_en_accion = true

	if animacionEnemy != null:
		animacionEnemy.play("atack")

	await get_tree().create_timer(tiempoAnimacionAtaque).timeout

	enemigo_en_accion = false

	if not estado_final and vida_jefe > 0:
		if animacionEnemy != null:
			animacionEnemy.play("idle")

func morir_jefe() -> void:
	estado_final = true
	activo = false
	detener_patrones()

	if animacionEnemy != null:
		animacionEnemy.play("dead")

	jefe_muerto.emit()

func _on_corazon_murio() -> void:
	estado_final = true
	activo = false
	detener_patrones()

	if animacionEnemy != null:
		animacionEnemy.play("win")

func detener_patrones() -> void:
	for p in patrones:
		p.stop_pattern()
