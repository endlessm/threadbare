extends Control

const RONDAS = [4, 6, 8]
const SIMBOLOS = [
	"res://scenes/quests/story_quests/lacasadelachina/1_stealth/stealth_components/memory_cards/rana.png",
	"res://scenes/quests/story_quests/lacasadelachina/1_stealth/stealth_components/memory_cards/sol.jpg",
	"res://scenes/quests/story_quests/lacasadelachina/1_stealth/stealth_components/memory_cards/serpiente.png",
	"res://scenes/quests/story_quests/lacasadelachina/1_stealth/stealth_components/memory_cards/mariposa.png",
	"res://scenes/quests/story_quests/lacasadelachina/1_stealth/stealth_components/memory_cards/condor.png",
]

const CARD_BACK = "res://scenes/quests/story_quests/lacasadelachina/1_stealth/stealth_components/memory_cards/card_back.png"

@onready var panel       = get_node("PanelFondo")
@onready var lbl_ronda   = get_node("PanelFondo/VBoxContainer/Lblronda")
@onready var lbl_pares   = get_node("PanelFondo/VBoxContainer/LblPares")
@onready var lbl_mensaje = get_node("PanelFondo/VBoxContainer/LblMensaje")

@onready var bloqueo1 = get_node("/root/LacasadelachinaStealth/TileMapLayers/bloqueo")
@onready var bloqueo2 = get_node("/root/LacasadelachinaStealth/TileMapLayers/bloqueo2")
@onready var bloqueo3 = get_node("/root/LacasadelachinaStealth/TileMapLayers/bloqueo3")

var guardia1 : Node = null
var guardia2 : Node = null
var guardia3 : Node = null

var ronda_actual      : int   = 0
var pares_encontrados : int   = 0
var pares_totales     : int   = 0
var cartas_volteadas  : Array = []
var puede_voltear     : bool  = true
var cartas_en_juego   : Array = []

signal minijuego_completado
signal ronda_completada_signal(ronda: int)

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func iniciar():
	if visible:
		return

	guardia1 = get_node_or_null("/root/LacasadelachinaStealth/EnemyGuards/Guard1-GoingBackAndForth")
	guardia2 = get_node_or_null("/root/LacasadelachinaStealth/EnemyGuards/Guard2-GoingBackAndForth2")
	guardia3 = get_node_or_null("/root/LacasadelachinaStealth/EnemyGuards/Guard3-GoingBackAndForth3")

	visible = true
	get_tree().paused = true
	_cargar_ronda()

func _cargar_ronda():
	pares_encontrados = 0
	cartas_volteadas.clear()
	puede_voltear = true
	lbl_mensaje.visible = false

	for carta in cartas_en_juego:
		carta.queue_free()
	cartas_en_juego.clear()

	var num_cartas = RONDAS[ronda_actual]
	pares_totales  = num_cartas / 2

	lbl_ronda.text = "Ronda %d / %d" % [ronda_actual + 1, RONDAS.size()]
	lbl_pares.text = "Pares: 0 / %d" % pares_totales

	var mazo = _crear_mazo(pares_totales)
	var col  = 0
	var fila = 0
	for simbolo in mazo:
		_crear_carta(simbolo, col, fila)
		col += 1
		if col >= pares_totales:
			col = 0
			fila += 1

func _crear_mazo(num_pares: int) -> Array:
	var mazo = []
	for i in num_pares:
		mazo.append(SIMBOLOS[i])
		mazo.append(SIMBOLOS[i])
	mazo.shuffle()
	return mazo

func _crear_carta(simbolo_path: String, col: int, fila: int):
	var btn = TextureButton.new()
	btn.size = Vector2(128, 128)
	btn.custom_minimum_size = Vector2(128, 128)
	btn.position = Vector2(20 + col * 140, 80 + fila * 140)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.texture_normal = load(CARD_BACK) as Texture2D
	btn.set_meta("simbolo", simbolo_path)
	btn.set_meta("volteada", false)
	btn.pressed.connect(_on_carta_presionada.bind(btn))
	panel.add_child(btn)
	cartas_en_juego.append(btn)

func _on_carta_presionada(carta: TextureButton):
	if not puede_voltear:            return
	if carta.get_meta("volteada"):   return
	if cartas_volteadas.size() >= 2: return

	carta.texture_normal = load(carta.get_meta("simbolo")) as Texture2D
	carta.set_meta("volteada", true)
	cartas_volteadas.append(carta)

	if cartas_volteadas.size() == 2:
		puede_voltear = false
		await get_tree().create_timer(0.8).timeout
		_evaluar_par()

func _evaluar_par():
	var c1 : TextureButton = cartas_volteadas[0]
	var c2 : TextureButton = cartas_volteadas[1]

	if c1.get_meta("simbolo") == c2.get_meta("simbolo"):
		c1.modulate = Color(0.637, 0.274, 1.0, 1.0)
		c2.modulate = Color(0.639, 0.275, 1.0, 1.0)
		c1.disabled = true
		c2.disabled = true
		pares_encontrados += 1
		lbl_pares.text = "Pares: %d / %d" % [pares_encontrados, pares_totales]

		if pares_encontrados == pares_totales:
			await get_tree().create_timer(0.5).timeout
			_ronda_completada()
	else:
		c1.texture_normal = load(CARD_BACK) as Texture2D
		c2.texture_normal = load(CARD_BACK) as Texture2D
		c1.set_meta("volteada", false)
		c2.set_meta("volteada", false)

	cartas_volteadas.clear()
	puede_voltear = true

func _ronda_completada():
	if ronda_actual == 0:
		bloqueo1.queue_free()
		if is_instance_valid(guardia1):
			guardia1.queue_free()
	elif ronda_actual == 1:
		bloqueo2.queue_free()
		if is_instance_valid(guardia2):
			guardia2.queue_free()
	elif ronda_actual == 2:
		bloqueo3.queue_free()
		if is_instance_valid(guardia3):
			guardia3.queue_free()

	ronda_actual += 1

	if ronda_actual < RONDAS.size():
		lbl_mensaje.text = "¡Bien! Avanza al siguiente guardia..."
		lbl_mensaje.visible = true
		await get_tree().create_timer(1.5).timeout
		visible = false
		get_tree().paused = false
		emit_signal("ronda_completada_signal", ronda_actual)  # ← después del unpause
	else:
		lbl_mensaje.text = "¡El camino es tuyo!"
		lbl_mensaje.visible = true
		await get_tree().create_timer(2.0).timeout
		visible = false
		get_tree().paused = false
		emit_signal("minijuego_completado")
