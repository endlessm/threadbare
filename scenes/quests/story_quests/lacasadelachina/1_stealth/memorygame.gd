extends Control

const RONDAS = [4, 6, 8]
const SIMBOLOS = ["A", "B", "C", "D", "E", "F", "G", "H"]
const CARD_SIZE = Vector2(64, 64)

@onready var grid        = get_node("PanelFondo/VBoxContainer/GridContainer")
@onready var lbl_ronda   = get_node("PanelFondo/VBoxContainer/Lblronda")
@onready var lbl_pares   = get_node("PanelFondo/VBoxContainer/LblPares")
@onready var lbl_mensaje = get_node("PanelFondo/VBoxContainer/LblMensaje")

var ronda_actual      : int   = 0
var pares_encontrados : int   = 0
var pares_totales     : int   = 0
var cartas_volteadas  : Array = []
var puede_voltear     : bool  = true

signal minijuego_completado

func _ready():
	visible = false

func iniciar():
	ronda_actual = 0
	visible = true
	_cargar_ronda()

func _cargar_ronda():
	pares_encontrados = 0
	cartas_volteadas.clear()
	puede_voltear     = true
	lbl_mensaje.visible = false

	var num_cartas = RONDAS[ronda_actual]
	pares_totales  = num_cartas / 2

	lbl_ronda.text = "Ronda %d / %d" % [ronda_actual + 1, RONDAS.size()]
	lbl_pares.text = "Pares: 0 / %d" % pares_totales
	grid.columns   = num_cartas / 2

	for c in grid.get_children():
		c.queue_free()

	var mazo = _crear_mazo(pares_totales)
	for simbolo in mazo:
		_crear_carta(simbolo)

func _crear_mazo(num_pares: int) -> Array:
	var mazo = []
	for i in num_pares:
		mazo.append(SIMBOLOS[i])
		mazo.append(SIMBOLOS[i])
	mazo.shuffle()
	return mazo

func _crear_carta(simbolo: String):
	var btn = Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.text = "?"
	btn.set_meta("simbolo", simbolo)
	btn.set_meta("volteada", false)
	btn.pressed.connect(_on_carta_presionada.bind(btn))
	grid.add_child(btn)

func _on_carta_presionada(carta: Button):
	if not puede_voltear:             return
	if carta.get_meta("volteada"):    return
	if cartas_volteadas.size() >= 2:  return

	carta.text = carta.get_meta("simbolo")
	carta.set_meta("volteada", true)
	cartas_volteadas.append(carta)

	if cartas_volteadas.size() == 2:
		puede_voltear = false
		await get_tree().create_timer(0.8).timeout
		_evaluar_par()

func _evaluar_par():
	var c1 : Button = cartas_volteadas[0]
	var c2 : Button = cartas_volteadas[1]

	if c1.get_meta("simbolo") == c2.get_meta("simbolo"):
		c1.modulate = Color(0.5, 1.0, 0.5)
		c2.modulate = Color(0.5, 1.0, 0.5)
		c1.disabled = true
		c2.disabled = true
		pares_encontrados += 1
		lbl_pares.text = "Pares: %d / %d" % [pares_encontrados, pares_totales]

		if pares_encontrados == pares_totales:
			await get_tree().create_timer(0.5).timeout
			_ronda_completada()
	else:
		c1.text = "?"
		c2.text = "?"
		c1.set_meta("volteada", false)
		c2.set_meta("volteada", false)

	cartas_volteadas.clear()
	puede_voltear = true

func _ronda_completada():
	ronda_actual += 1

	if ronda_actual < RONDAS.size():
		lbl_mensaje.text    = "¡Bien! Ronda %d…" % (ronda_actual + 1)
		lbl_mensaje.visible = true
		await get_tree().create_timer(1.5).timeout
		_cargar_ronda()
	else:
		lbl_mensaje.text    = "¡El guardián se aparta!\nEl camino es tuyo."
		lbl_mensaje.visible = true
		await get_tree().create_timer(2.0).timeout
		visible = false
		emit_signal("minijuego_completado")
