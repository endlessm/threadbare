# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool # Permite que el script se ejecute en el editor.
class_name Guard extends CharacterBody2D # Es la clase principal del guardia, con física 2D.
## Tipo de enemigo que patrulla un camino y da una alarma si detecta al jugador.

## Señal emitida cuando el jugador es detectado. Otros scripts pueden "escuchar" esta alarma.
signal player_detected(player: Player)

# --- Definición de Estados del Guardia (IA) ---

enum State {
	## Caminando a lo largo del camino de patrulla.
	PATROLLING,
	## El jugador está a la vista. El guardia necesita tiempo para confirmar la detección.
	DETECTING,
	## El jugador fue detectado y el guardia está en alerta máxima.
	ALERTED,
	## Perdió de vista al jugador. Va al último punto donde lo vio para investigar.
	INVESTIGATING,
	## Dejó de buscar. Vuelve caminando al punto más cercano de su ruta de patrulla.
	RETURNING,
}

const DEFAULT_SPRITE_FRAMES = preload("uid://ovu5wqo15s5g") # Archivo de animaciones por defecto.

# --- Variables de Configuración (Exports) ---

@export_category("Appearance")
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames # El set de animaciones.
@export_category("Sounds")
## Sonido que se reproduce al entrar en DETECTING o ALERTED.
@export var alerted_sound_stream: AudioStream:
	set = _set_alerted_sound_stream
## Sonido que se reproduce mientras el guardia camina.
@export var footsteps_sound_stream: AudioStream:
	set = _set_footsteps_sound_stream
## Sonido continuo (por ejemplo, el crepitar de una antorcha).
@export var idle_sound_stream: AudioStream:
	set = _set_idle_sound_stream
## Sonido que se repite en ráfagas después de estar en ALERTED.
@export var alert_others_sound_stream: AudioStream:
	set = _set_alert_other_sound_stream

@export_category("Patrol")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Add/Edit Patrol Path") var _edit_patrol_path: Callable = edit_patrol_path # Botón para editar la ruta en el editor.
## El camino que el guardia sigue mientras patrulla.
@export var patrol_path: Path2D:
	set(new_value):
		patrol_path = new_value

## El tiempo que espera en cada punto de la ruta.
@export_range(0, 5, 0.1, "or_greater", "suffix:s") var wait_time: float = 1.0
## La velocidad a la que se mueve el guardia.
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var move_speed: float = 100.0

@export_category("Player Detection")
## Si el jugador es detectado instantáneamente al ser visto.
@export var player_instantly_detected_on_sight: bool = false
## El tiempo que se requiere para detectar al jugador si no es instantáneo.
@export_range(0.1, 5, 0.1, "or_greater", "suffix:s") var time_to_detect_player: float = 1.0
## Escala del área de visión del guardia.
@export_range(0.1, 5, 0.1, "or_greater", "or_less") var detection_area_scale: float = 1.0:
	set(new_value):
		detection_area_scale = new_value
		if detection_area:
			detection_area.scale = Vector2.ONE * detection_area_scale # Ajusta el tamaño del cono de visión.

@export_category("Debug")
## Permite el movimiento en el editor (para probar la ruta sin jugar).
@export var move_while_in_editor: bool = false
## Muestra u oculta la información de depuración (texto con valores de variables).
@export var show_debug_info: bool = false

# --- Variables Internas de la IA ---

## Índice del punto de patrulla anterior.
var previous_patrol_point_idx: int = -1
## Índice del punto de patrulla actual al que se dirige.
var current_patrol_point_idx: int = 0
## Última posición conocida donde se vio al jugador.
var last_seen_position: Vector2
## Una lista de posiciones ("migas de pan") para que el guardia sepa por dónde volver.
var breadcrumbs: Array[Vector2] = []
## El estado actual del guardia (Patrullando, Alerta, etc.). Si cambia, llama a _set_state.
var state: State = State.PATROLLING:
	set = _set_state

## Variable interna para guardar la referencia al jugador que está siendo detectado.
var _player: Player

# --- Referencias a Nodos de la Escena (onready) ---

## El área que define el cono de visión del guardia.
@onready var detection_area: Area2D = %DetectionArea
## Barra que indica qué tan cerca está el jugador de ser detectado (barra de conciencia).
@onready var player_awareness: TextureProgressBar = %PlayerAwareness
## Rayo que se usa para verificar si hay paredes u obstáculos bloqueando la vista.
@onready var sight_ray_cast: RayCast2D = %SightRayCast
## El texto de depuración que muestra información.
@onready var debug_info: Label = %DebugInfo

## Referencia al script que maneja las animaciones de caminar/estar quieto.
@onready
# gdlint:ignore = max-line-length
var character_animation_player_behavior: CharacterAnimationPlayerBehavior = %CharacterAnimationPlayerBehavior

## El script que controla la velocidad y el movimiento real del guardia.
@onready var guard_movement: GuardMovement = %GuardMovement
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer # Para animaciones específicas (ej. alerta).
@onready var _alert_sound: AudioStreamPlayer = %AlertSound
@onready var _foot_sound: AudioStreamPlayer2D = %FootSound
@onready var _fire_sound: AudioStreamPlayer2D = %FireSound
@onready var _torch_hit_sound: AudioStreamPlayer2D = %TorchHitSound


# --- Advertencias y Configuración Inicial ---

# Revisa si las animaciones y configuraciones requeridas existen (solo se usa en el editor).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not sprite_frames:
		warnings.push_back("sprite_frames must be set.")

	# Verifica que las animaciones obligatorias ("alerted", "idle", "walk") estén presentes.
	for required_animation: StringName in [&"alerted", &"idle", &"walk"]:
		if sprite_frames and not sprite_frames.has_animation(required_animation):
			warnings.push_back(
				"sprite_frames is missing the following animation: %s" % required_animation
			)

	return warnings


# Se ejecuta al inicio del juego.
func _ready() -> void:
	if not Engine.is_editor_hint(): # Si estamos jugando:
		# Configura la barra de detección.
		if player_awareness:
			player_awareness.max_value = time_to_detect_player # El máximo es el tiempo que toma detectar.
			player_awareness.value = 0.0 # Empieza vacía.

	_set_sprite_frames(sprite_frames) # Carga las animaciones iniciales.

	if detection_area:
		detection_area.scale = Vector2.ONE * detection_area_scale # Ajusta el cono de visión.

	# Si hay un camino de patrulla, coloca al guardia en el punto de inicio.
	if patrol_path:
		global_position = _patrol_point_position(0)

	# Conecta los eventos de movimiento del script GuardMovement:
	guard_movement.destination_reached.connect(self._on_destination_reached) # Cuando llega al destino.
	guard_movement.still_time_finished.connect(self._on_still_time_finished) # Cuando termina de esperar.
	guard_movement.path_blocked.connect(self._on_path_blocked) # Cuando un obstáculo bloquea el camino.


# --- Lógica de Bucle Principal ---

# Se ejecuta CADA CUADRO del juego.
func _process(delta: float) -> void:
	_update_debug_info() # Actualiza el texto de depuración (si está visible).

	# Si estamos en el editor y el movimiento está desactivado, salimos.
	if Engine.is_editor_hint() and not move_while_in_editor:
		return

	_process_state() # Decide qué movimiento hacer según el estado actual.
	guard_movement.move() # Ejecuta el movimiento físico del guardia.

	if state != State.ALERTED: # Si no está ya alertado:
		_update_player_awareness(delta) # Actualiza la barra de detección.

	_update_animation() # Decide si animar (caminando) o no (quieto).


## Actualiza el comportamiento de movimiento del guardia basándose en su estado.
func _process_state() -> void:
	match state:
		State.PATROLLING: # Estado Patrullando:
			if patrol_path:
				var target_position: Vector2 = _patrol_point_position(current_patrol_point_idx)
				guard_movement.set_destination(target_position) # Va al siguiente punto de la ruta.
			else:
				guard_movement.stop_moving()
		State.INVESTIGATING: # Estado Investigando:
			guard_movement.set_destination(last_seen_position) # Va al último lugar donde vio al jugador.
		State.RETURNING: # Estado Regresando a la ruta:
			if not breadcrumbs.is_empty():
				var target_position: Vector2 = breadcrumbs.back() # Va a la última "miga de pan".
				guard_movement.set_destination(target_position)
			else:
				state = State.PATROLLING # Si ya llegó a todas las migas, vuelve a patrullar.
		State.ALERTED: # Estado Alertado:
			guard_movement.stop_moving() # Se queda completamente quieto.


## Lógica para llenar o vaciar la barra de conciencia del jugador.
func _update_player_awareness(delta: float) -> void:
	# Revisa si el jugador está presente Y si no hay una pared bloqueando la vista.
	var player_in_sight := _player and not _is_sight_to_point_blocked(_player.global_position)

	# Mueve el valor de la barra gradualmente hacia el máximo (si lo ve) o hacia cero (si no lo ve).
	player_awareness.value = move_toward(
		player_awareness.value, player_awareness.max_value if player_in_sight else 0.0, delta
	)
	player_awareness.visible = player_awareness.ratio > 0.0 # Muestra la barra solo si hay progreso.
	player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0) # Hace la barra más visible a medida que se llena.

	if player_awareness.ratio >= 1.0: # Si la barra está llena:
		state = State.ALERTED # ¡Alarma!
		player_detected.emit(_player) # Emite la señal para que el juego sepa que el jugador fue detectado.


func _update_animation() -> void:
	if state == State.ALERTED: # Si está alertado, la animación es fija (la de alerta).
		return
	if velocity.is_zero_approx(): # Si está quieto:
		animation_player.play(&"idle")
	else: # Si se está moviendo:
		animation_player.play(&"walk")
		
# --- Funciones de Debug (Ayuda para desarrolladores) ---

## Actualiza el texto de depuración con el estado y las variables internas.
func _update_debug_info() -> void:
	debug_info.visible = show_debug_info
	if not debug_info.visible:
		return
	debug_info.text = ""
	debug_property("position")
	debug_value("state", State.keys()[state])
	debug_property("previous_patrol_point_idx")
	debug_property("current_patrol_point_idx")
	debug_value("time left", "%.2f" % guard_movement.still_time_left_in_seconds)
	debug_value("target point", guard_movement.destination)


# Muestra el nombre y valor de una propiedad.
func debug_property(property_name: String) -> void:
	debug_value(property_name, get(property_name))


# Muestra el nombre y valor de una variable.
func debug_value(value_name: String, value: Variant) -> void:
	debug_info.text += "%s: %s\n" % [value_name, value]


# --- Eventos de Movimiento (GuardMovement) ---

## Lo que sucede cuando el guardia llegó a su destino.
func _on_destination_reached() -> void:
	match state:
		State.PATROLLING:
			guard_movement.wait_seconds(wait_time) # Espera el tiempo configurado.
			_advance_target_patrol_point() # Calcula el siguiente punto de la ruta.
		State.INVESTIGATING:
			guard_movement.wait_seconds(wait_time) # Espera un tiempo después de investigar.
		State.RETURNING:
			breadcrumbs.pop_back() # Ya llegó a la miga de pan, la quita.


## Lo que sucede cuando el guardia termina de esperar.
func _on_still_time_finished() -> void:
	match state:
		State.INVESTIGATING:
			state = State.RETURNING # Si terminó de investigar, ahora tiene que regresar a la ruta.


## Lo que sucede si el guardia se queda atascado por un obstáculo.
func _on_path_blocked() -> void:
	match state:
		State.PATROLLING:
			guard_movement.wait_seconds(wait_time) # Espera un tiempo.
			# Si se bloquea, invierte la dirección de patrullaje.
			if previous_patrol_point_idx > -1:
				var new_patrol_point: int = previous_patrol_point_idx
				previous_patrol_point_idx = current_patrol_point_idx
				current_patrol_point_idx = new_patrol_point
		State.INVESTIGATING:
			state = State.RETURNING # Si se atasca investigando, empieza a regresar.
		State.RETURNING:
			if not breadcrumbs.is_empty():
				breadcrumbs.pop_back() # Si se atasca regresando, descarta esa posición.


# --- Lógica de Cambio de Estado y Patrullaje ---

# Función que se ejecuta cada vez que el estado cambia (el "setter" de la variable 'state').
func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		State.DETECTING:
			if not _alert_sound.playing:
				_alert_sound.play() # Empieza a sonar el sonido de alerta.
		State.ALERTED:
			character_animation_player_behavior.process_mode = Node.PROCESS_MODE_DISABLED # Congela las animaciones normales.
			if not _alert_sound.playing:
				_alert_sound.play()
			animation_player.play(&"alerted") # Pone la animación de alerta.
			player_awareness.ratio = 1.0 # Llena la barra de detección.
			player_awareness.tint_progress = Color.RED
			player_awareness.visible = true
		State.INVESTIGATING:
			guard_movement.start_moving_now() # Empieza a moverse de inmediato.
			breadcrumbs.push_back(global_position) # Guarda la posición actual como punto de retorno.


## Calcula el siguiente punto de la ruta de patrulla.
func _advance_target_patrol_point() -> void:
	if not patrol_path or not patrol_path.curve or _amount_of_patrol_points() < 2:
		return

	var new_patrol_point_idx: int

	if _is_patrol_path_closed():
		# Si la ruta es cerrada (ciclo), avanza al siguiente punto cíclicamente.
		new_patrol_point_idx = (current_patrol_point_idx + 1) % (_amount_of_patrol_points() - 1)
	else:
		# Si la ruta es abierta, va y viene (ping-pong).
		var at_last_point: bool = current_patrol_point_idx == (_amount_of_patrol_points() - 1)
		var at_first_point: bool = current_patrol_point_idx == 0
		var going_backwards_in_path: bool = previous_patrol_point_idx > current_patrol_point_idx
		
		if at_last_point:
			new_patrol_point_idx = current_patrol_point_idx - 1
		elif at_first_point:
			new_patrol_point_idx = current_patrol_point_idx + 1
		elif going_backwards_in_path:
			new_patrol_point_idx = current_patrol_point_idx - 1
		else:
			new_patrol_point_idx = current_patrol_point_idx + 1

	previous_patrol_point_idx = current_patrol_point_idx
	current_patrol_point_idx = new_patrol_point_idx


## Revisa si hay una pared u obstáculo bloqueando la línea de visión al punto.
func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding() # Devuelve verdadero si choca con algo.


## Convierte el índice de un punto de patrulla a una posición en el mundo.
func _patrol_point_position(point_idx: int) -> Vector2:
	var local_point_position: Vector2 = patrol_path.curve.get_point_position(point_idx)
	return patrol_path.to_global(local_point_position)


## Devuelve la cantidad de puntos en la ruta.
func _amount_of_patrol_points() -> int:
	return patrol_path.curve.point_count


## Devuelve verdadero si la ruta es un ciclo (punto final = punto inicial).
func _is_patrol_path_closed() -> bool:
	if not patrol_path:
		return false

	var curve: Curve2D = patrol_path.curve
	if curve.point_count < 3:
		return false

	var first_point_position: Vector2 = curve.get_point_position(0)
	var last_point_position: Vector2 = curve.get_point_position(curve.point_count - 1)

	return first_point_position.is_equal_approx(last_point_position)


# --- Lógica de Reset y Editor ---

## Reinicia al guardia a su posición y valores iniciales.
func _reset() -> void:
	previous_patrol_point_idx = -1
	current_patrol_point_idx = 0
	velocity = Vector2.ZERO
	if patrol_path:
		global_position = _patrol_point_position(0) # Lo coloca en el punto de inicio.


## Se ejecuta antes de guardar para asegurar que el guardia inicie en el punto correcto.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_reset()


static func _editor_interface() -> Object:
	# Este es un método para obtener la interfaz del editor de Godot (código técnico).
	return Engine.get_singleton("EditorInterface")


## Función para el botón del editor que edita o crea la ruta de patrulla.
func edit_patrol_path() -> void:
	if not Engine.is_editor_hint():
		return

	var editor_interface := _editor_interface()

	if patrol_path:
		editor_interface.edit_node.call_deferred(patrol_path) # Edita la ruta existente.
	else:
		# Crea una nueva ruta de patrulla si no existe.
		var new_patrol_path: Path2D = Path2D.new()
		patrol_path = new_patrol_path
		get_parent().add_child(patrol_path)
		patrol_path.owner = owner
		patrol_path.global_position = global_position
		var patrol_path_curve: Curve2D = Curve2D.new()
		patrol_path.curve = patrol_path_curve
		patrol_path.name = "%s-PatrolPath" % name
		patrol_path_curve.add_point(Vector2.ZERO)
		patrol_path_curve.add_point(Vector2.RIGHT * 150.0)
		editor_interface.edit_node.call_deferred(patrol_path) # Abre la nueva ruta para editarla.


# --- Setters de Variables (Configuración de Animaciones y Sonidos) ---

# Función que se llama cuando se cambia el 'sprite_frames'.
func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	animated_sprite_2d.sprite_frames = sprite_frames
	update_configuration_warnings()


# Función que se llama cuando se cambia el 'alerted_sound_stream'.
func _set_alerted_sound_stream(new_value: AudioStream) -> void:
	alerted_sound_stream = new_value
	if not is_node_ready():
		await ready
	_alert_sound.stream = new_value


# Función que se llama cuando se cambia el 'footsteps_sound_stream'.
func _set_footsteps_sound_stream(new_value: AudioStream) -> void:
	footsteps_sound_stream = new_value
	if not is_node_ready():
		await ready
	_foot_sound.stream = new_value


# Función que se llama cuando se cambia el 'idle_sound_stream'.
func _set_idle_sound_stream(new_value: AudioStream) -> void:
	idle_sound_stream = new_value
	if not is_node_ready():
		await ready
	_fire_sound.stream = new_value


# Función que se llama cuando se cambia el 'alert_others_sound_stream'.
func _set_alert_other_sound_stream(new_value: AudioStream) -> void:
	alert_others_sound_stream = new_value
	if not is_node_ready():
		await ready
	_torch_hit_sound.stream = new_value


# --- Eventos de Colisión (Detección) ---

## Se activa si el jugador entra en un área de detección instantánea.
func _on_instant_detection_area_body_entered(body: Node2D) -> void:
	if not body is Player: # Ignora si no es el jugador.
		return
	state = State.ALERTED # Alerta inmediata.
	player_detected.emit(body as Player) # Activa la alarma.


## Se activa si el jugador entra en el cono de visión normal.
func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_player = body as Player
	if _is_sight_to_point_blocked(body.global_position): # Si hay pared, ignora.
		return
	if player_instantly_detected_on_sight:
		state = State.ALERTED
		player_detected.emit(_player)
	else:
		state = State.DETECTING # Empieza el proceso de llenado de la barra.


## Se activa si el jugador sale del cono de visión.
func _on_detection_area_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_player = null
	last_seen_position = body.global_position # Guarda dónde se escondió.
	if state == State.DETECTING:
		guard_movement.stop_moving()
		state = State.INVESTIGATING # Deja de detectar y empieza a investigar.
