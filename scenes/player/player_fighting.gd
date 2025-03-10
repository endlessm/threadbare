class_name PlayerFighting
extends Node2D

@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_shield: AnimatableBody2D = %PlayerShield
@onready var hit_box: Area2D = %HitBox
@onready var fight_animation: AnimationPlayer = %FightAnimation

var player: Player
var is_fighting: bool = false
signal got_hit

func _ready() -> void:
	hit_box.body_entered.connect(_on_player_got_hit)
	if owner is Player:
		player = owner

func _on_player_got_hit(body: Node2D):
	body.queue_free()
	got_hit.emit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_accept"):
		is_fighting = true
	elif Input.is_action_just_released(&"ui_accept"):
		is_fighting = false
