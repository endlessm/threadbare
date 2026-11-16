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
@export var target: Node2D:
	set = _set_target

## The projectile will be instantiated at this distance from this node,
## in the direction of the [member target].
@export_range(0., 100., 1., "or_greater", "suffix:m") var distance: float = 100.0

## If the projectile is a [RigidBody2D], apply this impulse when throwing.
@export_range(10., 1000., 5., "or_greater", "or_less", "suffix:m/s") var impulse: float = 30.0

## Where to add the projectiles.
@export var add_mode: AddMode:
	set = _set_add_mode

## Projectiles may be added as children of this node depending on [member add_mode].
## [br][br]
## [b]Note:[/b] If there is a grandparent node and this isn't set,
## the grandparent node will be automatically assigned to this variable.
@export var reference: Node2D:
	set = _set_reference


func _set_target(new_value: Node2D) -> void:
	target = new_value
	update_configuration_warnings()


func _set_add_mode(new_value: AddMode) -> void:
	add_mode = new_value
	update_configuration_warnings()
	notify_property_list_changed()


func _set_reference(new_value: Node2D) -> void:
	reference = new_value
	update_configuration_warnings()


func _enter_tree() -> void:
	if not reference and get_parent() and get_parent().get_parent():
		reference = get_parent().get_parent()


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"reference":
			if add_mode == AddMode.CHILD_OF_ROOT:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if add_mode == AddMode.CHILD_OF_REFERENCE and not reference:
		warnings.append("Reference node must be set if Add Mode is Child of Reference")
	if not projectile_scenes or projectile_scenes.is_empty():
		warnings.append("At least one projectile scene must be set")
	if not target:
		warnings.append("Target must be set")
	return warnings


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
