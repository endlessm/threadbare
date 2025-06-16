# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

@tool # Indica que este script puede ejecutarse en el editor de Godot.
class_name Player # Define el nombre de la clase como Player.
extends CharacterBody2D # Hereda de CharacterBody2D, un nodo para personajes con colisiones y movimiento.

signal mode_changed(mode: Mode) # Define una señal que se emite cuando cambia el modo del jugador.

## Controls how the player can interact with the world around them.
enum Mode { # Define un enum llamado Mode para los diferentes modos del jugador.
    ## Player can explore the world, interact with items and NPCs, but is not
    ## engaged in combat. Combat actions are not available in this mode.
    COZY, # Modo "acogedor" - el jugador puede explorar e               interactuar.
    ## Player is engaged in combat. Player can use combat actions.
    FIGHTING, # Modo de combate - el jugador puede usar acciones de combate.
    ## Player can't be controlled anymore.
    DEFEATED, # Modo derrotado - el jugador no puede ser controlado.
}

const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = { # Define un diccionario con la cantidad de frames requeridos para cada animación.
    &"idle": 10, # La animación "idle" debe tener 10 frames.
    &"walk": 6, # La animación "walk" debe tener 6 frames.
    &"attack_01": 4, # La animación "attack_01" debe tener 4 frames.
    &"defeated": 11, # La animación "defeated" debe tener 11 frames.
}
const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp") # Carga un recurso SpriteFrames por defecto.

## The character's name. This is used to highlight when the player's character
## is speaking during dialogue.
@export var player_name: String = "Player Name" # Define una variable exportada para el nombre del jugador.

## Controls how the player can interact with the world around them.
@export var mode: Mode = Mode.COZY: # Define una variable exportada para el modo del jugador, con el modo COZY por defecto.
    set = _set_mode # Define una función setter para la variable mode.
@export_range(10, 100000, 10) var walk_speed: float = 300.0 # Define una variable exportada para la velocidad al caminar.
@export_range(10, 100000, 10) var run_speed: float = 500.0 # Define una variable exportada para la velocidad al correr.
@export_range(10, 100000, 10) var stopping_step: float = 1500.0 # Define una variable exportada para la fuerza de frenado.
@export_range(10, 100000, 10) var moving_step: float = 4000.0 # Define una variable exportada para la fuerza de aceleración.

## The SpriteFrames must have specific animations with a certain amount of frames.
## See [member REQUIRED_ANIMATION_FRAMES].
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME: # Define una variable exportada para el recurso SpriteFrames del jugador.
    set = _set_sprite_frames # Define una función setter para la variable sprite_frames.

@export_group("Sounds") # Crea un grupo en el inspector para las variables de sonido.
## Sound that plays for each step during the walk animation
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"): # Define una variable exportada para el sonido de los pasos al caminar.
    set = _set_walk_sound_stream # Define una función setter para la variable walk_sound_stream.

var input_vector: Vector2 # Define una variable para el vector de entrada del jugador.

@onready var player_interaction: PlayerInteraction = %PlayerInteraction # Obtiene una referencia al nodo PlayerInteraction.
@onready var player_fighting: Node2D = %PlayerFighting # Obtiene una referencia al nodo PlayerFighting.
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite # Obtiene una referencia al nodo AnimatedSprite2D del jugador.
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound # Obtiene una referencia al nodo AudioStreamPlayer2D para el sonido de los pasos.


func _set_mode(new_mode: Mode) -> void: # Función setter para la variable mode.
    var previous_mode: Mode = mode # Guarda el modo anterior.
    mode = new_mode # Actualiza el modo actual.
    if not is_node_ready(): # Si el nodo no está listo, retorna.
        return
    match mode: # Usa un match statement para ejecutar código diferente según el modo.
        Mode.COZY: # Si el modo es COZY.
            _toggle_player_behavior(player_interaction, true) # Activa el comportamiento de interacción.
            _toggle_player_behavior(player_fighting, false) # Desactiva el comportamiento de combate.
        Mode.FIGHTING: # Si el modo es FIGHTING.
            _toggle_player_behavior(player_interaction, false) # Desactiva el comportamiento de interacción.
            _toggle_player_behavior(player_fighting, true) # Activa el comportamiento de combate.
        Mode.DEFEATED: # Si el modo es DEFEATED.
            _toggle_player_behavior(player_interaction, false) # Desactiva el comportamiento de interacción.
            _toggle_player_behavior(player_fighting, false) # Desactiva el comportamiento de combate.
    if mode != previous_mode: # Si el modo ha cambiado.
        mode_changed.emit(mode) # Emite la señal mode_changed.


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void: # Función setter para la variable sprite_frames.
    sprite_frames = new_sprite_frames # Actualiza el valor de sprite_frames.
    if not is_node_ready(): # Si el nodo no está listo, retorna.
        return
    if new_sprite_frames == null: # Si el nuevo valor es nulo.
        new_sprite_frames = DEFAULT_SPRITE_FRAME # Usa el valor por defecto.
    player_sprite.sprite_frames = new_sprite_frames # Actualiza el recurso SpriteFrames del AnimatedSprite2D.
    update_configuration_warnings() # Actualiza las advertencias de configuración.


func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void: # Función para activar o desactivar el comportamiento de un nodo.
    behavior_node.visible = is_active # Establece la visibilidad del nodo.
    behavior_node.process_mode = ( # Establece el modo de procesamiento del nodo.
        ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED # Si está activo, hereda el modo de procesamiento, si no, lo desactiva.
    )


func _get_configuration_warnings() -> PackedStringArray: # Función para obtener advertencias de configuración.
    var warnings: PackedStringArray # Define una variable para almacenar las advertencias.
    for animation in REQUIRED_ANIMATION_FRAMES: # Itera sobre las animaciones requeridas.
        if not sprite_frames.has_animation(animation): # Si el recurso SpriteFrames no tiene la animación.
            warnings.append("sprite_frames is missing the following animation: %s" % animation) # Agrega una advertencia.
        elif sprite_frames.get_frame_count(animation) != REQUIRED_ANIMATION_FRAMES[animation]: # Si la animación no tiene la cantidad de frames requerida.
            warnings.append( # Agrega una advertencia.
                (
                    "sprite_frames animation %s has %d frames, but should have %d"
                    % [
                        animation,
                        sprite_frames.get_frame_count(animation),
                        REQUIRED_ANIMATION_FRAMES[animation]
                    ]
                )
            )
    return warnings # Retorna las advertencias.


func _ready() -> void: # Función que se llama cuando el nodo está listo.
    _set_mode(mode) # Establece el modo inicial.
    _set_sprite_frames(sprite_frames) # Establece el recurso SpriteFrames inicial.


func _unhandled_input(_event: InputEvent) -> void: # Función para manejar la entrada del usuario.
    var axis: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down") # Obtiene el vector de entrada del usuario.

    var speed: float # Define una variable para la velocidad.
    if Input.is_action_pressed(&"running"): # Si el usuario está corriendo.
        speed = run_speed # Usa la velocidad al correr.
    else: # Si no está corriendo.
        speed = walk_speed # Usa la velocidad al caminar.

    input_vector = axis * speed # Calcula el vector de entrada.


## Returns [code]true[/code] if the player is running. When using an analogue joystick, this can be
## [code]false[/code] even if the player is holding the "run" button, because the joystick may be
## inclined only slightly.
func is_running() -> bool: # Función para determinar si el jugador está corriendo.
    # While walking diagonally with an analogue joystick, the input vector can be fractionally
    # greater than walk_speed, due to trigonometric/floating-point inaccuracy.
    return input_vector.length_squared() > (walk_speed * walk_speed) + 1.0 # Retorna true si el vector de entrada es mayor que la velocidad al caminar.


func _process(delta: float) -> void: # Función que se llama en cada frame.
    if Engine.is_editor_hint(): # Si el juego se está ejecutando en el editor.
        return # Retorna.

    if player_interaction.is_interacting or mode == Mode.DEFEATED: # Si el jugador está interactuando o está derrotado.
        velocity = Vector2.ZERO # Detiene el movimiento.
        return # Retorna.

    var step: float # Define una variable para la fuerza de aceleración.
    if input_vector.is_zero_approx(): # Si el vector de entrada es casi cero.
        step = stopping_step # Usa la fuerza de frenado.
    else: # Si no es casi cero.
        step = moving_step # Usa la fuerza de aceleración.

    velocity = velocity.move_toward(input_vector, step * delta) # Mueve la velocidad hacia el vector de entrada.

    move_and_slide() # Aplica el movimiento y maneja las colisiones.


func teleport_to( # Función para teletransportar al jugador.
    tele_position: Vector2, # Posición a la que se teletransportará.
    smooth_camera: bool = false, # Si la cámara debe moverse suavemente.
    look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED # Hacia qué lado debe mirar el jugador.
) -> void:
    var camera: Camera2D = get_viewport().get_camera_2d() # Obtiene la cámara del viewport.

    if is_instance_valid(camera): # Si la cámara es válida.
        var smoothing_was_enabled: bool = camera.position_smoothing_enabled # Guarda el estado del suavizado de la cámara.
        camera.position_smoothing_enabled = smooth_camera # Establece el suavizado de la cámara.
        global_position = tele_position # Establece la posición global del jugador.
        %PlayerSprite.look_at_side(look_side) # Hace que el jugador mire hacia el lado especificado.
        await get_tree().process_frame # Espera un frame.
        camera.position_smoothing_enabled = smoothing_was_enabled # Restaura el estado del suavizado de la cámara.
    else: # Si la cámara no es válida.
        global_position = tele_position # Establece la posición global del jugador.


func _set_walk_sound_stream(new_value: AudioStream) -> void: # Función setter para la variable walk_sound_stream.
    walk_sound_stream = new_value # Actualiza el valor de walk_sound_stream.
    if not is_node_ready(): # Si el nodo no está listo.
        await ready # Espera a que esté listo.
    _walk_sound.stream = walk_sound_stream # Establece el stream de audio del nodo AudioStreamPlayer2D.