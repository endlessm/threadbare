class_name Enemy
extends CharacterBody2D

const BOOM = preload("res://scenes/boom.tscn")
const BULLET = preload("res://scenes/bullet.tscn")
@onready var timer: Timer = %Timer
@onready var bullet_marker: Marker2D = %BulletMarker
@onready var hit_box: Area2D = %HitBox
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var health_bar: ProgressBar = %HealthBar

var health = 1.

func _ready() -> void:
	timer.timeout.connect(_on_timeout)
	hit_box.body_entered.connect(_on_got_hit)

func _on_timeout() -> void:
	if not Globals.player or Globals.player.is_queued_for_deletion():
		return
	animated_sprite_2d.play(&"attack anticipation")
	await animated_sprite_2d.animation_looped
	animated_sprite_2d.play(&"attack")
	var player = Globals.player as Player
	var bullet = BULLET.instantiate()
	bullet.direction = player.global_position - bullet_marker.global_position
	bullet.ink_color_name = randi_range(0, 3)
	bullet.global_position = bullet_marker.global_position + bullet.direction.normalized() * 100.
	Engine.get_main_loop().current_scene.add_child(bullet)
	await animated_sprite_2d.animation_looped
	animated_sprite_2d.play(&"idle")

func _on_got_hit(body: Node2D) -> void:
	body.queue_free()
	animation_player.play(&"got hit")
	health -= 0.5
	health_bar.value = clamp(health, 0., 1.)
	if health <= 0.:
		var boom = BOOM.instantiate()
		if body is Bullet:
			boom.ink_color_name = body.ink_color_name
		Engine.get_main_loop().current_scene.add_child(boom)
		boom.global_position = body.global_position
		queue_free()
