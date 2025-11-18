# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool # Le dice a Godot que este script puede funcionar dentro del editor.
class_name Player # Le da un nombre especial a este script (Player) para usarlo fácilmente.
extends CharacterBody2D # Es un personaje que se mueve y colisiona en un mundo 2D.

signal mode_changed(mode: Mode) # Una 'señal' que se dispara cuando el modo del jugador cambia.

# --- Definición de Modos de Juego ---

## Define los diferentes estados o "modos" en que puede estar el jugador.
enum Mode {
	## El jugador puede explorar, interactuar (hablar, etc.), pero no pelear.
	COZY, 
	## El jugador está en combate y puede usar acciones de ataque.
	FIGHTING,
	## El jugador está usando el gancho para moverse.
	HOOKING,
	## El jugador ha sido derrotado y no puede ser controlado.
	DEFEATED,
}

# --- Constantes de Animación ---

## Animaciones OBLIGATORIAS: deben existir en el 'sprite_frames' con el número de cuadros indicado.
const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10, # Animación quieto (10 cuadros)
	&"walk": 6, # Animación caminando (6 cuadros)
	&"attack_01": 4, # Animación de ataque 1 (4 cuadros)
	&"attack_02": 4, # Animación de ataque 2 (4 cuadros)
	&"defeated": 11, # Animación de derrota (11 cuadros)
}

## Animaciones OPCIONALES: si existen, deben tener el número de cuadros indicado.
const OPTIONAL_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"run": 6, # Animación corriendo (6 cuadros)
}

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp") # El archivo de animaciones predeterminado.

# --- Variables que se pueden configurar en el Editor (Exports) ---

## El nombre del personaje, usado en los diálogos.
@export var player_name: String = "Player Name"

## El modo actual del jugador. Si cambia, llama a la función _set_mode.
@export var mode: Mode = Mode.COZY:
	set = _set_mode

## Velocidad normal al caminar. Se ajusta de 10 a 100000.
@export_range(10, 100000, 10) var walk_speed: float = 300.0

## Velocidad al correr.
@export_range(10, 100000, 10) var run_speed: float = 500.0

## Velocidad lenta al apuntar el gancho.
@export_range(10, 100000, 10) var aiming_speed: float = 100.0

## Qué tan rápido el personaje frena. Un valor alto frena de golpe.
@export_range(10, 100000, 10) var stopping_step: float = 1500.0

## Qué tan rápido el personaje empieza a moverse.
@export_range(10, 100000, 10) var moving_step: float = 4000.0

## El archivo que contiene todas las animaciones del jugador. Si cambia, llama a _set_sprite_frames.
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_group("Sounds") # Crea un grupo para sonidos en el inspector de Godot.
## El archivo de audio para el sonido de pasos. Si cambia, llama a _set_walk_sound_stream.
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"):
	set = _set_walk_sound_stream

# --- Variables Internas y Referencias a Nodos ---

var input_vector: Vector2 # Almacena la dirección y velocidad que el jugador quiere moverse.

# Variables que "encuentran" otros objetos (nodos) del juego cuando la escena está lista:
@onready var player_interaction: PlayerInteraction = %PlayerInteraction # Lógica para hablar/abrir.
@onready var player_fighting: Node2D = %PlayerFighting # Lógica para atacar.
@onready var player_hook: PlayerHook = %PlayerHook # Lógica para el gancho.
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite # El que muestra las animaciones.
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound # El que reproduce el sonido de caminar.


# --- Lógica de Cambio de Modo ---

# Función que cambia el modo actual del jugador y activa/desactiva las funciones necesarias.
func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode # Guarda el modo anterior.
	mode = new_mode # Establece el nuevo modo.
	
	if not is_node_ready(): return # Si no está listo, sale.
		
	# Revisa el nuevo modo y solo activa el código que debe ejecutarse en ese momento:
	match mode:
		Mode.COZY: # Modo Tranquilo/Interacción
			_toggle_player_behavior(player_interaction, true)
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, false)
		Mode.FIGHTING: # Modo Pelea
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, true)
			_toggle_player_behavior(player_hook, false)
		Mode.HOOKING: # Modo Gancho
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, true)
		Mode.DEFEATED: # Modo Derrotado (o Inactivo)
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, false)
			
	# Si el modo cambió, avisa a otros scripts.
	if mode != previous_mode:
		mode_changed.emit(mode)


# --- Lógica de Animaciones (Sprite) ---

# Función para cargar un nuevo set de animaciones para el jugador.
func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames # Guarda la nueva configuración.
	if not is_node_ready(): return
	
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME # Si es nulo, usa el por defecto.
	
	player_sprite.sprite_frames = new_sprite_frames # Aplica las nuevas animaciones.
	update_configuration_warnings() # Revisa si hay advertencias.


# --- Función Auxiliar para Activar/Desactivar Comportamientos ---

# Enciende o apaga un nodo de comportamiento (como PlayerFighting o PlayerHook).
func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	behavior_node.visible = is_active # Lo muestra u oculta.
	# Activa o desactiva su lógica (proceso) para ahorrar recursos.
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)


# --- Revisión de Animaciones (Solo se usa en el editor) ---

# Revisa si las animaciones y la cantidad de cuadros son correctas para mostrar advertencias al desarrollador.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray # Lista para guardar los mensajes de error.
	
	# Verifica que las animaciones obligatorias existan.
	for animation: StringName in REQUIRED_ANIMATION_FRAMES:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)

	# Revisa que el número de cuadros (frames) sea el correcto.
	var animations: Dictionary[StringName, int] = REQUIRED_ANIMATION_FRAMES.merged(
		OPTIONAL_ANIMATION_FRAMES
	)
	for animation: StringName in animations:
		if not sprite_frames.has_animation(animation):
			continue
		
		var count := sprite_frames.get_frame_count(animation)
		var expected_count := animations[animation]

		if count != expected_count:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [animation, count, expected_count]
				)
			)

	return warnings


# --- Inicio y Procesamiento de la Entrada del Jugador ---

# Se ejecuta al inicio del juego.
func _ready() -> void:
	_set_mode(mode) # Configura el modo inicial.
	_set_sprite_frames(sprite_frames) # Carga las animaciones iniciales.


# Se activa cada vez que hay una entrada (tecla, joystick, etc.) que aún no ha sido usada.
func _unhandled_input(_event: InputEvent) -> void:
	# Recoge la dirección del movimiento deseado.
	var axis: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	var speed: float # Velocidad que se usará.
	
	# Determina la velocidad basándose en lo que el jugador hace:
	if player_hook.is_throwing_or_aiming(): # Si apunta el gancho.
		speed = aiming_speed
	elif Input.is_action_pressed(&"running"): # Si presiona correr.
		speed = run_speed
	else: # Por defecto.
		speed = walk_speed

	# Calcula el vector de movimiento (dirección por velocidad).
	input_vector = axis * speed


## Descripción: Devuelve si el jugador está corriendo.

# --- Movimiento y Control de Velocidad ---

# Función que verifica si el jugador se está moviendo a velocidad de "correr".
func is_running() -> bool:
	# Compara la velocidad actual con la velocidad de caminar, compensando pequeños errores de cálculo.
	return input_vector.length_squared() > (walk_speed * walk_speed) + 1.0


# Se ejecuta CADA CUADRO del juego para aplicar el movimiento.
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return # Sale si es solo el editor.

	# Si el gancho lo está jalando, salimos (el gancho maneja el movimiento).
	if player_hook.pulling:
		return

	# Si está interactuando o derrotado, la velocidad es cero (se detiene).
	if player_interaction.is_interacting or mode == Mode.DEFEATED:
		velocity = Vector2.ZERO
		return

	# Decide si está frenando (usa 'stopping_step') o acelerando (usa 'moving_step').
	var step := (
		stopping_step if velocity.length_squared() > input_vector.length_squared() else moving_step
	)
	
	# Mueve gradualmente la velocidad actual hacia la deseada para crear un movimiento suave.
	velocity = velocity.move_toward(input_vector, step * delta)

	# Mueve al personaje en el mundo y resuelve las colisiones.
	move_and_slide()


# --- Teletransportación ---

# Función para mover al jugador instantáneamente a un lugar, con opciones de cámara.
func teleport_to(
	tele_position: Vector2,
	smooth_camera: bool = false,
	look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED
) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d() # Obtiene la cámara.

	if is_instance_valid(camera): # Si hay cámara:
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera # Configura si debe ser suave.
		global_position = tele_position # Mueve al jugador.
		%PlayerSprite.look_at_side(look_side) # Cambia la dirección visual.
		await get_tree().process_frame # Espera un cuadro.
		camera.position_smoothing_enabled = smoothing_was_enabled # Restaura el suavizado.
	else:
		global_position = tele_position # Si no hay cámara, solo mueve al jugador.


# --- Configuración de Sonido ---

# Función para cambiar el audio que se usa para el sonido de pasos.
func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value
	if not is_node_ready():
		await ready # Espera a que esté listo si es necesario.
	_walk_sound.stream = walk_sound_stream # Aplica el nuevo sonido.


# --- Lógica de Derrota ---

# Inicia la secuencia de derrota del jugador.
func defeat(falling: bool = false) -> void:
	if mode == Player.Mode.DEFEATED: return # Si ya está derrotado, no hace nada.

	mode = Player.Mode.DEFEATED # Cambia el estado a derrotado.

	if falling: # Si se indica que debe "caer":
		var tween := create_tween()
		# Encoge al personaje a escala cero en 2 segundos.
		tween.tween_property(self, "scale", Vector2.ZERO, 2.0)

	await get_tree().create_timer(2.0).timeout # Espera 2 segundos.
	# Recarga la escena actual con un efecto de desvanecimiento (FADE).
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
