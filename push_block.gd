extends CharacterBody2D

# Beware dodgy maths
const INITIAL_VELOCITY := 256.0  # px/s
const DURATION := 0.5  # s
const DECELERATION := INITIAL_VELOCITY / DURATION  # px/s^2

@export var foam: TileMapLayer
@export var submerged_blocks: TileMapLayer

func _ready() -> void:
	if not submerged_blocks and get_parent() is TileMapLayer:
		submerged_blocks = get_parent()
	
	if not foam:
		foam = submerged_blocks.get_parent().get_node("Foam")


func snap_to_cardinal(v: Vector2) -> Vector2:
	return Vector2(signf(v.x), 0) if absf(v.x) > absf(v.y) else Vector2(0, signf(v.y))


func got_hit(player: Node2D) -> void:
	var dir := player.global_position.direction_to(global_position)
	velocity = snap_to_cardinal(dir) * INITIAL_VELOCITY


func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)

	# Need to not call move_and_slide() otherwise, or else you can push the box by running against it and then it slides away to resolve the collision.
	if not velocity.is_zero_approx():
		move_and_slide()


func _on_area_2d_body_shape_entered(
	body_rid: RID,
	body: Node2D,
	_body_shape_index: int,
	_local_shape_index: int,
) -> void:
	var tile_map := body as TileMapLayer
	if not tile_map:
		return

	# For this to work, the water layer's physics quadrant size has to be set to
	# 1, i.e. no chunking of water physics - probably bad for performance...
	# But if this became a practical problem we could split up the water layer
	# based on whether it's placed somewhere where blocks can be pushed into it, or not.
	var coords := tile_map.get_coords_for_body_rid(body_rid)

	# This doesn't work because at the point when the 1×1px area in the centre of a block
	# travelling rightwards touches a block of water at (x, y),
	# its centre is still in tile (x - 1, y).
	# var coords := tile_map.local_to_map(tile_map.to_local(global_position))

	# Erase the water
	tile_map.set_cell(coords, -1)
	# Add foam
	foam.set_cell(coords, 2, Vector2i(0, 0))
	# Put a static copy of this block "into the water"
	submerged_blocks.set_cell(coords, 0, Vector2i(1, 0))
	# Free the physical block
	queue_free()
	# TODO: sound-effect
	# TODO: do this more convincingly!
