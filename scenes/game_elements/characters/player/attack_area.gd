extends Area2D

@export var damage: int = 1
@export var attack_cooldown: float = 0.5
var can_attack: bool = true

func _ready():
	collision_mask = 65535   # Máscara a todas las capas para prueba

func _input(event):
	if event.is_action_pressed("attack") and can_attack:
		attack()

func attack():
	can_attack = false
	if owner is Player:
		var player = owner as Player
		var offset_x = 40 if not player.player_sprite.flip_h else -40
		global_position = player.global_position + Vector2(offset_x, 0)
	monitoring = true
	print("Cuerpos superpuestos: ", get_overlapping_bodies())
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Daño aplicado a ", body.name)
	await get_tree().create_timer(0.1).timeout
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
	monitoring = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
