extends Node2D

# =========================
# PALABRAS DEL JUEGO
# =========================
const PALABRAS = [
	"TUMBA", "CRUDA", "BRUJA", "HORROR", "PANICO",
	"TERROR", "SOMBRA", "CRIPTA", "CADAVER",
	"ESPECTRO", "TINIEBLA", "FANTASMA",
	"OSCURIDAD", "MALDICION"
]

# =========================
# DIBUJO DEL AHORCADO
# =========================
const AHORCADO = [
	[
		"  +---+  ",
		"  |    |  ",
		"      |  ",
		"      |  ",
		"       |  ",
		"========="
	],
	[
		"  +---+  ",
		"  |   |  ",
		"  O   |  ",
		"      |  ",
		"      |  ",
		"========="
	],
	[
		"  +---+  ",
		"  |   |  ",
		"  O   |  ",
		"  |   |  ",
		"      |  ",
		"========="
	],
	[
		"  +---+  ",
		"  |   |  ",
		"  O   |  ",
		" /|   |  ",
		"      |  ",
		"========="
	],
	[
		"  +---+  ",
		"  |   |  ",
		"  O   |  ",
		" /|\\  |  ",
		"      |  ",
		"========="
	],
	[
		"  +---+  ",
		"  |   |  ",
		"  O   |  ",
		" /|\\  |  ",
		" /    |  ",
		"========="
	],
	[
		"  +---+  ",
		"  |   |  ",
		"  O   |  ",
		" /|\\  |  ",
		" / \\  |  ",
		"========="
	]
]

# =========================
# VARIABLES
# =========================
var palabra_secreta: String = ""
var letras_adivinadas: Array = []
var letras_falladas: Array = []

var fallos := 0
var tiempo_restante := 60
var juego_activo := true

# =========================
# NODOS
# =========================
@onready var label_ahorcado = $CanvasGroup/Panel/LabelAhorcado
@onready var label_palabra = $CanvasGroup/Panel/LabelPalabra
@onready var label_letras_usadas = $CanvasGroup/Panel/LabelLetrasUsadas
@onready var label_mensaje = $CanvasGroup/Panel/LabelMensaje
@onready var label_tiempo = $CanvasGroup/LabelTiempo

@onready var timer_principal = $Timer

@onready var player = $Player
@onready var bestia = $Bestia

# =========================
# INICIO
# =========================
func _ready() -> void:
	randomize()

	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]

	_configurar_fuente()
	_configurar_timers()

	_actualizar_display()
	_actualizar_timer_display()

# =========================
# CONFIGURACIÓN
# =========================
func _configurar_fuente() -> void:
	var fuente = load("res://assets/fonts/JetBrainsMono-Regular.ttf")

	if fuente:
		label_ahorcado.add_theme_font_override("font", fuente)
		label_ahorcado.add_theme_font_size_override("font_size", 16)

	label_ahorcado.autowrap_mode = TextServer.AUTOWRAP_OFF

func _configurar_timers() -> void:
	timer_principal.timeout.connect(_on_tiempo_agotado)

	var tick := Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	tick.one_shot = false

	add_child(tick)

	tick.timeout.connect(_on_timer_tick)

# =========================
# ACTUALIZAR INTERFAZ
# =========================
func _actualizar_display() -> void:
	var texto_palabra := ""

	for letra in palabra_secreta:
		if letra in letras_adivinadas:
			texto_palabra += letra + " "
		else:
			texto_palabra += "_ "

	label_palabra.text = texto_palabra.strip_edges()

	label_letras_usadas.text = "Errores: " + " ".join(letras_falladas)

	if fallos < AHORCADO.size():
		label_ahorcado.text = "\n".join(AHORCADO[fallos])

func _actualizar_timer_display() -> void:
	var minutos = tiempo_restante / 60
	var segundos = tiempo_restante % 60

	label_tiempo.text = "%02d:%02d" % [minutos, segundos]

# =========================
# LETRAS
# =========================
func _on_letra_presionada(letra: String) -> void:

	if letra in letras_adivinadas or letra in letras_falladas:
		return

	if letra in palabra_secreta:
		letras_adivinadas.append(letra)
	else:
		letras_falladas.append(letra)
		fallos += 1

	_actualizar_display()
	_verificar_estado_juego()

# =========================
# VERIFICAR ESTADO
# =========================
func _verificar_estado_juego() -> void:

	var gano := true

	for letra in palabra_secreta:
		if letra not in letras_adivinadas:
			gano = false
			break

	if gano:
		juego_activo = false

		label_mensaje.text = "¡Escapaste! Abriendo puerta final..."

		await get_tree().create_timer(2.0).timeout

		get_tree().change_scene_to_file(
			"res://scenes/Victory.tscn"
		)
		return

	if fallos >= AHORCADO.size() - 1:
		_game_over()

# =========================
# PROCESO PRINCIPAL
# =========================
func _process(delta: float) -> void:

	if not juego_activo:
		return

	var direccion = (
		player.position - bestia.position
	).normalized()

	bestia.position += direccion * 45.0 * delta

	if bestia.position.distance_to(player.position) < 60:
		_game_over()

# =========================
# TEMPORIZADOR
# =========================
func _on_timer_tick() -> void:

	if not juego_activo:
		return

	tiempo_restante -= 1

	_actualizar_timer_display()

	if tiempo_restante <= 0:
		_game_over()

func _on_tiempo_agotado() -> void:
	_game_over()

# =========================
# GAME OVER
# =========================
func _game_over() -> void:

	if not juego_activo:
		return

	juego_activo = false

	get_tree().change_scene_to_file(
		"res://scenes/GameOver.tscn"
	)

# =========================
# ENTRADA DEL TECLADO
# =========================
func _input(event) -> void:

	if not juego_activo:
		return

	if event is InputEventKey and event.pressed:

		var letra = OS.get_keycode_string(
			event.keycode
		).to_upper()

		if letra.length() == 1 and letra >= "A" and letra <= "Z":
			_on_letra_presionada(letra)
