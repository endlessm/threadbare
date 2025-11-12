extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	visible = false
	modulate.a = 0.0  # Comienza invisible
	await get_tree().create_timer(11.0).timeout
	aparecer()

func aparecer() -> void:
	visible = true
	scale = Vector2(0.1, 0.1)
	if sprite:
		sprite.play("aparecer")

	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1, 1), 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


	# Creamos el tween dentro del árbol, justo cuando lo necesitamos
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
