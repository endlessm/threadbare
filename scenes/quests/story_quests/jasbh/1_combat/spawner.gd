extends Node2D

@export var circle_scene: PackedScene          # arrastra aquí tu Circle.tscn en el Inspector
@export var player_nodepath: NodePath          # arrastra el nodo del jugador aquí
@export var spawn_interval: float = 5.0        # intervalo en segundos

var _player_node: Node2D = null
var _timer: Timer
var activo: bool = false                       # controla si debe spawnear o no

func _ready() -> void:
	_player_node = get_node(player_nodepath)

	# Crear el temporizador (no autoinicia)
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	add_child(_timer)
	_timer.connect("timeout", Callable(self, "_on_spawn_timeout"))

# 🔹 llamado desde CameraZone cuando el jugador entra
func start_spawning() -> void:
	if activo:
		return
	activo = true
	_timer.start()

# 🔹 llamado desde CameraZone cuando el jugador sale
func stop_spawning() -> void:
	if not activo:
		return
	activo = false
	_timer.stop()

func _on_spawn_timeout() -> void:
	if not activo:
		return
	if not _player_node or not circle_scene:
		return

	# Instanciar el círculo
	var circle_instance = circle_scene.instantiate()

	# Colocarlo justo donde está el jugador
	circle_instance.global_position = _player_node.global_position

	# Añadirlo a la escena
	get_tree().current_scene.add_child(circle_instance)
