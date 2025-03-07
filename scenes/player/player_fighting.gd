class_name PlayerFighting
extends Node2D

@export var player: Player

@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_shield: AnimatableBody2D = %PlayerShield
@onready var hit_box: Area2D = %HitBox

var is_fighting: bool = false
signal got_hit

func _ready() -> void:
	hit_box.body_entered.connect(_on_player_got_hit)
	if not player and owner is Player:
		player = owner

func _on_player_got_hit(body: Node2D):
	body.queue_free()
	got_hit.emit()

func _process(_delta: float) -> void:
	if not player.axis.is_zero_approx():
		var angle = player.axis.angle()
		player_shield.rotation = angle - PI/2

	if Input.is_action_just_pressed(&"ui_accept"):
		is_fighting = true
	elif Input.is_action_just_released(&"ui_accept"):
		await player_sprite.animation_looped
		is_fighting = false
