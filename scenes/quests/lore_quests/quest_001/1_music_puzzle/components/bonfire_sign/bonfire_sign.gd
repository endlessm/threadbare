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

@export var is_ignited: bool = false:
	set(new_val):
		is_ignited = new_val
		update_ignited_state()

@onready var fire: AnimatedSprite2D = %Fire
@onready var interact_area: InteractArea = %InteractArea
@onready var sign_sprite: AnimatedSprite2D = %SignSprite

@onready var puzzle: MusicPuzzle = get_node(puzzle_path)


func _ready() -> void:
	update_ignited_state()


func update_ignited_state():
	if is_instance_valid(fire):
		fire.play(&"burning" if is_ignited else &"default")
	if is_instance_valid(interact_area):
		interact_area.disabled = not is_ignited

	update_sign_sprite()


func ignite() -> void:
	is_ignited = true


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	await puzzle.play_demo_melody_of_fire(self)
	interact_area.end_interaction()


func update_sign_sprite() -> void:
	if !is_instance_valid(sign_sprite):
		return
	var suffix: String = "on" if is_ignited else "off"
	var sign_string: String = Sign.find_key(sign)

	sign_sprite.animation = "%s_%s" % [sign_string.to_snake_case(), suffix]
