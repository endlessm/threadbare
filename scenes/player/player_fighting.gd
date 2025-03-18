class_name PlayerFighting
extends Node2D

const FX = preload("res://scenes/fx.tscn")
const BOOM = preload("res://scenes/boom.tscn")

@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_shield: AnimatableBody2D = %PlayerShield
@onready var hit_box: Area2D = %HitBox
@onready var fight_animation: AnimationPlayer = %FightAnimation
@onready var camera_2d: Camera2D = %Camera2D
@onready var health_bar: ProgressBar = %HealthBar

var player: Player
var is_fighting: bool = false
var health: float = 1.0
signal got_hit

func _ready() -> void:
	hit_box.body_entered.connect(_on_player_got_hit)
	if owner is Player:
		player = owner

func _on_player_got_hit(body: Node2D):
	body.queue_free()
	got_hit.emit()
	health -= 0.2
	health_bar.value = clamp(health, 0., 1.)
	if health <= 0.:
		var boom = BOOM.instantiate()
		if body is Bullet:
			boom.ink_color_name = body.ink_color_name
		Engine.get_main_loop().current_scene.add_child(boom)
		boom.global_position = body.global_position
		camera_2d.position_smoothing_enabled = false
		camera_2d.reparent(player.get_parent(), true)
		player.queue_free()
	else:
		var fx = FX.instantiate()
		if body is Bullet:
			fx.ink_color_name = body.ink_color_name
		Engine.get_main_loop().current_scene.add_child(fx)
		fx.global_position = body.global_position


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_accept"):
		is_fighting = true
	elif Input.is_action_just_released(&"ui_accept"):
		is_fighting = false
