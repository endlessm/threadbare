extends Node2D

signal jefe_muerto

@export var patrones: Array[Node] = []
@export var vida_jefe: int = 2
@export var barra: TextureProgressBar
@export var animacionPlayer: AnimatedSprite2D
@export var animacionEnemy: AnimatedSprite2D
@export var corazon: Node
@export var tiempoEntrePatrones: float = 5.0

var indice_actual: int = 0
var vida_total: int = 0
var activo: bool = false

func _ready() -> void:
	vida_total = vida_jefe

	barra.max_value = vida_total
	barra.value = vida_jefe

	if corazon != null:
		corazon.murio.connect(_on_corazon_murio)

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

		animacionEnemy.play("hit")
		animacionPlayer.play("atack")

		await get_tree().create_timer(tiempoEntrePatrones).timeout

		if not activo:
			return

		vida_jefe -= 1
		barra.value = vida_jefe

		if vida_jefe <= 0:
			morir_jefe()
			return

		indice_actual += 1

		if indice_actual >= patrones.size():
			indice_actual = 0

func morir_jefe() -> void:
	activo = false
	detener_patrones()
	animacionEnemy.play("dead")
	jefe_muerto.emit()

func _on_corazon_murio() -> void:
	activo = false
	detener_patrones()
	animacionEnemy.play("win")

func detener_patrones() -> void:
	for p in patrones:
		p.stop_pattern()
