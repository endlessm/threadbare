extends Node2D

const PALABRAS = ["CARTA"]
const SPEED_ZOMBIE = 40

var palabra_secreta = ""
var intento_actual = 0
var tiempo_restante = 120
var juego_activo = false  # ← Ahora empieza en false hasta que termine el diálogo

# Referencia al diálogo
@onready var dialogue_balloon = $Dialogue  # Ajusta la ruta si lo pusiste en otro lado
@onready var input_letra = $CanvasGroup/InputLetra
@onready var grid_letras = $CanvasGroup/Panel/GridLetras
@onready var label_mensaje = $CanvasGroup/Panel/LabelMensaje
@onready var label_tiempo = $CanvasGroup/LabelTiempo
@onready var timer_principal = $Timer
@onready var zombie = $Zombie
@onready var player = $Player

func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]

	# Hacer que la capa de oscuridad ignore los clics (evita que bloquee el LineEdit)
	var dark_overlay = get_node_or_null("CanvasLayer/DarknessOverlay")
	if dark_overlay:
		var color_rect = dark_overlay.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Configurar el grid de letras
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

	# Deshabilitar la UI del juego hasta que termine el diálogo
	input_letra.editable = false
	input_letra.focus_mode = Control.FOCUS_NONE
	label_mensaje.text = "Escucha el acertijo..."
	timer_principal.stop()  # El temporizador no empieza aún
	# Opcional: ocultar el temporizador o dejarlo en 00:00
	label_tiempo.text = "00:00"

	# Conectar señales del diálogo
	if dialogue_balloon:
		# El balloon emite tree_exited cuando se cierra (al terminar el diálogo)
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		# Iniciar el diálogo
		_iniciar_dialogo()
	else:
		print("Error: No se encontró el nodo Dialogue. Asegúrate de instanciar balloon.tscn como hijo de Room1.")
		# Si no hay diálogo, empezar el juego directamente (fallback)
		_iniciar_juego()

	# Conectar el LineEdit (solo se usará cuando el juego esté activo)
	input_letra.text_submitted.connect(_on_palabra_enviada)

	# Señales de letras ocultas (para el jugador)
	player.letra_iluminada.connect(_on_letra_iluminada)
	player.letra_oscurecida.connect(_on_letra_oscurecida)

	# Tick de 1 segundo para el contador (lo creamos pero no lo activamos hasta el inicio)
	var tick = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = false
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)
	# Guardamos referencia para iniciarlo después
	set_meta("tick_timer", tick)

func _iniciar_dialogo():
	# Cargar el recurso de diálogo (ajusta la ruta según tu proyecto)
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/acertijo.dialogue")
	if dialogue_resource:
		dialogue_balloon.start(dialogue_resource, "start")
	else:
		print("No se pudo cargar el diálogo. Iniciando juego directamente.")
		_iniciar_juego()

func _on_dialogue_finished():
	# Cuando el diálogo termina (se cierra el balloon), comenzamos el juego
	_iniciar_juego()

func _iniciar_juego():
	juego_activo = true
	# Activar el LineEdit
	input_letra.editable = true
	input_letra.focus_mode = Control.FOCUS_ALL
	input_letra.grab_focus()
	label_mensaje.text = "Escribe tu intento (5 letras)"
	# Iniciar temporizador de 120 segundos
	tiempo_restante = 120
	_actualizar_timer_display()
	timer_principal.start(120)  # El timer principal para game over
	timer_principal.timeout.connect(_on_tiempo_agotado)
	# Iniciar el timer de tick (1 segundo)
	var tick = get_meta("tick_timer")
	if tick:
		tick.start()
	# El zombie ya se moverá en _process cuando juego_activo sea true

# El resto de funciones se mantienen casi igual, pero añadimos comprobación de juego_activo
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
		juego_activo = false
		label_mensaje.text = "¡Correcto! La puerta se abre..."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.tscn")
	else:
		intento_actual += 1
		if intento_actual >= 6:
			_game_over()
		else:
			label_mensaje.text = "Intento %d/6" % intento_actual

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
