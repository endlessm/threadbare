# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name AreaFiller
extends Node
## Fills a CollisionObject2D with child scenes, spaced randomly with a minimum
## separation.
##
## This can be used with [StaticBody2D] to create a forest at the boundary of
## the map which the player cannot walk through, or with [Area2D] to create a
## patch of wild flowers.
## [br][br]
## Create this node as a child of a [StaticBody2D] or [Area2D] (or another
## [CollisionObject2D]). Define the collisions shapes as normal, either with
## [CollisionPolygon2D], or with [CollisionShape2D] with a [RectangleShape2D],
## [CircleShape2D], or [CapsuleShape2D]. Assign at least one scene to [member
## scenes], adjust other parameters to taste, then click [b]Refill[/b] in the
## inspector to fill the area with a new random arrangement of instances of
## [member scenes]. These children are saved to the owning scene: no random
## generation occurs at runtime.

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

@warning_ignore("unused_private_class_variable")
@export_tool_button("Refill") var _fill_button: Callable = fill

var _area: CollisionObject2D
var _undoredo: Object  # EditorUndoRedoManager


func _enter_tree() -> void:
	var parent := get_parent()
	if parent is CollisionObject2D:
		_area = parent
	update_configuration_warnings()


func _exit_tree() -> void:
	_area = null
	update_configuration_warnings()


func _ready() -> void:
	if not Engine.is_editor_hint():
		self.queue_free()
		return

	var plugin: Node = ClassDB.instantiate("EditorPlugin")
	_undoredo = plugin.get_undo_redo()
	plugin.queue_free()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not _area:
		warnings.append("Parent is not a CollisionObject2D (e.g. Area2D or StaticBody2D)")

	if not scenes:
		warnings.append("At least one scene must be provided")

	return warnings


# Converts a [CollisionShape2D] node's shape to a polygon in the coordinate
# space of its parent [CollisionObject2D]. Supported shape types are
# [RectangleShape2D], [CircleShape2D], and [CapsuleShape2D]. Returns an empty
# array if the shape type is not supported.
func _shape_to_polygon(o: CollisionShape2D) -> PackedVector2Array:
	if not o.shape:
		return PackedVector2Array()

	var local_polygon: PackedVector2Array
	var shape := o.shape

	if shape is RectangleShape2D:
		var h := (shape as RectangleShape2D).size / 2.0
		local_polygon = PackedVector2Array(
			[
				Vector2(-h.x, -h.y),
				Vector2(h.x, -h.y),
				Vector2(h.x, h.y),
				Vector2(-h.x, h.y),
			]
		)
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		var n := 32
		local_polygon.resize(n)
		for i in range(n):
			var angle := TAU * float(i) / n
			local_polygon[i] = Vector2.from_angle(angle) * r
	elif shape is CapsuleShape2D:
		var r := (shape as CapsuleShape2D).radius
		var half_straight := (shape as CapsuleShape2D).height / 2.0 - r
		var n := 16  # vertices per semicircle
		# Top semicircle: center at (0, -half_straight).
		# Sweep from PI to 2*PI so the arc bulges upward (toward -Y in screen space).
		for i in range(n + 1):
			var angle := PI + PI * float(i) / n
			local_polygon.append(Vector2(r * cos(angle), -half_straight + r * sin(angle)))
		# Bottom semicircle: center at (0, +half_straight).
		# Sweep from 0 to PI so the arc bulges downward (toward +Y in screen space).
		for i in range(n + 1):
			var angle := PI * float(i) / n
			local_polygon.append(Vector2(r * cos(angle), half_straight + r * sin(angle)))
	else:
		push_warning(
			(
				"%s has unsupported shape type %s (use RectangleShape2D, CircleShape2D, or CapsuleShape2D)"
				% [o, shape]
			)
		)
		return PackedVector2Array()

	return o.transform * local_polygon


# Merges [param polygon] into [param merged], combining with any polygons it
# overlaps. Returns the updated set of disjoint polygons.
#
# TODO: Holes in merged results (rare for convex inputs) are not handled.
func _merge_into(
	polygon: PackedVector2Array, merged: Array[PackedVector2Array]
) -> Array[PackedVector2Array]:
	var current := polygon
	var result: Array[PackedVector2Array] = []
	for existing in merged:
		var union: Array[PackedVector2Array] = Geometry2D.merge_polygons(existing, current)
		if union.size() == 1:
			# Polygons overlapped; continue merging the combined shape
			current = union[0]
		else:
			# Disjoint; keep existing polygon unchanged
			result.append(existing)
	result.append(current)
	return result


## Generate random points that fill the shapes of [param area], at least
## [param minimum_separation] px apart.
func _generate_points() -> PackedVector2Array:
	var points: PackedVector2Array

	# Collect polygons from all shape owners, converting as needed.
	# If the polygon has a transform we have to apply it here so that
	# minimum_separation is interpreted in the parent's coordinate space.
	var polygons: Array[PackedVector2Array] = []
	for owner_id: int in _area.get_shape_owners():
		var o := _area.shape_owner_get_owner(owner_id)
		var polygon: PackedVector2Array
		if o is CollisionPolygon2D:
			polygon = o.transform * o.polygon
		elif o is CollisionShape2D:
			polygon = _shape_to_polygon(o)
			if polygon.is_empty():
				continue
		else:
			push_warning("%s not supported" % o)
			continue
		polygons.append(polygon)

	# Merge overlapping polygons so that overlap regions are not over-sampled.
	var merged: Array[PackedVector2Array] = []
	for polygon in polygons:
		merged = _merge_into(polygon, merged)

	# Sample each disjoint polygon region.
	for polygon in merged:
		var sampler := PoissonDiscSampler.new()
		sampler.initialise(polygon, minimum_separation)
		sampler.fill()
		points.append_array(sampler.points)

	return points


func _prepare_child(pos: Vector2) -> Node2D:
	var scene: PackedScene = scenes.pick_random()
	var child: Node2D = scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
	child.position = pos
	if sprite_frames and "sprite_frames" in child:
		child.sprite_frames = sprite_frames.pick_random()
	return child


## Clears [member area] (except for this node and any collision shapes),
## generate a new set of points according to the current
## parameters, and fill [member area] with instances of [member scenes]
## at those points.
func fill() -> void:
	var scene := get_tree().edited_scene_root

	_undoredo.create_action("Refill area", UndoRedo.MergeMode.MERGE_DISABLE, scene, false)

	var old_children: Array[Node]
	var new_children: Array[Node]

	for child: Node in _area.get_children():
		if child != self and child is not CollisionPolygon2D and child is not CollisionShape2D:
			old_children.append(child)

	var points := _generate_points()
	for point in points:
		new_children.append(_prepare_child(point))

	# When performing the action in either direction, we want to remove, then add.
	for child in old_children:
		_undoredo.add_do_method(_area, "remove_child", child)

	for child in new_children:
		_undoredo.add_do_method(_area, "add_child", child, true)
		_undoredo.add_do_property(child, "owner", scene)
		_undoredo.add_undo_method(_area, "remove_child", child)

	for child in old_children:
		_undoredo.add_undo_method(_area, "add_child", child, true)
		_undoredo.add_undo_property(child, "owner", scene)

	_undoredo.commit_action()
