extends CanvasLayer

@onready var text = $Label
@onready var bg = $ColorRect

@export var text_fade_time: float = 3.0
@export var bg_fade_time: float = 2.0
@export var initial_delay: float = 0.5

func _ready() -> void:
	run_intro()

func run_intro() -> void:
	# Espera mínima para asegurar que todo cargó
	await get_tree().process_frame
	await get_tree().create_timer(initial_delay).timeout

	# Fade del texto
	var tween1 = create_tween()
	tween1.tween_property(text, "modulate:a", 0.0, text_fade_time)
	await tween1.finished

	# Fade del fondo negro
	var tween2 = create_tween()
	tween2.tween_property(bg, "modulate:a", 0.0, bg_fade_time)
	await tween2.finished

	# Eliminar overlay completamente
	queue_free()
