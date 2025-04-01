# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends RayCast2D

@export var character: CharacterBody2D

var interact_area: InteractArea
var _target_position_right: Vector2
var _target_position_left: Vector2


func _ready() -> void:
	_target_position_right = target_position
	_target_position_left = target_position.reflect(Vector2.UP)
	if not character and owner is CharacterBody2D:
		character = owner


func _process(_delta: float) -> void:
	if not character:
		return
	if not enabled:
		return
	if not is_zero_approx(character.velocity.x):
		if character.velocity.x < 0:
			target_position = _target_position_left
		else:
			target_position = _target_position_right
	if is_colliding():
		interact_area = get_collider() as InteractArea
	else:
		interact_area = null
