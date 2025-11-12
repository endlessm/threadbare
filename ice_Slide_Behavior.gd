extends BaseCharacterBehavior

var is_sliding: bool = false
var slide_direction: Vector2 = Vector2.ZERO
@onready var originalSpeed = character.walk_speed
@onready var tile_map_layer: TileMapLayer = get_parent().get_parent().get_node("MapaHielo") # ajusta según tu estructura
@onready var hitbox:CollisionShape2D = character.get_node("CollisionShape2D")


func _physics_process(delta: float) -> void:
	if not character or Engine.is_editor_hint():
		return

	if is_sliding:
		character.moving_step = 0
		character.stopping_step = 0
		
		var slide_speed = character.walk_speed * 1.2
		var motion = slide_direction * slide_speed * delta
		var collision = character.move_and_collide(motion)
		
		if collision:
			is_sliding = false
			character.velocity = Vector2.ZERO
		else:
			_check_hielo()
	else:
		# Movimiento normal
		character.moving_step = 4000
		character.stopping_step = 1500
		if character.input_vector != Vector2.ZERO:
			_check_hielo()
	
func _check_hielo() -> void:
	if tile_map_layer == null:
		return
	var center = hitbox.global_position 
	var local_center = tile_map_layer.to_local(center)
	var tile_pos = tile_map_layer.local_to_map(local_center)
	var tile_id = tile_map_layer.get_cell_source_id(tile_pos)
	var data = tile_map_layer.get_cell_atlas_coords(tile_pos)
	
	if tile_id == 5 and data == Vector2i(0, 1):
		if not is_sliding:
			is_sliding = true
			slide_direction = character.input_vector.normalized()
	else:
		is_sliding = false		
		
func hieloAbajo() -> bool:
	if tile_map_layer == null:
		return false
	var center = hitbox.global_position 
	var local_center = tile_map_layer.to_local(center)
	var tile_pos = tile_map_layer.local_to_map(local_center)
	var tile_id = tile_map_layer.get_cell_source_id(tile_pos)
	var data = tile_map_layer.get_cell_atlas_coords(tile_pos)
	return tile_id == 5 and data == Vector2i(0, 1)
