extends Area2D

signal parte_recogida

var recogida: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if recogida:
		return
	if body.name != "Player":
		return
	recogida = true
	emit_signal("parte_recogida")
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.12)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	queue_free()
