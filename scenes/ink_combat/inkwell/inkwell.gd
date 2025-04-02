# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Inkwell
extends StaticBody2D

signal completed

const INK_NEEDED: int = 3

@export var ink_color_name: InkBlob.InkColorNames = InkBlob.InkColorNames.CYAN

var ink_amount: int = 0

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var interact_label: Control = %InteractLabel


func _ready() -> void:
	var color: Color = InkBlob.INK_COLORS[ink_color_name]
	animated_sprite_2d.modulate = color

	interact_label.label_text = InkBlob.InkColorNames.keys()[ink_color_name]

	var current_scene: Node = get_tree().current_scene
	var screen_overlay: CanvasLayer = current_scene.get_node_or_null("ScreenOverlay")
	if not screen_overlay:
		push_error("ScreenOverlay not found in current scene.")
		return
	interact_label.reparent(screen_overlay)


func fill() -> void:
	animation_player.play(&"fill")
	ink_amount += 1
	animated_sprite_2d.frame += 1
	if ink_amount >= INK_NEEDED:
		var ink_drinkers: Array[Node] = get_tree().get_nodes_in_group(&"ink_drinkers")
		var ink_drinker: InkDrinker = ink_drinkers.pick_random() as InkDrinker
		ink_drinker.explode(ink_color_name)
		queue_free()
		interact_label.queue_free()
		completed.emit()
