extends Node

@export var zone_nodes: Array[NodePath] = []        # Path a cada AllHooked (3 elementos)
@export var timer_node: NodePath                   # Path al Timer
@export var timer_seconds: int = 180               # 3 minutos por defecto
@export var timer_label: NodePath = NodePath("")   # opcional, Label para mostrar tiempo
@export var auto_start_on_first_zone: bool = true  # si true, timer arranca la 1ª vez que se entra a una zona
@export var final_collectible: NodePath      # path al CollectibleItem que se revelará
@export var final_dialogue: DialogueResource # DialogueResource opcional con el texto de Charlie
@export var start_on_ready: bool = true
@export var player_node: NodePath = NodePath("")

signal puzzle_succeeded
signal puzzle_failed

var _zones_done: Dictionary = {}   # key: Node -> bool
var _timer: Timer = null
var _running: bool = false

func _ready() -> void:
	# Conectar zonas
	for p in zone_nodes:
		var n := get_node_or_null(p)
		if n:
			# conectar usando Callable bind (evita incompatibilidades con overloads)
			var cb := Callable(self, "_on_zone_all_hooked").bind(n)
			if not n.is_connected("all_hooked", cb):
				n.connect("all_hooked", cb)
			_zones_done[n] = false

	# Timer
	_timer = get_node_or_null(timer_node) as Timer
	if _timer:
		_timer.wait_time = timer_seconds
		_timer.one_shot = true
		var cbt := Callable(self, "_on_timer_timeout")
		if not _timer.is_connected("timeout", cbt):
			_timer.connect("timeout", cbt)

	# Label (opcional)
	if timer_label != NodePath(""):
		var lab := get_node_or_null(timer_label) as Label
		if lab:
			_update_timer_label(timer_seconds)
	if start_on_ready:
		start_puzzle()


func start_puzzle(_body: Node = null) -> void:
	# Se puede conectar a body_entered (recibirá body), por eso acepta arg opcional
	if _running:
		return
	_running = true
	# reset zona
	for k in _zones_done.keys():
		_zones_done[k] = false
	if _timer:
		_timer.start(timer_seconds)
	# si hay label, actualizar en cada frame
	set_process(true)

func _on_zone_all_hooked(zone_node: Node) -> void:
	if not _running:
		# si auto_start habilitado, arrancar la 1ª vez que se detecta la zona
		if auto_start_on_first_zone:
			start_puzzle()
		else:
			return

	_zones_done[zone_node] = true
	_check_success_condition()

func _check_success_condition() -> void:
	# éxito si todas las zonas están en true
	for v in _zones_done.values():
		if not v:
			return
	# todas completas
	_success()

func _success() -> void:
	_running = false
	if _timer:
		_timer.stop()

	# Mostrar diálogo final (Charlie) si existe
	if final_dialogue:
		DialogueManager.show_dialogue_balloon(final_dialogue, "", [])
		await DialogueManager.dialogue_ended

	# Cambiar al jugador a modo COZY (antes de revelar el collectible)
	_set_player_mode_to_cozy()

	# Revelar el collectible final (si existe)
	if final_collectible != NodePath(""):
		var col := get_node_or_null(final_collectible)
		if col and col.has_method("reveal"):
			col.reveal()

	# Emitir señal principal
	emit_signal("puzzle_succeeded")

	# Actualizar label final por si está visible
	if timer_label != NodePath(""):
		var lab := get_node_or_null(timer_label) as Label
		if lab:
			lab.text = "¡Completado!"

	set_process(false)

func _on_timer_timeout() -> void:
	_running = false
	emit_signal("puzzle_failed")

	# resetear zonas y estados para poder reiniciar el minijuego
	_reset_zones_state()

	# ocultar el collectible final para el nuevo intento si existe
	if final_collectible != NodePath(""):
		var col := get_node_or_null(final_collectible)
		if col:
			# CollectibleItem tiene la propiedad 'revealed'
			col.revealed = false


	# feedback UI
	if timer_label != NodePath(""):
		var lab := get_node_or_null(timer_label) as Label
		if lab:
			lab.text = "Tiempo agotado. Reiniciando..."

	# breve pausa antes de reiniciar para que el jugador vea el mensaje
	await get_tree().create_timer(0.8).timeout

	# reiniciar el minijuego desde cero
	get_tree().reload_current_scene()
	
func _reset_zones_state() -> void:
	# Limpia el estado interno de cada AllHooked llamando a released(area)
	for p in zone_nodes:
		var n := get_node_or_null(p)
		if not n:
			continue

		var areas: Array = []

		# use get() para evitar llamar a APIs que no existen
		if n.has_method("get"):
			var temp = n.get("areas_to_hook")
			if temp is Array:
				areas = temp
		else:
			if n.has("areas_to_hook"):
				var temp = n.get("areas_to_hook")
				if temp is Array:
					areas = temp

		# Ahora es seguro recorrer
		for area in areas:
			if area and n.has_method("released"):
				n.released(area)

		# reset tracking local siempre
		_zones_done[n] = false



func _process(delta: float) -> void:
	if _running and _timer:
		_update_timer_label(ceil(_timer.time_left))

func _update_timer_label(seconds_left: int) -> void:
	var lab := get_node_or_null(timer_label) as Label
	if not lab:
		return
	var m := int(seconds_left / 60)
	var s := int(seconds_left % 60)
	lab.text = _zero(m) + ":" + _zero(s)

func _set_player_mode_to_cozy() -> void:
	var player := _get_player_node()
	if not player:
		print("PuzzleManager: no se encontró Player para cambiar modo.")
		return

	player.mode = 0   # COZY
	print("PuzzleManager: player.mode = COZY (0)")

# helper: obtiene el nodo player (por player_node exportado o por grupo 'player')
func _get_player_node() -> Node:
	if player_node != NodePath("") and get_node_or_null(player_node):
		return get_node_or_null(player_node)
	var group_nodes := get_tree().get_nodes_in_group("player")
	if group_nodes.size() > 0:
		return group_nodes[0]
	return null

func _zero(n: int) -> String:
	if n >= 10:
		return str(n)
	return "0" + str(n)
