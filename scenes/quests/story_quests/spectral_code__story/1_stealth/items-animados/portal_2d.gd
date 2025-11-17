extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	$AnimatedSprite2D.play("aparecer")
	visible = true
	modulate.a = 1.0  # Comienza visible
	scale = Vector2(1, 1)


	# Espera unos segundos antes de desaparecer (ajusta el tiempo a tu gusto)
	await get_tree().create_timer(7.0).timeout
	desaparecer()

func desaparecer() -> void:
	var t := create_tween()
	# Alpha de 1 a 0 (fade out sutil)
	t.tween_property(self, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Escala de normal a un poco más pequeña
	t.tween_property(self, "scale", Vector2(0.8, 0.8), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Al terminar el tween, ocultamos el nodo
	t.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	visible = false
