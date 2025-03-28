class_name Inkwell
extends CharacterBody2D

const SPLASH: PackedScene = preload("res://scenes/ink_combat/splash/splash.tscn")

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0

var ink_amount: float = 0.

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var interact_label: Control = %InteractLabel


func _ready() -> void:
	var color: Color = InkBlob.INK_COLORS[ink_color_name]
	animated_sprite_2d.modulate = color

	var current_scene: Node = Engine.get_main_loop().current_scene
	var screen_overlay: CanvasLayer = current_scene.get_node("ScreenOverlay")
	interact_label.reparent(screen_overlay)
	interact_label.label_text = InkBlob.InkColorNames.keys()[ink_color_name]


func got_hit(
	ink_blob_global_position: Vector2, _hit_vector: Vector2, ink_blob_color_name: int
) -> void:
	var splash: Node2D = SPLASH.instantiate()
	splash.ink_color_name = ink_blob_color_name
	Engine.get_main_loop().current_scene.add_child(splash)
	splash.global_position = ink_blob_global_position


func _get_ink_drinkers() -> Array[InkDrinker]:
	var is_ink_drinker: Callable = func(enemy: Node2D) -> bool: return enemy is InkDrinker
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	return enemies.filter(is_ink_drinker)


func fill() -> void:
	animation_player.play(&"fill")
	ink_amount += 0.334
	animated_sprite_2d.frame += 1
	if ink_amount >= 1.:
		var ink_drinkers: Array[InkDrinker] = _get_ink_drinkers()
		var ink_drinker: InkDrinker = ink_drinkers.pick_random() as InkDrinker
		ink_drinker.explode(ink_color_name)
		queue_free()
		interact_label.queue_free()
