extends Node2D

var is_fighting: bool = false

@onready var hit_box: Area2D = %HitBox
@onready var got_hit_animation: AnimationPlayer = %GotHitAnimation
@onready var air_stream: Area2D = %AirStream
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var timer: Timer = %Timer

@onready var player: Player = self.owner as Player

var life = 3


func _ready() -> void:
	hit_box.body_entered.connect(_on_body_entered)
	air_stream.body_entered.connect(_on_air_stream_body_entered)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"repel"):
		is_fighting = true
	elif Input.is_action_just_released(&"repel"):
		is_fighting = false


func _on_body_entered(body: Node2D) -> void:
	body = body as Projectile
	if not body:
		return
	life = life - 1 
	body.add_small_fx()
	body.queue_free()
	got_hit_animation.play(&"got_hit")
	CameraShake.shake()
	if life == 0:
		player.mode = Player.Mode.DEFEATED
		await get_tree().create_timer(2.0).timeout
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
	hit_box.set_collision_mask_value(9, false)
	await get_tree().create_timer(2.0).timeout
	hit_box.set_collision_mask_value(9, true)


func _on_air_stream_body_entered(body: Projectile) -> void:
	body.can_hit_enemy = true
	body.can_hit_player = false
	body.got_hit(owner)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DISABLED:
			got_hit_animation.play(&"RESET")
			got_hit_animation.advance(0)
