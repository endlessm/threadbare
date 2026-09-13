# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name TileMapMaskBounds
extends BaseCanvasItemBehavior
## Feeds the bounds of a set of [TileMapLayer]s to a mask shader.
##
## Shaders such as world_rewoven.gdshader stretch a mask texture across a rect
## given in world units, so that it spans the affected area exactly once whether
## the material is applied to a [CanvasGroup] or to a single [CanvasItem]. This
## node computes that rect from the tiles that are in use, and writes it into the
## [code]mask_origin[/code] and [code]mask_size[/code] parameters of the
## [ShaderMaterial] of [member BaseCanvasItemBehavior.canvas_item].
## [br][br]
## Only [TileMapLayer]s are measured: the canvas item itself if it is one, plus
## every [TileMapLayer] among its descendants. A [Sprite2D], or any other kind of
## [CanvasItem], is ignored, because Godot has no general way to ask a canvas
## item for its bounds. So a [CanvasGroup] that mixes tile layers with other
## nodes gets a rect that covers the tile layers only, and one with no tile layer
## at all gets no rect, leaving the shader parameters untouched.
## [br][br]
## Add it as a child of the node holding the material. If [member
## BaseCanvasItemBehavior.canvas_item] is not set, the parent is used.

const MASK_ORIGIN := &"mask_origin"
const MASK_SIZE := &"mask_size"

## Recompute the rect. Useful after changing the tiles.
@export_tool_button("Update bounds") var update_button: Callable = update_bounds


func _set_canvas_item(new_canvas_item: CanvasItem) -> void:
	super(new_canvas_item)
	update_bounds()


func _ready() -> void:
	update_bounds()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()
	if canvas_item:
		if canvas_item.material is not ShaderMaterial:
			warnings.push_back("Canvas item does not have a ShaderMaterial.")
		elif _collect_layers(canvas_item).is_empty():
			warnings.push_back(
				"No TileMapLayer found in the canvas item, so bounds cannot be computed."
			)
	return warnings


## Computes the world-space bounds of the canvas item's tiles and writes them to
## its material.
func update_bounds() -> void:
	if not is_inside_tree() or not canvas_item:
		return

	var material := canvas_item.material as ShaderMaterial
	if not material:
		return

	var bounds := get_world_bounds(canvas_item)
	if not bounds.has_area():
		return

	material.set_shader_parameter(MASK_ORIGIN, bounds.position)
	material.set_shader_parameter(MASK_SIZE, bounds.size)


## Returns the bounds, in world units, of every [TileMapLayer] in [param root],
## including itself. Returns an empty [Rect2] when there is none.
static func get_world_bounds(root: CanvasItem) -> Rect2:
	var bounds := Rect2()
	var first := true

	for layer: TileMapLayer in _collect_layers(root):
		if not layer.tile_set:
			continue
		var used := layer.get_used_rect()
		if not used.has_area():
			continue

		# get_used_rect() is in tile coordinates; convert to the layer's local
		# pixels, then to world space so the rect is comparable across layers.
		var tile_size := Vector2(layer.tile_set.tile_size)
		var local := Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)
		var world := layer.get_global_transform() * local

		if first:
			bounds = world
			first = false
		else:
			bounds = bounds.merge(world)

	return bounds


static func _collect_layers(node: Node) -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	if node is TileMapLayer:
		layers.append(node as TileMapLayer)
	for child: Node in node.get_children():
		layers.append_array(_collect_layers(child))
	return layers
