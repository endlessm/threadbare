class_name Inkwell
extends CharacterBody2D

const FX = preload("res://scenes/fx.tscn")

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var interact_label: Control = %InteractLabel

var ink_amount = 0.

func _ready() -> void:
	var color: Color = Globals.INK_COLORS[ink_color_name]
	animated_sprite_2d.modulate = color
	
	var current_scene: Node = Engine.get_main_loop().current_scene
	var screen_overlay: CanvasLayer = current_scene.get_node("ScreenOverlay")
	interact_label.reparent(screen_overlay)
	interact_label.label_text = Globals.INK_COLOR_NAMES.keys()[ink_color_name]


func got_hit(bullet_global_position: Vector2, hit_vector: Vector2, bullet_ink_color_name):
	var fx = FX.instantiate()
	fx.ink_color_name = bullet_ink_color_name
	Engine.get_main_loop().current_scene.add_child(fx)
	fx.global_position = bullet_global_position

func fill():
	animation_player.play(&"fill")
	ink_amount += 0.334
	animated_sprite_2d.frame += 1
	if ink_amount >= 1.:
		var enemies: Array = get_tree().get_nodes_in_group(&"enemies")
		var enemy = enemies.pick_random() as Enemy
		enemy.die(ink_color_name)
		queue_free()
		interact_label.queue_free()

		
