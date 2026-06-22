extends Node

@onready var player = $"../Player"
@onready var anim_intro = $"../Player/AnimationPlayer2"
@onready var overlay = $"../ScreenOverlay"

func _ready():
	player.mode = Player.Mode.SYSTEM_CONTROLLED
	
	# 1. MOSTRAR EL DIÁLOGO
	overlay.mostrar_mensaje("¡Bienvenido! Ten cuidado.")
	
	# 2. INICIAR LA ANIMACIÓN DE INTRO
	anim_intro.play("intro")
	
	# 3. EL TRUCO PARA QUE CAMINE:
	# Le damos una velocidad pequeña para que el script del personaje crea que se mueve
	# Ajusta el valor de (100, 0) a la velocidad real de tu personaje
	player.velocity = Vector2(100, 0) 
	
	await anim_intro.animation_finished
	
	# 4. RESET AL TERMINAR
	player.velocity = Vector2.ZERO
	player.mode = Player.Mode.USER_CONTROLLED
