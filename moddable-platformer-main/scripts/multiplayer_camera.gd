class_name MultiplayerCamera
extends Camera2D

const FRAME_MARGIN: int = 128
const MIN_ZOOM: float = 1.0
const MAX_ZOOM: float = 0.4

var player_characters: Array[Player]

@onready var viewport_size: Vector2 = get_viewport_rect().size


func _ready():
	if not enabled or not is_current():
		set_process(false)
		return

	for pc in get_tree().get_nodes_in_group("players"):
		player_characters.append(pc as Player)


func _physics_process(delta: float):
	if not player_characters:
		return

	var new_position: Vector2 = Vector2.ZERO
	for pc: Player in player_characters:
		new_position += pc.position
	new_position /= player_characters.size()
	if position_smoothing_enabled:
		position = lerp(position, new_position, position_smoothing_speed * delta)
	else:
		position = new_position

	var frame = Rect2(position, Vector2.ONE)
	for pc: Player in player_characters:
		frame = frame.expand(pc.position)
	frame = frame.grow_individual(FRAME_MARGIN, FRAME_MARGIN, FRAME_MARGIN, FRAME_MARGIN)

	var new_zoom: float
	if frame.size.x > frame.size.y * viewport_size.aspect():
		new_zoom = clamp(viewport_size.x / frame.size.x, MAX_ZOOM, MIN_ZOOM)
	else:
		new_zoom = clamp(viewport_size.y / frame.size.y, MAX_ZOOM, MIN_ZOOM)
	zoom = lerp(zoom, Vector2.ONE * new_zoom, 0.5)
