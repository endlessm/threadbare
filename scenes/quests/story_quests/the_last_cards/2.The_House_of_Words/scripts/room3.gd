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
var palabra_secreta: String = ""
var letras_adivinadas: Array[String] = []
var letras_falladas: Array[String] = []
var fallos: int = 0
var tiempo_restante: float = 60
var juego_activo: bool = false
var tick_timer: Timer
var puerta_instanciada: bool = false
var door: Node2D = null

# ------------------------------
# VARIABLES DE LA LLAVE
# ------------------------------
var partes_recogidas: int = 0
const TOTAL_PARTES = 3
var llave_completa: bool = false

# ------------------------------
# REFERENCIAS A NODOS
# ------------------------------
@onready var label_palabra: Label             = $CanvasGroup/Panel/LabelPalabra
@onready var label_letras_usadas: Label       = $CanvasGroup/Panel/LabelLetrasUsadas
@onready var label_tiempo: Label              = $CanvasGroup/LabelTiempo
@onready var label_llave: Label                = $CanvasGroup/Panel/LabelLlave
@onready var timer_principal: Timer           = $Timer
@onready var player: CharacterBody2D          = $Player
@onready var dialogue_balloon: Node            = $Dialogue
@onready var musica_fondo: AudioStreamPlayer2D = $MusicaFondo
@onready var teclado: Node                     = $CanvasGroup/CanvasLayer/Teclado

# ------------------------------
# ZOMBIES
# ------------------------------
@onready var zombie1: CharacterBody2D = $Zombie
@onready var zombie2: CharacterBody2D = $Zombie2
@onready var zombie3: CharacterBody2D = $Zombie3
@onready var zombie4: CharacterBody2D = $Zombie4

# ------------------------------
# PUERTAS
# ------------------------------
@onready var puerta_fija: Node2D  = $Puerta
@onready var puerta_fija2: Node2D = $Puerta2

# ------------------------------
# PARTES DEL AHORCADO
# ------------------------------
@onready var base_ahorcado: Node2D = $PartesAhorcado/Soporte
@onready var cabeza: Node2D        = $PartesAhorcado/Cabeza
@onready var cuello: Node2D        = $PartesAhorcado/Cuello
@onready var brazo_izq: Node2D     = $PartesAhorcado/BrazoIzquierdo
@onready var brazo_der: Node2D     = $PartesAhorcado/BrazoDerecho
@onready var tronco: Node2D        = $PartesAhorcado/Tronco
@onready var pierna_izq: Node2D    = $PartesAhorcado/PiernaIzquierdo
@onready var pierna_der: Node2D    = $PartesAhorcado/PiernaDerecho

var orden_partes: Array[Node2D] = []
var escalas_originales: Array[Vector2] = []

# ------------------------------
# INICIALIZACIÓN
# ------------------------------
func _ready() -> void:
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]

	puerta_fija.global_position  = Vector2(2573, 730)
	puerta_fija2.global_position = Vector2(2573, 115)

	orden_partes = [cabeza, cuello, brazo_izq, brazo_der, tronco, pierna_izq, pierna_der]
	for parte: Node2D in orden_partes:
		escalas_originales.append(parte.scale)
		parte.visible = false
	base_ahorcado.visible = true

	timer_principal.timeout.connect(_on_tiempo_agotado)
	tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	add_child(tick_timer)
	tick_timer.timeout.connect(_on_timer_tick)

	# Conectar zombies
	for zombie: CharacterBody2D in [zombie1, zombie2, zombie3, zombie4]:
		if zombie:
			zombie.player_detected.connect(_on_player_detected)
			zombie.set_activo(false)

	# Puertas bloqueadas hasta tener la llave completa
	_bloquear_puertas()

	# Conectar teclado virtual
	if teclado:
		teclado.letra_presionada.connect(_on_letra_teclado)
	_agregar_boton_borrar()

	_actualizar_display()
	_actualizar_timer_display()
	_actualizar_label_llave()

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
	var fila3: Node = teclado.get_node_or_null("Fila3")
	if not fila3:
		return
	# En ahorcado no necesitamos borrar


func _on_letra_teclado(letra: String) -> void:
	if not juego_activo:
		return
	_on_letra_presionada(letra)

# ------------------------------
# ZOMBIES
# ------------------------------
func _on_player_detected(_player_node: Node2D) -> void:
	if not juego_activo:
		return
	_game_over()

# ------------------------------
# PUERTAS
# ------------------------------
func _bloquear_puertas() -> void:
	for puerta: Node2D in [puerta_fija, puerta_fija2]:
		if puerta:
			puerta.puede_abrirse   = false
			puerta.mensaje_bloqueo = "Necesitas las 3 partes de la llave"


func _desbloquear_puertas() -> void:
	for puerta: Node2D in [puerta_fija, puerta_fija2]:
		if puerta:
			puerta.puede_abrirse   = true
			puerta.mensaje_bloqueo = ""

# ------------------------------
# SISTEMA DE LLAVE (3 partes)
# ------------------------------
func _setup_partes_llave() -> void:
	# ⚠️ Ajusta estas posiciones según tu mapa
	var posiciones: Array[Vector2] = [
		Vector2(800,  900),   # Parte 1 — dientes
		Vector2(2200, 300),   # Parte 2 — mango
		Vector2(3100, 1100),  # Parte 3 — cabeza
	]
	var texturas: Array[String] = [
		"res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/sprites/llave_parte_1.png",
		"res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/sprites/llave_parte_2.png",
		"res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/sprites/llave_parte_3.png",
	]

	var llave_script: Script = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scripts/LlaveParte.gd")
	if not llave_script:
		push_error("No se encontró LlaveParte.gd")
		return

	for i in range(TOTAL_PARTES):
		var parte: Area2D = Area2D.new()
		parte.set_script(llave_script)

		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite2D"
		var tex: Texture2D = load(texturas[i])
		if tex:
			sprite.texture = tex
		sprite.scale = Vector2(0.3, 0.3)
		parte.add_child(sprite)

		var col: CollisionShape2D = CollisionShape2D.new()
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 40.0
		col.shape = shape
		parte.add_child(col)

		add_child(parte)
		parte.global_position = posiciones[i]
		parte.parte_recogida.connect(_on_parte_llave_recogida)


func _on_parte_llave_recogida() -> void:
	partes_recogidas += 1
	_actualizar_label_llave()
	if partes_recogidas >= TOTAL_PARTES:
		llave_completa = true
		_desbloquear_puertas()
		_mostrar_llave_completa()


func _actualizar_label_llave() -> void:
	if not label_llave:
		return
	if llave_completa:
		label_llave.text = "🗝 ¡Llave completa!"
	else:
		label_llave.text = "🗝 Llave: %d / %d" % [partes_recogidas, TOTAL_PARTES]


func _mostrar_llave_completa() -> void:
	# Muestra la imagen de la llave completa brevemente en pantalla
	var sprite_completa: Sprite2D = Sprite2D.new()
	sprite_completa.texture = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/sprites/llave_completa.png")
	sprite_completa.scale   = Vector2(0.5, 0.5)
	add_child(sprite_completa)
	sprite_completa.global_position = player.global_position + Vector2(0, -80)

	# Sube y desaparece
	var tween: Tween = create_tween()
	tween.tween_property(sprite_completa, "position:y", sprite_completa.position.y - 60, 0.8)
	tween.parallel().tween_property(sprite_completa, "modulate:a", 0.0, 0.8)
	await tween.finished
	sprite_completa.queue_free()

	# Parpadeo del label
	if label_llave:
		var t2: Tween = create_tween()
		t2.tween_property(label_llave, "modulate", Color(1, 1, 0), 0.25)
		t2.tween_property(label_llave, "modulate", Color(1, 1, 1), 0.25)
		t2.set_loops(5)

# ------------------------------
# DIÁLOGO
# ------------------------------
func _iniciar_dialogo() -> void:
	var dialogue_resource: Resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/room3.dialogue")
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
	tiempo_restante = 60
	_actualizar_timer_display()
	timer_principal.start(60)
	tick_timer.start()
	label_letras_usadas.text = "Errores: (0/7)"

	# Zombies activos
	for zombie: CharacterBody2D in [zombie1, zombie2, zombie3, zombie4]:
		if zombie:
			zombie.set_activo(true)

	# Aparecen las partes de la llave
	_setup_partes_llave()

# ------------------------------
# LÓGICA DE LETRAS
# ------------------------------
func _on_letra_presionada(letra: String) -> void:
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
		_marcar_letra_usada(letra)

	_actualizar_display()
	_verificar_victoria()


func _marcar_letra_usada(letra: String) -> void:
	if not teclado:
		return
	for fila: Node in [teclado.get_node_or_null("Fila1"), teclado.get_node_or_null("Fila2"), teclado.get_node_or_null("Fila3")]:
		if not fila:
			continue
		for boton: Node in fila.get_children():
			if boton is Button and boton.text == letra:
				var estilo_usado: StyleBoxFlat = StyleBoxFlat.new()
				estilo_usado.bg_color = Color(0.4, 0.1, 0.1)
				estilo_usado.corner_radius_top_left    = 8
				estilo_usado.corner_radius_top_right   = 8
				estilo_usado.corner_radius_bottom_left  = 8
				estilo_usado.corner_radius_bottom_right = 8
				boton.add_theme_stylebox_override("normal", estilo_usado)
				boton.add_theme_stylebox_override("hover",  estilo_usado)
				boton.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _marcar_letra_correcta(letra: String) -> void:
	if not teclado:
		return
	for fila: Node in [teclado.get_node_or_null("Fila1"), teclado.get_node_or_null("Fila2"), teclado.get_node_or_null("Fila3")]:
		if not fila:
			continue
		for boton: Node in fila.get_children():
			if boton is Button and boton.text == letra:
				var estilo_correcto: StyleBoxFlat = StyleBoxFlat.new()
				estilo_correcto.bg_color = Color(0.1, 0.5, 0.1)
				estilo_correcto.corner_radius_top_left    = 8
				estilo_correcto.corner_radius_top_right   = 8
				estilo_correcto.corner_radius_bottom_left  = 8
				estilo_correcto.corner_radius_bottom_right = 8
				boton.add_theme_stylebox_override("normal", estilo_correcto)
				boton.add_theme_stylebox_override("hover",  estilo_correcto)
				boton.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _mostrar_parte_ahorcado() -> void:
	var indice: int = fallos - 1
	if indice >= 0 and indice < orden_partes.size():
		var parte: Node2D = orden_partes[indice]
		parte.visible = true
		_animar_aparicion(parte, indice)


func _animar_aparicion(parte: Node2D, idx: int) -> void:
	parte.scale = Vector2.ZERO
	var escala_final: Vector2 = escalas_originales[idx]
	var tween: Tween = create_tween()
	tween.tween_property(parte, "scale", escala_final, 0.2).set_ease(Tween.EASE_OUT)

# ------------------------------
# ACTUALIZACIÓN DE UI
# ------------------------------
func _actualizar_display() -> void:
	var display: String = ""
	for letra: String in palabra_secreta:
		if letra in letras_adivinadas:
			display += letra + " "
			_marcar_letra_correcta(letra)
		else:
			display += "_ "
	label_palabra.text = display.strip_edges()
	label_letras_usadas.text = "Errores: " + " ".join(letras_falladas) + " (%d/%d)" % [fallos, orden_partes.size()]


func _actualizar_timer_display() -> void:
	var minutos: int = int(tiempo_restante) / 60
	var segundos: int = int(tiempo_restante) % 60
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]

# ------------------------------
# VICTORIA / DERROTA
# ------------------------------
func _verificar_victoria() -> void:
	var gano: bool = true
	for letra: String in palabra_secreta:
		if letra not in letras_adivinadas:
			gano = false
			break

	if gano:
		juego_activo = false
		for zombie: CharacterBody2D in [zombie1, zombie2, zombie3, zombie4]:
			if zombie:
				zombie.set_activo(false)
		label_palabra.text = "¡ESCAPASTE!"
		if not puerta_instanciada:
			var door_scene: PackedScene = load("res://scenes/game_elements/props/door/door.tscn")
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
# PROCESO
# ------------------------------
func _process(_delta: float) -> void:
	if not juego_activo:
		return

# ------------------------------
# TEMPORIZADORES
# ------------------------------
func _on_tiempo_agotado() -> void:
	_game_over()


func _on_timer_tick() -> void:
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()

# ------------------------------
# GAME OVER
# ------------------------------
func _game_over() -> void:
	juego_activo = false
	for zombie: CharacterBody2D in [zombie1, zombie2, zombie3, zombie4]:
		if zombie:
			zombie.set_activo(false)
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")

# ------------------------------
# DIÁLOGO DE VICTORIA
# ------------------------------
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
