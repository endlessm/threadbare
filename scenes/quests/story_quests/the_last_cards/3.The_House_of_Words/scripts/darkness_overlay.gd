extends ColorRect

var player: Node2D = null
var lantern_area: Node2D = null

func _ready() -> void:
	# Forzar que cubra exactamente la pantalla
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("DetectionArea"):
		lantern_area = player.get_node("DetectionArea")

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	if not material or not material is ShaderMaterial:
		return

	# Obtener la cámara activa para convertir posición mundial a pantalla
	var camera = get_viewport().get_camera_2d()
	var screen_size = get_viewport_rect().size
	
	var player_screen_pos: Vector2
	if camera:
		# Convertir posición mundial del player a posición en pantalla
		var player_world_pos = player.global_position
		var canvas_transform = get_viewport().get_canvas_transform()
		player_screen_pos = canvas_transform * player_world_pos
	else:
		player_screen_pos = player.get_global_transform_with_canvas().origin
	
	var uv_pos = Vector2(
		player_screen_pos.x / screen_size.x,
		player_screen_pos.y / screen_size.y
	)

	material.set_shader_parameter("light_pos", uv_pos)

	if lantern_area:
		material.set_shader_parameter("cone_direction", lantern_area.rotation)
