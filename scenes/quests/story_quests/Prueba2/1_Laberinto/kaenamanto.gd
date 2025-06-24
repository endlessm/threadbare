extends CharacterBody2D

@export var speed: float = 84
@export var attack_cooldown: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $Area2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer

var player: Node2D = null
var can_attack: bool = true

func _ready() -> void:
	vision_area.body_entered.connect(_on_body_entered)
	vision_area.body_exited.connect(_on_body_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_timer.timeout.connect(_on_attack_timeout)

	sprite.play("idle")

func _physics_process(_delta: float) -> void:
	if player:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		sprite.flip_h = direction.x < 0
		if sprite.animation != "default":
			sprite.play("default")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite.animation != "idle":
			sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

func _on_attack_area_entered(body: Node2D) -> void:
	if body.name == "Player" and can_attack:
		can_attack = false
		sprite.play("attack")

		await get_tree().create_timer(0.2).timeout

		if body.has_method("set_mode"):
			body.set_mode(2) # Mode.DEFEATED

		var anim_sprite := body.get_node_or_null("PlayerSprite")
		if anim_sprite and anim_sprite is AnimatedSprite2D:
			if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("defeated"):
				anim_sprite.play("defeated")
				await anim_sprite.animation_finished

		await get_tree().create_timer(0.5).timeout

		if body.has_method("teleport_to"):
			var respawn_position := Vector2(100, 100)
			if body.has_meta("last_respawn_position"):
				respawn_position = body.get_meta("last_respawn_position")
			body.teleport_to(respawn_position, true)

		attack_timer.start(attack_cooldown)

func _on_attack_timeout() -> void:
	can_attack = true
