extends Area2D
class_name CameraZone

@export var player_node: NodePath = NodePath("")   # arrastra tu Player aquí
@export var camera_node: NodePath = NodePath("")   # arrastra la Camera2D que quieres activar
@export var spawner_node: NodePath = NodePath("")  # arrastra tu Spawner (opcional)

var _zone_camera: Camera2D
var _previous_camera: Camera2D
var _spawner: Node

func _ready() -> void:
	# resolución estricta: depende de que arrastres rutas válidas en el Inspector
	_zone_camera = get_node(camera_node)           # error si no asignaste: intencional (modo estricto)
	_spawner = get_node_or_null(spawner_node)     # opcional: puede ser null

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	# solo reaccionar si entra exactamente el nodo Player que arrastraste
	if body != get_node(player_node):
		return

	_previous_camera = get_viewport().get_camera_2d()
	_zone_camera.make_current()

	# activar spawner: asume que el spawner tiene start_spawning()
	if _spawner:
		_spawner.call("start_spawning")

func _on_body_exited(body: Node) -> void:
	if body != get_node(player_node):
		return

	# restaurar cámara previa si existe y es válida
	if _previous_camera and is_instance_valid(_previous_camera):
		_previous_camera.make_current()

	# desactivar spawner: asume que el spawner tiene stop_spawning()
	if _spawner:
		_spawner.call("stop_spawning")
