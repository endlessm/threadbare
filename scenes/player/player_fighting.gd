class_name PlayerFighting
extends Node2D

@export var player: Player

@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_shield: StaticBody2D = %PlayerShield
@onready var player_shield_collision: CollisionShape2D = %PlayerShieldCollision
@onready var hit_box: Area2D = %HitBox

var is_fighting: bool = false

func _ready() -> void:
	hit_box.body_entered.connect(_on_player_got_hit)
	if not player and owner is Player:
		player = owner

func _on_player_got_hit(_body: Node2D):
	print("HIT")

func _process(_delta: float) -> void:
	if not player.axis.is_zero_approx():
		var angle = player.axis.angle()
		player_shield.rotation = angle - PI/2

	if Input.is_action_just_pressed(&"ui_accept"):
		is_fighting = true
		player_shield_collision.disabled = false
	elif Input.is_action_just_released(&"ui_accept"):
		await player_sprite.animation_looped
		player_shield_collision.disabled = true
		is_fighting = false
