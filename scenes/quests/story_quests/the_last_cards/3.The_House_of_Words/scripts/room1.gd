extends Node2D

const PALABRAS = ["CARTA"]
const SPEED_ZOMBIE = 40

var palabra_secreta = ""
var intento_actual = 0
var tiempo_restante = 120
var juego_activo = false
var puerta_instanciada = false

@onready var dialogue_balloon = $Dialogue
@onready var input_letra = $CanvasGroup/InputLetra
@onready var grid_letras = $CanvasGroup/Panel/GridLetras
@onready var label_mensaje = $CanvasGroup/Panel/LabelMensaje
@onready var label_tiempo = $CanvasGroup/LabelTiempo
@onready var timer_principal = $Timer
@onready var zombie = $Zombie
@onready var player = $Player
@onready var musica_fondo = $MusicaFondo

var door = null

func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]

	# Oscuridad ignore clics
	var dark_overlay = get_node_or_null("CanvasLayer/DarknessOverlay")
	if dark_overlay:
		var color_rect = dark_overlay.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Configurar grid de letras
	for i in range(30):
		var label = grid_letras.get_child(i)
		label.custom_minimum_size = Vector2(70, 70)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.25)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.4, 0.6)
		label.add_theme_stylebox_override("normal", sb)

	# Deshabilitar UI hasta diálogo
	input_letra.editable = false
	input_letra.focus_mode = Control.FOCUS_NONE
	label_mensaje.text = "Escucha el acertijo..."
	timer_principal.stop()
	label_tiempo.text = "00:00"

	if musica_fondo:
		musica_fondo.stop()

	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()

	input_letra.text_submitted.connect(_on_palabra_enviada)
	player.letra_iluminada.connect(_on_letra_iluminada)
	player.letra_oscurecida.connect(_on_letra_oscurecida)

	var tick = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = false
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)
	set_meta("tick_timer", tick)

func _iniciar_dialogo():
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/acertijo.dialogue")
	if dialogue_resource:
		dialogue_balloon.start(dialogue_resource, "start")
	else:
		_iniciar_juego()

func _on_dialogue_finished():
	await get_tree().process_frame
	_iniciar_juego()

func _iniciar_juego():
	juego_activo = true
	if musica_fondo and not musica_fondo.playing:
		musica_fondo.play()

	input_letra.editable = true
	input_letra.focus_mode = Control.FOCUS_ALL
	input_letra.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	input_letra.grab_focus()
	label_mensaje.text = "Escribe tu intento (5 letras)"
	tiempo_restante = 120
	_actualizar_timer_display()
	timer_principal.start(120)
	timer_principal.timeout.connect(_on_tiempo_agotado)
	var tick = get_meta("tick_timer")
	if tick:
		tick.start()

func _on_letra_iluminada(nodo: Node2D) -> void:
	if not juego_activo: return
	if nodo.has_method("revelar_desde_player"):
		nodo.revelar_desde_player()

func _on_letra_oscurecida(nodo: Node2D) -> void:
	if not juego_activo: return
	if nodo.has_method("oscurecer_desde_player"):
		nodo.oscurecer_desde_player()

func _actualizar_timer_display():
	var minutos = int(tiempo_restante) / 60
	var segundos = int(tiempo_restante) % 60
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]

func _process(delta):
	if not juego_activo:
		return
	var dir = (player.position - zombie.position).normalized()
	zombie.position += dir * SPEED_ZOMBIE * delta
	if zombie.position.distance_to(player.position) < 80:
		_game_over()

func _on_palabra_enviada(texto: String):
	if not juego_activo:
		return
	var intento = texto.to_upper().strip_edges()
	input_letra.text = ""
	input_letra.grab_focus()

	if intento.length() != 5:
		label_mensaje.text = "Escribe exactamente 5 letras"
		return

	_evaluar_intento(intento)

func _evaluar_intento(intento: String):
	for i in range(5):
		var label = grid_letras.get_child(intento_actual * 5 + i)
		label.text = intento[i]
		if intento[i] == palabra_secreta[i]:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.55, 0.2)))
		elif palabra_secreta.contains(intento[i]):
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.6, 0.5, 0.0)))
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.3, 0.3, 0.3)))

	if intento == palabra_secreta:
		# VICTORIA
		juego_activo = false
		if musica_fondo and musica_fondo.playing:
			musica_fondo.stop()

		if not puerta_instanciada:
			var door_scene = load("res://scenes/game_elements/props/door/door.tscn")
			door = door_scene.instantiate()
			add_child(door)
			door.global_position = player.global_position + Vector2(100, 0)
			door.open()
			puerta_instanciada = true

		# Mostrar diálogo de victoria
		await _mostrar_dialogo_victoria()
		
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.tscn")
		return
	else:
		intento_actual += 1
		if intento_actual >= 6:
			_game_over()
		else:
			label_mensaje.text = "Intento %d/6" % intento_actual

func _mostrar_dialogo_victoria():
	# Cargar la escena del balloon (ajusta la ruta si es diferente)
	var balloon_scene = load("res://scenes/ui_elements/dialogue/balloon.tscn")
	if not balloon_scene:
		print("Error: no se encontró balloon.tscn")
		return
	
	var victoria_balloon = balloon_scene.instantiate()
	add_child(victoria_balloon)
	
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/victoria.dialogue")
	if dialogue_resource:
		victoria_balloon.start(dialogue_resource, "start")
		await victoria_balloon.tree_exited
	else:
		print("No se pudo cargar el diálogo de victoria")
		victoria_balloon.queue_free()

func _crear_fondo(color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	return sb

func _on_tiempo_agotado():
	_game_over()

func _on_timer_tick():
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()

func _game_over():
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	juego_activo = false
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/GameOver.tscn")

func _input(event: InputEvent):
	if not juego_activo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var rect = input_letra.get_global_rect()
		if rect.has_point(event.position):
			input_letra.grab_focus()
		else:
			input_letra.release_focus()
