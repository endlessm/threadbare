extends Area2D

@export var speed: float = 300.0
@export var damage: int = 50
var direction: Vector2 = Vector2.RIGHT
@export var owner_type: String = "player"
var active: bool = false

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	active = true
	connect("area_entered", Callable(self, "_on_hit"))
	connect("body_entered", Callable(self, "_on_body_hit"))

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player_turret"):
		print("💥 Bala impactó la torreta del jugador")
		if area.has_method("shoot"):
			area.shoot()
		queue_free()

func _on_body_hit(body: Node) -> void:
	if not active:
		return
	if owner_type == "player" and body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	if owner_type == "boss" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	queue_free()

func _on_visible_on_screen_exited() -> void:
	queue_free()
