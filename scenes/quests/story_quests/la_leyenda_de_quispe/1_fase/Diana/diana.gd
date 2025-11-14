extends Area2D

var vida_maxima: int = 3
var vida_actual: int = 0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	vida_actual = vida_maxima
	
	if animated_sprite:
		animated_sprite.animation = "filling"
		animated_sprite.stop() 
		animated_sprite.frame = 0
	else:
		print("❌ ERROR: Falta el AnimatedSprite2D en la Diana")

func recibir_dano() -> void:
	vida_actual -= 1
	print("🎯 Diana golpeada. Vida restante: ", vida_actual)
	var frame_objetivo: int = vida_maxima - vida_actual
	if animated_sprite:
		if frame_objetivo < animated_sprite.sprite_frames.get_frame_count("filling"):
			animated_sprite.frame = frame_objetivo
	if vida_actual <= 0:
		destruir()

func destruir() -> void:
	print("💥 Diana destruida")
	queue_free()
