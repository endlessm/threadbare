extends CharacterBody2D

@export var texture_left: Texture2D
@export var texture_right: Texture2D
@export var speed: float = 175.0
@export var patrol_distance: float = 300.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

var direction: int = 1
var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	detection_area.body_entered.connect(_on_detection_area_body_entered)

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed
	move_and_slide()

	# patrulla: va y vuelve dentro de patrol_distance
	if global_position.x >= start_position.x + patrol_distance:
		direction = -1
	elif global_position.x <= start_position.x - patrol_distance:
		direction = 1

	update_sprite_direction()

func update_sprite_direction() -> void:
	if direction > 0:
		sprite.texture = texture_right
	else:
		sprite.texture = texture_left

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().reload_current_scene()
