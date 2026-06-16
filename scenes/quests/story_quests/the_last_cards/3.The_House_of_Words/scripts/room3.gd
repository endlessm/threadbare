extends Node2D

# ------------------------------
# CONSTANTES
# ------------------------------
const PALABRAS = [
	"TUMBA", "CRUDA", "BRUJA", "HORROR", "PANICO",
	"TERROR", "SOMBRA", "CRIPTA", "CADAVER", "ESPECTRO",
	"TINIEBLA", "FANTASMA", "OSCURIDAD", "MALDICION"
]

# ------------------------------
# VARIABLES DEL JUEGO
# ------------------------------
var palabra_secreta = ""
var letras_adivinadas = []
var letras_falladas = []
var fallos = 0
var tiempo_restante = 60
var juego_activo = false
var tick_timer: Timer
var puerta_instanciada = false
var door = null

# ------------------------------
# REFERENCIAS A NODOS (UI)
# ------------------------------
@onready var label_palabra = $CanvasGroup/Panel/LabelPalabra
@onready var label_letras_usadas = $CanvasGroup/Panel/LabelLetrasUsadas
@onready var label_tiempo = $CanvasGroup/LabelTiempo
@onready var timer_principal = $Timer
@onready var bestia = $Bestia
@onready var player = $Player
@onready var dialogue_balloon = $Dialogue
@onready var musica_fondo = $MusicaFondo
@onready var teclado = $CanvasGroup/CanvasLayer/Teclado  

# ------------------------------
# REFERENCIAS A LAS PARTES DEL AHORCADO
# ------------------------------
@onready var base_ahorcado = $PartesAhorcado/Soporte
@onready var cabeza = $PartesAhorcado/Cabeza
@onready var cuello = $PartesAhorcado/Cuello
@onready var brazo_izq = $PartesAhorcado/BrazoIzquierdo
@onready var brazo_der = $PartesAhorcado/BrazoDerecho
@onready var tronco = $PartesAhorcado/Tronco
@onready var pierna_izq = $PartesAhorcado/PiernaIzquierdo
@onready var pierna_der = $PartesAhorcado/PiernaDerecho

var orden_partes = []
var escalas_originales = []

# ------------------------------
# INICIALIZACIÓN
# ------------------------------
func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]

	orden_partes = [cabeza, cuello, brazo_izq, brazo_der, tronco, pierna_izq, pierna_der]
	for parte in orden_partes:
		escalas_originales.append(parte.scale)
		parte.visible = false
	base_ahorcado.visible = true

	timer_principal.timeout.connect(_on_tiempo_agotado)
	tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	add_child(tick_timer)
	tick_timer.timeout.connect(_on_timer_tick)

	if bestia.has_node("DetectionArea"):
		var detection_area = bestia.get_node("DetectionArea")
		detection_area.body_entered.connect(_on_bestia_detecta)

	# Conectar teclado virtual
	if teclado:
		teclado.letra_presionada.connect(_on_letra_teclado)
	_agregar_boton_borrar()

	_actualizar_display()
	_actualizar_timer_display()

	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()

# ------------------------------
# TECLADO VIRTUAL
# ------------------------------
func _agregar_boton_borrar() -> void:
	if not teclado:
		return
	var fila3 = teclado.get_node_or_null("Fila3")
	if not fila3:
		return
	# En ahorcado no necesitamos borrar, pero agregamos un botón de ENTER
	# por si se quiere confirmar visualmente (opcional)
	# En ahorcado cada letra se envía de una sola vez, no hace falta acumular

func _on_letra_teclado(letra: String) -> void:
	if not juego_activo:
		return
	_on_letra_presionada(letra)

# ------------------------------
# BESTIA
# ------------------------------
func _on_bestia_detecta(body: Node2D) -> void:
	if not juego_activo:
		return
	if body == player:
		_game_over()

# ------------------------------
# DIÁLOGO
# ------------------------------
func _iniciar_dialogo():
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/room3.dialogue")
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
	tiempo_restante = 60
	_actualizar_timer_display()
	timer_principal.start(60)
	tick_timer.start()
	label_letras_usadas.text = "Errores: (0/7)"

	if bestia.has_node("GuardMovement"):
		var guard_movement = bestia.get_node("GuardMovement")
		if guard_movement.has_method("start_moving_now"):
			guard_movement.start_moving_now()

# ------------------------------
# LÓGICA DE LETRAS
# ------------------------------
func _on_letra_presionada(letra: String):
	if not juego_activo:
		return
	if letra in letras_adivinadas or letra in letras_falladas:
		return

	if palabra_secreta.contains(letra):
		letras_adivinadas.append(letra)
	else:
		letras_falladas.append(letra)
		fallos += 1
		_mostrar_parte_ahorcado()
		# Deshabilitar visualmente el botón presionado
		_marcar_letra_usada(letra)

	_actualizar_display()
	_verificar_victoria()

func _marcar_letra_usada(letra: String) -> void:
	if not teclado:
		return
	for fila in [teclado.get_node_or_null("Fila1"), teclado.get_node_or_null("Fila2"), teclado.get_node_or_null("Fila3")]:
		if not fila:
			continue
		for boton in fila.get_children():
			if boton is Button and boton.text == letra:
				var estilo_usado = StyleBoxFlat.new()
				estilo_usado.bg_color = Color(0.4, 0.1, 0.1)  # Rojo oscuro = fallo
				estilo_usado.corner_radius_top_left = 8
				estilo_usado.corner_radius_top_right = 8
				estilo_usado.corner_radius_bottom_left = 8
				estilo_usado.corner_radius_bottom_right = 8
				boton.add_theme_stylebox_override("normal", estilo_usado)
				boton.add_theme_stylebox_override("hover", estilo_usado)
				boton.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _marcar_letra_correcta(letra: String) -> void:
	if not teclado:
		return
	for fila in [teclado.get_node_or_null("Fila1"), teclado.get_node_or_null("Fila2"), teclado.get_node_or_null("Fila3")]:
		if not fila:
			continue
		for boton in fila.get_children():
			if boton is Button and boton.text == letra:
				var estilo_correcto = StyleBoxFlat.new()
				estilo_correcto.bg_color = Color(0.1, 0.5, 0.1)  # Verde = correcto
				estilo_correcto.corner_radius_top_left = 8
				estilo_correcto.corner_radius_top_right = 8
				estilo_correcto.corner_radius_bottom_left = 8
				estilo_correcto.corner_radius_bottom_right = 8
				boton.add_theme_stylebox_override("normal", estilo_correcto)
				boton.add_theme_stylebox_override("hover", estilo_correcto)
				boton.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _mostrar_parte_ahorcado():
	var indice = fallos - 1
	if indice >= 0 and indice < orden_partes.size():
		var parte = orden_partes[indice]
		parte.visible = true
		_animar_aparicion(parte, indice)

func _animar_aparicion(parte: Node2D, idx: int):
	parte.scale = Vector2.ZERO
	var escala_final = escalas_originales[idx]
	var tween = create_tween()
	tween.tween_property(parte, "scale", escala_final, 0.2).set_ease(Tween.EASE_OUT)

# ------------------------------
# ACTUALIZACIÓN DE UI
# ------------------------------
func _actualizar_display():
	var display = ""
	for letra in palabra_secreta:
		if letra in letras_adivinadas:
			display += letra + " "
			_marcar_letra_correcta(letra)
		else:
			display += "_ "
	label_palabra.text = display.strip_edges()
	label_letras_usadas.text = "Errores: " + " ".join(letras_falladas) + " (%d/%d)" % [fallos, orden_partes.size()]

func _actualizar_timer_display():
	var minutos = int(tiempo_restante) / 60
	var segundos = int(tiempo_restante) % 60
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]

# ------------------------------
# CONDICIONES DE VICTORIA / DERROTA
# ------------------------------
func _verificar_victoria():
	var gano = true
	for letra in palabra_secreta:
		if letra not in letras_adivinadas:
			gano = false
			break

	if gano:
		juego_activo = false
		label_palabra.text = "¡ESCAPASTE!"
		if not puerta_instanciada:
			var door_scene = load("res://scenes/game_elements/props/door/door.tscn")
			if door_scene:
				door = door_scene.instantiate()
				add_child(door)
				door.global_position = player.global_position + Vector2(100, 0)
				door.open()
				puerta_instanciada = true
		await _mostrar_dialogo_victoria()
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room4.tscn")
		return

	if fallos >= orden_partes.size():
		_game_over()

# ------------------------------
# MOVIMIENTO
# ------------------------------
func _process(delta):
	if not juego_activo:
		return


# ------------------------------
# TEMPORIZADORES
# ------------------------------
func _on_tiempo_agotado():
	_game_over()

func _on_timer_tick():
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()

# ------------------------------
# GAME OVER
# ------------------------------
func _game_over():
	juego_activo = false
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")

# ------------------------------
# DIÁLOGO DE VICTORIA
# ------------------------------
func _mostrar_dialogo_victoria():
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

# Teclado físico bloqueado completamente
func _input(_event: InputEvent):
	pass
