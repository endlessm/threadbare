extends CanvasLayer

@onready var barra_vida: Control = $barra_vida
@export var player_path: NodePath

var player: Player

func _ready():
	if player_path:
		player = get_node(player_path)
	if barra_vida and player:
		barra_vida.init_health(player.max_hp)
		barra_vida.update_health(player.hp)

func _process(_delta):
	if not barra_vida or not player or not is_instance_valid(player):
		return

	var cam := get_viewport().get_camera_2d()
	if not cam:
		return

	# Posición en pantalla usando la transformación de la cámara
	var screen_pos := cam.get_canvas_transform() * player.global_position

	# Ajuste para que la barra quede centrada sobre la cabeza
	var offset := Vector2(-barra_vida.size.x / 2.0, -60.0)
	barra_vida.position = screen_pos + offset

	# Actualizar el valor de la barra cada frame (puedes optimizarlo con señales)
	barra_vida.update_health(player.hp)
