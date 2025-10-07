# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ThrowProjectileBehavior
extends Node2D
## @experimental
##
## Behavior to throw projectiles.

## Controls where the projectile instances will be added.
enum AddMode {
	## Add projectiles as child of the reference node.
	CHILD_OF_REFERENCE,
	## Add projectiles to the current scene root.
	CHILD_OF_ROOT,
}
## The projectile scenes to instantiate when throwing a projectile.
@export var projectile_scenes: Array[PackedScene]

## The target to aim the throw.
@export var target: Node2D

## The projectile will be instantiated at this distance from this node,
## in the direction of the [member target].
@export_range(0., 100., 1., "or_greater", "suffix:m") var distance: float = 100.0

## If the projectile is a [RigidBody2D], apply this impulse when throwing.
@export_range(10., 1000., 5., "or_greater", "or_less", "suffix:m/s") var impulse: float = 30.0

## Where to add the projectiles.
@export var add_mode: AddMode

## Projectiles may be added as children of this node depending on [member add_mode].
## [br][br]
## [b]Note:[/b] If there is a grandparent node and this isn't set,
## the grandparent node will be automatically assigned to this variable.
@export var reference: Node2D


func _enter_tree() -> void:
	if not reference and get_parent() and get_parent().get_parent():
		reference = get_parent().get_parent()


## Instantiate the projectile and add it to the scene.
## [br][br]
## Hint: You can connect a [signal Timer.timeout] signal to this method
## for periodic throws.
func throw() -> void:
	var projectile := projectile_scenes.pick_random().instantiate() as Node2D
	var direction := global_position.direction_to(target.global_position)
	projectile.global_position = global_position + direction * distance
	if projectile is RigidBody2D:
		projectile.apply_impulse(direction * impulse)
	match add_mode:
		AddMode.CHILD_OF_REFERENCE:
			reference.add_child(projectile)
		AddMode.CHILD_OF_ROOT:
			get_tree().current_scene.add_child(projectile)
