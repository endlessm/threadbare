# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ShapeCast2D

@export var character: CharacterBody2D

var _target_position_right: Vector2
var _target_position_left: Vector2


func _ready() -> void:
	_target_position_right = target_position
	_target_position_left = target_position.reflect(Vector2.UP)
	if not character and owner is CharacterBody2D:
		character = owner


func get_interact_area() -> InteractArea:
	var closest 
	var closest_position
	print(get_collision_count())
	for i in get_collision_count():
		var collider = get_collider(i)
		var collider_distance = collider.global_position.distance_to(character.global_position)
		if not closest or collider_distance < closest_position :
			closest = collider
			closest_position = collider_distance
	return closest as InteractArea


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
