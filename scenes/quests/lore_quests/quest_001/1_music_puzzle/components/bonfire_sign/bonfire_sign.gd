# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BonfireSign
extends StaticBody2D

enum Sign { FORWARD, BACK, BACK_UP, FORWARD_UP }

# This is a NodePath instead of just a node reference to be able to initialize it to ..
@export_node_path("MusicPuzzle") var puzzle_path: NodePath = ^".."

@export var sign: Sign = Sign.FORWARD:
	set(new_sign):
		sign = new_sign
		update_sign_sprite()

var _is_ignited: bool = false

@onready var fire: AnimatedSprite2D = %Fire
@onready var interact_area: InteractArea = %InteractArea
@onready var sign_sprite: AnimatedSprite2D = %SignSprite

@onready var puzzle: MusicPuzzle = get_node(puzzle_path)


func _ready() -> void:
	update_sign_sprite()


func ignite() -> void:
	_is_ignited = true
	fire.play(&"burning")
	interact_area.disabled = false
	update_sign_sprite()


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	await puzzle.play_demo_melody_of_fire(self)
	interact_area.end_interaction()


func update_sign_sprite() -> void:
	if !is_inside_tree():
		return
	var suffix: String = "on" if _is_ignited else "off"
	var sign_string: String = Sign.find_key(sign)

	sign_sprite.animation = "%s_%s" % [sign_string.to_snake_case(), suffix]
