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
	
	# Configurar partes del ahorcado
	orden_partes = [cabeza, cuello, brazo_izq, brazo_der, tronco, pierna_izq, pierna_der]
	for parte in orden_partes:
		escalas_originales.append(parte.scale)
		parte.visible = false
	base_ahorcado.visible = true
	
	# Conectar temporizadores
	timer_principal.timeout.connect(_on_tiempo_agotado)
	tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	add_child(tick_timer)
	tick_timer.timeout.connect(_on_timer_tick)
	
	# NUEVO: Conectar detección de la bestia
	if bestia.has_node("DetectionArea"):
		var detection_area = bestia.get_node("DetectionArea")
		detection_area.body_entered.connect(_on_bestia_detecta)
	
	_actualizar_display()
	_actualizar_timer_display()
	
	# Iniciar diálogo
	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()

# NUEVO: Función llamada cuando la bestia detecta al jugador
func _on_bestia_detecta(body: Node2D) -> void:
	if not juego_activo:
		return
	if body == player:
		_game_over()

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
	
	# NUEVO (opcional): Activar patrulla de la bestia si es necesario
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
	
	_actualizar_display()
	_verificar_victoria()

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
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room4.tscn")  # Ajusta la ruta
		return
	
	if fallos >= orden_partes.size():
		_game_over()

# ------------------------------
# MOVIMIENTO (sin persecución)
# ------------------------------
func _process(delta):
	if not juego_activo:
		return
	
	# Solo límites para el jugador (sin mover a la bestia)
	var limite_izq = 50
	var limite_der = 1150
	var limite_sup = 50
	var limite_inf = 650
	player.position.x = clamp(player.position.x, limite_izq, limite_der)
	player.position.y = clamp(player.position.y, limite_sup, limite_inf)
	
	# ELIMINADO: código de persecución y distancia

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
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")  # Reinicia la misma escena

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

# ------------------------------
# ENTRADA DE TECLADO
# ------------------------------
func _input(event):
	if not juego_activo:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var letra = char(event.keycode).to_upper()
		if letra.length() == 1 and letra >= "A" and letra <= "Z":
			_on_letra_presionada(letra)
