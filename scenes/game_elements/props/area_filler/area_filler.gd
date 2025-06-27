# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name AreaFiller
extends Node
## Fills a CollisionObject2D with child scenes,
## spaced randomly with a minimum separation.
##
## This can be used with [StaticBody2D] to create a forest at the boundary of
## the map which the player cannot walk through, or with [Area2D] to create a
## patch of wild flowers.
##
## The level designer should set [member area]'s [CollisionPolygon2D](s)
## and the parameters of this node as desired, then click Refill in the
## inspector to fill the area with a
## new random arrangement of child scenes. These children are saved to the
## scene, and no random generation occurs at runtime.

## Scenes that will be randomly placed into [member area]. There is an equal
## probability of each scene being used each time. This list must not be
## empty.
@export var scenes: Array[PackedScene] = []:
	set(new_value):
		scenes = new_value
		update_configuration_warnings()

## If non-empty, each placed scene will have a randomly-selected element of this
## list assigned to its [code]sprite_frames[/code] property.
@export var sprite_frames: Array[SpriteFrames] = []

## Minimum separation between placed scenes. The maximum separation is twice
## this value.
@export_range(16.0, 256.0, 1.0, "suffix:px", "or_more") var minimum_separation: float = 64.0

@export_tool_button("Refill") var fill_button: Callable = fill

var _area: CollisionObject2D


func _enter_tree() -> void:
	var parent := get_parent()
	if parent is CollisionObject2D:
		_area = parent
	update_configuration_warnings()


func _exit_tree() -> void:
	_area = null
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not _area:
		warnings.append("Parent is not a CollisionObject2D (e.g. Area2D or StaticBody2D)")

	if not scenes:
		warnings.append("At least one scene must be provided")

	return warnings


## Generate random points that fill the shapes of [param area], at least
## [param minimum_separation] px apart.
func _generate_points() -> PackedVector2Array:
	var points: PackedVector2Array

	# TODO: Handling multiple shapes separately will give incorrect results if
	# they overlap. A more correct approach would be to merge the polygons, and
	# deal with shapes that have holes in!
	for owner_id: int in _area.get_shape_owners():
		var o := _area.shape_owner_get_owner(owner_id)
		if o is CollisionPolygon2D:
			# If the polygon has a transform we have to feed the sampler the
			# transformed points. Otherwise you get weird results when the
			# polygon is scaled or skewed because the minimum_separation has
			# not been.
			var transformed_polygon: PackedVector2Array = o.transform * o.polygon
			var sampler := PoissonDiscSampler.new()
			sampler.initialise(transformed_polygon, minimum_separation)
			sampler.fill()

			points.append_array(sampler.points)
		else:
			push_warning("%s not supported (use CollisionPolygon2D)" % o)

	return points


func _clear_area() -> void:
	for child: Node in _area.get_children():
		if child != self and child is not CollisionPolygon2D and child is not CollisionShape2D:
			child.queue_free()


func _add_child(pos: Vector2) -> void:
	var child: Node2D = scenes.pick_random().instantiate()
	child.position = pos
	if sprite_frames and "sprite_frames" in child:
		child.sprite_frames = sprite_frames.pick_random()
	_area.add_child(child, true)
	child.owner = get_tree().edited_scene_root


## Clears [member area] (except for this node and any collision shapes),
## generate a new set of points according to the current
## parameters, and fill [member area] with instances of [member scenes]
## at those points.
func fill() -> void:
	_clear_area()

	# Wait a tick so that the old children are freed and their names can be reused
	await get_tree().process_frame

	var points := _generate_points()
	for point in points:
		_add_child(point)
