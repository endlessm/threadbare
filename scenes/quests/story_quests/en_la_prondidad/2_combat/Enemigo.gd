extends Node2D

@export var patrones: Array[Node] = []
@export var duraciones: Array[float] = []
@export var vida_jefe: int = 1

var indice_actual: int = 0
var activo: bool = false
var vida_total: int = 1

@onready var barra: ProgressBar = $"../../CanvasLayer/Control/ProgressBarenemy"

func _ready() -> void:
	barra.max_value = vida_total
	barra.value = vida_jefe
	iniciar()

func iniciar() -> void:
	activo = true
	run()

func run() -> void:
	while activo and vida_jefe > 0:
		if indice_actual >= patrones.size():
			indice_actual = 0

		var patron = patrones[indice_actual]
		var tiempo = duraciones[indice_actual]

		patron.start_pattern()

		await get_tree().create_timer(tiempo).timeout

		patron.stop_pattern()

		vida_jefe -= 1
		barra.value = vida_jefe   

		indice_actual += 1

	if vida_jefe <= 0:
		fin()

func fin() -> void:
	activo = false

	for p in patrones:
		p.stop_pattern()
