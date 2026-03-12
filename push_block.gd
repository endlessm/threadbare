extends CharacterBody2D

@export var foam: TileMapLayer
@export var submerged_blocks: TileMapLayer


func _on_area_2d_body_shape_entered(
	_body_rid: RID,
	body: Node2D,
	_body_shape_index: int,
	_local_shape_index: int,
) -> void:
	var tile_map := body as TileMapLayer
	if not tile_map:
		return

	# For this to work, the water layer's physics quadrant size has to be set to
	# 1, i.e. no chunking of water physics - probably bad for performance!
	# var coords := tile_map.get_coords_for_body_rid(_body_rid)
	# TODO: is there a way to do this "properly" using physics? If not:
	var coords := tile_map.local_to_map(tile_map.to_local(global_position))
	# Erase the water
	tile_map.set_cell(coords, -1)
	# Add foam
	foam.set_cell(coords, 2, Vector2i(0, 0))
	# Put a static copy of this block into the water
	submerged_blocks.set_cell(coords, 0, Vector2i(1, 0))
	# Free the physical block
	queue_free()
	# TODO: sound-effect
	# TODO: do this more convincingly!
