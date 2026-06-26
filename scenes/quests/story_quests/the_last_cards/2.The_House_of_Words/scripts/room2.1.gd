extends Node2D

const PALABRAS = ["FUTURO"]

var palabra_secreta: String = ""
var intento_actual: int = 0
var tiempo_restante: float = 120
var juego_activo: bool = false
var puerta_instanciada: bool = false
var palabra_actual: String = ""

@onready var dialogue_balloon: Node = $Dialogue
@onready var input_letra: LineEdit = $CanvasGroup/InputLetra
@onready var grid_letras: GridContainer = $CanvasGroup/Panel/GridLetras
@onready var label_mensaje: Label = $CanvasGroup/Panel/LabelMensaje
@onready var label_tiempo: Label = $CanvasGroup/LabelTiempo
@onready var timer_principal: Timer = $Timer
@onready var zombie: CharacterBody2D = $Zombie
@onready var player: CharacterBody2D = $Player
@onready var musica_fondo: AudioStreamPlayer2D = $MusicaFondo
@onready var teclado: Node = $CanvasGroup/CanvasLayer/Teclado
@onready var guardia1: Node2D = $Guard
@onready var guardia2: Node2D = $Guard2
@onready var guardia3: Node2D = $Guard3
@onready var puerta_fija: Node2D = $Puerta
@onready var puerta_fija2: Node2D = $Puerta2

var door: Node2D = null


func _ready() -> void:
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]
	puerta_fija.global_position = Vector2(2573, 730)
	puerta_fija2.global_position = Vector2(2573, 115)

	for i in range(36):
		var label: Label = grid_letras.get_child(i)
		label.custom_minimum_size = Vector2(65, 65)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.25)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.4, 0.6)
		label.add_theme_stylebox_override("normal", sb)

	# Input físico deshabilitado siempre
	input_letra.editable = false
	input_letra.focus_mode = Control.FOCUS_NONE
	input_letra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_mensaje.text = "Escucha el diálogo..."
	timer_principal.stop()
	label_tiempo.text = "00:00"

	timer_principal.timeout.connect(_on_tiempo_agotado)

	var tick: Timer = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = false
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)
	set_meta("tick_timer", tick)

	player.letra_iluminada.connect(_on_letra_iluminada)
	player.letra_oscurecida.connect(_on_letra_oscurecida)

	# Conectar teclado virtual
	if teclado:
		teclado.letra_presionada.connect(_on_letra_teclado)
	_agregar_boton_borrar()

	if musica_fondo:
		musica_fondo.stop()

	# Conectar zombie (igual que en Room1/Room2): no se mueve hasta que empiece el juego
	if zombie:
		zombie.player_detected.connect(_on_player_detected)
		zombie.set_activo(false)

	# En esta sala las puertas ya se pueden abrir desde el inicio (no hay condición previa)
	_actualizar_estado_puertas_inicial()

	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()


func _on_player_detected(_player_node: Node2D) -> void:
	_game_over()


func _agregar_boton_borrar() -> void:
	if not teclado:
		return
	var fila3: Node = teclado.get_node_or_null("Fila3")
	if not fila3:
		return
	var boton_borrar: Button = Button.new()
	boton_borrar.text = "⌫"
	boton_borrar.custom_minimum_size = Vector2(80, 60)
	var estilo_normal: StyleBoxFlat = StyleBoxFlat.new()
	estilo_normal.bg_color = Color(0.8, 0.2, 0.2)
	estilo_normal.corner_radius_top_left = 8
	estilo_normal.corner_radius_top_right = 8
	estilo_normal.corner_radius_bottom_left = 8
	estilo_normal.corner_radius_bottom_right = 8
	var estilo_hover: StyleBoxFlat = StyleBoxFlat.new()
	estilo_hover.bg_color = Color(1.0, 0.3, 0.3)
	estilo_hover.corner_radius_top_left = 8
	estilo_hover.corner_radius_top_right = 8
	estilo_hover.corner_radius_bottom_left = 8
	estilo_hover.corner_radius_bottom_right = 8
	boton_borrar.add_theme_stylebox_override("normal", estilo_normal)
	boton_borrar.add_theme_stylebox_override("hover", estilo_hover)
	boton_borrar.add_theme_color_override("font_color", Color.WHITE)
	boton_borrar.pressed.connect(func() -> void: _on_letra_teclado("BORRAR"))
	fila3.add_child(boton_borrar)


func _on_letra_teclado(letra: String) -> void:
	if not juego_activo:
		return
	if letra == "BORRAR":
		if palabra_actual.length() > 0:
			palabra_actual = palabra_actual.left(palabra_actual.length() - 1)
			input_letra.text = palabra_actual
		return
	if palabra_actual.length() < 6:
		palabra_actual += letra
		input_letra.text = palabra_actual
	if palabra_actual.length() == 6:
		_procesar_intento(palabra_actual)
		palabra_actual = ""


func _procesar_intento(texto: String) -> void:
	if not juego_activo:
		return
	var intento: String = texto.to_upper().strip_edges()
	input_letra.text = ""
	palabra_actual = ""
	if intento.length() != 6:
		label_mensaje.text = "Escribe exactamente 6 letras"
		return
	_evaluar_intento(intento)


func _iniciar_dialogo() -> void:
	var dialogue_resource: Resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/parte2room2.dialogue")
	if dialogue_resource:
		dialogue_balloon.start(dialogue_resource, "start")
	else:
		_iniciar_juego()


func _on_dialogue_finished() -> void:
	await get_tree().process_frame
	_iniciar_juego()


func _iniciar_juego() -> void:
	juego_activo = true
	if musica_fondo and not musica_fondo.playing:
		musica_fondo.play()

	# Input físico siempre deshabilitado
	input_letra.editable = false
	input_letra.focus_mode = Control.FOCUS_NONE
	input_letra.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label_mensaje.text = "Escribe tu intento (6 letras)"
	tiempo_restante = 120
	_actualizar_timer_display()
	timer_principal.start(120)
	var tick: Timer = get_meta("tick_timer")
	if tick:
		tick.start()

	# El zombie empieza a moverse junto con el juego
	if zombie:
		zombie.set_activo(true)


func _on_letra_iluminada(nodo: Node2D) -> void:
	if not juego_activo:
		return
	if nodo.has_method("revelar_desde_player"):
		nodo.revelar_desde_player()


func _on_letra_oscurecida(nodo: Node2D) -> void:
	if not juego_activo:
		return
	if nodo.has_method("oscurecer_desde_player"):
		nodo.oscurecer_desde_player()


func _evaluar_intento(intento: String) -> void:
	for i in range(6):
		var label: Label = grid_letras.get_child(intento_actual * 6 + i)
		label.text = intento[i]
		if intento[i] == palabra_secreta[i]:
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.5, 0.2)))
			label.add_theme_color_override("font_color", Color.GREEN)
		elif palabra_secreta.contains(intento[i]):
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.5, 0.4, 0.1)))
			label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.2, 0.2)))
			label.add_theme_color_override("font_color", Color.WHITE)

	if intento == palabra_secreta:
		juego_activo = false
		if zombie:
			zombie.set_activo(false)
		if musica_fondo and musica_fondo.playing:
			musica_fondo.stop()
		if not puerta_instanciada:
			var door_scene: PackedScene = load("res://scenes/game_elements/props/door/door.tscn")
			door = door_scene.instantiate()
			add_child(door)
			door.global_position = player.global_position + Vector2(100, 0)
			door.open()
			puerta_instanciada = true
		await _mostrar_dialogo_victoria()
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")
		return
	else:
		intento_actual += 1
		if intento_actual >= 6:
			_game_over()
		else:
			label_mensaje.text = "Intento %d/6" % intento_actual
			_rehabilitar_teclado()


func _rehabilitar_teclado() -> void:
	if not teclado:
		return
	for fila: Node in [teclado.get_node_or_null("Fila1"), teclado.get_node_or_null("Fila2"), teclado.get_node_or_null("Fila3")]:
		if fila:
			for boton: Node in fila.get_children():
				boton.mouse_filter = Control.MOUSE_FILTER_STOP


func _crear_fondo(color: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = color
	return sb


func _on_tiempo_agotado() -> void:
	_game_over()


func _on_timer_tick() -> void:
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()


func _actualizar_timer_display() -> void:
	var minutos: int = int(tiempo_restante) / 60
	var segundos: int = int(tiempo_restante) % 60
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]


## Esta sala no tiene condición previa: ambas puertas se pueden abrir desde el inicio.
func _actualizar_estado_puertas_inicial() -> void:
	for puerta: Node2D in [puerta_fija, puerta_fija2]:
		if puerta:
			puerta.puede_abrirse = true
			puerta.mensaje_bloqueo = ""


func _game_over() -> void:
	juego_activo = false
	if zombie:
		zombie.set_activo(false)
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.1.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")


func _mostrar_dialogo_victoria() -> void:
	var balloon_scene: PackedScene = load("res://scenes/ui_elements/dialogue/balloon.tscn")
	if not balloon_scene:
		print("Error: no se encontró balloon.tscn")
		return
	var victoria_balloon: Node = balloon_scene.instantiate()
	add_child(victoria_balloon)
	var dialogue_resource: Resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/victoria.dialogue")
	if dialogue_resource:
		victoria_balloon.start(dialogue_resource, "start")
		await victoria_balloon.tree_exited
	else:
		print("No se pudo cargar el diálogo de victoria")
		victoria_balloon.queue_free()


# Teclado físico bloqueado completamente
func _input(_event: InputEvent) -> void:
	pass
