extends Node2D
class_name PestilloArea

var zonas_totales: int = 6
var zonas_correctas: Array[int] = []
var progreso: int = 0
var cinematic_node  # Referencia a la cinemática
@onready var musica=$AudioStreamPlayer2D
@onready var cronometro: Timer = $Cronometro
@onready var label_cronometro: Label = $"../../ScreenOverlay/CronometroLabel"

var tiempo_total: float = 30.0
var tiempo_restante: float = tiempo_total

func _ready() -> void:
	cronometro.wait_time = 1.0
	cronometro.one_shot = false
	cronometro.autostart = false
	cronometro.timeout.connect(_on_cronometro_tick)

	# Obtener nodo de la cinemática
	cinematic_node = get_tree().get_first_node_in_group("cinematica")
	if cinematic_node:
		cinematic_node.cinematica_terminada.connect(_iniciar_puzzle)
	else:
		_iniciar_puzzle()

	# Conectar zonas
	for i in range(1, zonas_totales + 1):
		var path = "objetos/Area2D" + str(i)
		if has_node(path):
			var area = get_node(path)
			area.input_event.connect(_on_zona_click.bind(i))

func reiniciar_zonas() -> void:
	label_cronometro.add_theme_color_override("font_color", Color(0, 0, 0))
	progreso = 0
	var indices: Array[int] = []
	for i in range(1, zonas_totales + 1):
		indices.append(i)
	indices.shuffle()
	zonas_correctas = indices.duplicate()

	print("🔄 Nuevas zonas correctas:", zonas_correctas)

	for i in range(1, zonas_totales + 1):
		var pestillo = get_node("objetos/Area2D" + str(i))
		if pestillo.has_method("soltar"):
			pestillo.soltar()

	tiempo_restante = tiempo_total
	_actualizar_label()

func _on_zona_click(_viewport: Viewport, event: InputEvent, _shape_idx: int, zona_id: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var zona_esperada: int = zonas_correctas[progreso]
		var pestillo = get_node("objetos/Area2D" + str(zona_id))

		if zona_id == zona_esperada:
			pestillo.presionar_y_quedarse()
			progreso += 1
			if progreso >= zonas_correctas.size():
				cronometro.stop()
				musica.stop()
				if cinematic_node:
					cinematic_node.notificar_ganador()
		else:
			await pestillo.presionar_temporal()
			$AudioStreamPlayer2D2.play()
			for i in range(1, zonas_totales + 1):
				var p = get_node("objetos/Area2D" + str(i))
				if p.presionado:
					p.soltar()
			progreso = 0

func _on_cronometro_tick() -> void:
	tiempo_restante -= 1
	_actualizar_label()

	if tiempo_restante < 15:
		label_cronometro.add_theme_color_override("font_color", Color(1, 0, 0))

	if tiempo_restante <= 0:
		if cinematic_node:
			musica.stop()
			cinematic_node.notificar_perdida()
		reiniciar_zonas()

func _actualizar_label() -> void:
	label_cronometro.text = "Tiempo: %02d" % int(tiempo_restante)

func _iniciar_puzzle() -> void:
	reiniciar_zonas()
	musica.play()  # Iniciar música cuando comienza el cronómetro
	cronometro.start()

func _on_cinematica_cinematica_terminada() -> void:
	pass  # Ya no es necesario si se usa el grupo "cinematica"
