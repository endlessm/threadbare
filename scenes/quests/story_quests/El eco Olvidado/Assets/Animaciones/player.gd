extends CharacterBody2D

@export var speed: float = 400.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var step_sound: AudioStreamPlayer = $Pasos

# Variables para controlar el ritmo de los pasos
var can_play_step: bool = true
var is_moving: bool = false

func _ready() -> void:
	# Verificar que las referencias no sean null
	if animated_sprite == null:
		print("ERROR: AnimatedSprite2D no encontrado")
	
	if step_sound == null:
		print("ERROR: Nodo de pasos no encontrado")
	else:
		print("Nodo de pasos encontrado")
		# Configurar el nodo de audio
		step_sound.autoplay = false
		step_sound.stop()

func _physics_process(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	
	# Verificar si el personaje se está moviendo
	var was_moving = is_moving
	is_moving = input_direction != Vector2.ZERO
	
	# Si dejó de moverse, detener el sonido inmediatamente
	if was_moving and not is_moving:
		step_sound.stop()
		can_play_step = true
	
	# Reproducir sonido de pasos cuando se mueve
	if is_moving and step_sound != null:
		play_step_sound()
	
	handle_animations(input_direction)
	move_and_slide()

func handle_animations(input_direction: Vector2) -> void:
	if not animated_sprite:
		return
	
	if input_direction == Vector2.ZERO:
		if animated_sprite.animation != "Idle" and animated_sprite.sprite_frames.has_animation("Idle"):
			animated_sprite.play("Idle")
	else:
		if animated_sprite.sprite_frames.has_animation("Run"):
			if animated_sprite.animation != "Run":
				animated_sprite.play("Run")
	
	if input_direction.x > 0:
		animated_sprite.flip_h = false
	elif input_direction.x < 0:
		animated_sprite.flip_h = true

# Función para reproducir el sonido de paso con un pequeño retraso entre pasos
func play_step_sound() -> void:
	if can_play_step and not step_sound.playing:
		step_sound.play()
		can_play_step = false
		# Esperar un poco antes de permitir el siguiente paso
		await get_tree().create_timer(0.3).timeout
		can_play_step = true

# Función de prueba - presiona ESPACIO para probar el sonido manualmente
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("=== PRUEBA DE SONIDO MANUAL ===")
		if step_sound != null:
			step_sound.play()
			print("Sonido reproducido manualmente")
			
