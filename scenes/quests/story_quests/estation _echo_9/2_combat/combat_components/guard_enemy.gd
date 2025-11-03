extends Node2D

@export var data: Resource
var direction := 1
var start_position := Vector2.ZERO
@onready var sprite = $Sprite2D

func _ready():
	start_position = position
	if data == null:
		print("⚠ No se asignó .tres al enemigo")
	else:
		print("✅ Enemigo listo")

func _process(delta):
	if data == null:
		return
	position.x += data.speed * direction * delta

	if abs(position.x - start_position.x) > data.patrol_distance:
		direction *= -1
		sprite.flip_h = direction < 0

func _on_VisionArea_body_entered(body):
	if body.name == "Player":
		sprite.texture = load("res://2_combat/combat_components/estation_echo_9_guard_enemy_alerted.png")
		get_tree().reload_current_scene()
