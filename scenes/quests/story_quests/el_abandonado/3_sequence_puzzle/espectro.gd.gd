extends Area2D

@export var speed: float = 520.0
@export var damage: int = 10
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func setup(start_position: Vector2, target_position: Vector2) -> void:
	global_position = start_position
	direction = (target_position - start_position).normalized()
	rotation = direction.angle()


func setup_direction(start_position: Vector2, new_direction: Vector2) -> void:
	global_position = start_position
	direction = new_direction.normalized()
	rotation = direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if sprite != null:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("El espectro golpeó al jugador")

		if body.has_method("take_damage"):
			body.take_damage(damage)

		queue_free()
