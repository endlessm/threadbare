extends Area2D

@export var move_distance: float = 100.0
@export var speed: float = 100.0
@export var hat_scene: PackedScene

var start_x: float
var direction: int = 1
var hat_dropped: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hat_spawn_point: Marker2D = $HatSpawnPoint
@onready var hookable_area: HookableArea = %HookableArea
@onready var hookable_collision: CollisionShape2D = %HookableArea/CollisionShape2D

func _ready() -> void:
	start_x = global_position.x
	animated_sprite.play("with_hat")


func _process(delta: float) -> void:
	if hat_dropped:
		return

	global_position.x += speed * direction * delta

	if global_position.x >= start_x + move_distance:
		direction = -1
		animated_sprite.flip_h = true
	elif global_position.x <= start_x:
		direction = 1
		animated_sprite.flip_h = false


func got_pulled(_direction: Vector2) -> void:
	if hat_dropped:
		hookable_area.release_from_pull(true)
		return

	hit_by_grapple()

	await get_tree().create_timer(0.1).timeout
	hookable_area.release_from_pull(true)


func hit_by_grapple() -> void:
	if hat_dropped:
		return

	hat_dropped = true

	animated_sprite.play("no_hat")

	hookable_area.monitoring = false
	hookable_area.monitorable = false
	hookable_collision.set_deferred("disabled", true)

	drop_hat()


func drop_hat() -> void:
	if hat_scene == null:
		return

	var hat: Node2D = hat_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(hat)
	hat.skeleton_pirate = get_tree().current_scene.get_node("SkeletonPirate")
	hat.global_position = hat_spawn_point.global_position

	var target_position: Vector2 = hat.global_position + Vector2(0, 40)

	var tween := create_tween()
	tween.tween_property(
		hat,
		"global_position",
		target_position,
		0.4
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
