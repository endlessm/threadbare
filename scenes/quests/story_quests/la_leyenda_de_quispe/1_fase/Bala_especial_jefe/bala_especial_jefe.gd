extends Area2D

@export var speed: float = 250.0
@export var damage: int = 80
var direction: Vector2 = Vector2.LEFT

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	$CollisionPolygon2D.disabled = false

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("💥 Bala triangular impactó al jugador")
		queue_free()

func _on_visible_on_screen_exited() -> void:
	queue_free()
