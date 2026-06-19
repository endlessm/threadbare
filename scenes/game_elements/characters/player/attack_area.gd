extends Area2D

@export var damage: int = 1
@export var attack_cooldown: float = 0.5
var can_attack: bool = true

func _ready():
	collision_mask = 2   # Solo capa zombi
	monitoring = false

func _process(_delta):
	# Voltear visualmente (opcional)
	if owner is Player:
		var player = owner as Player
		scale.x = 1 if not player.player_sprite.flip_h else -1

func _input(event):
	if event.is_action_pressed("attack") and can_attack:
		attack()

func attack():
	can_attack = false
	monitoring = true
	await get_tree().create_timer(0.05).timeout
	var bodies = get_overlapping_bodies()
	print("Cuerpos detectados: ", bodies)
	for body in bodies:
		if body == owner:   # Ignorar al jugador
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Daño a ", body.name)
	monitoring = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
