extends CharacterBody2D
class_name Zombie

## Señal que se emite cuando el zombi alcanza al player.
## Room1.gd (o cualquier escena que lo use) se conecta a esta señal,
## igual que ya hace con los Guard.
signal player_detected(player_node: Node2D)

@export_group("Movimiento")
## Velocidad de desplazamiento del zombi (patrullando o persiguiendo).
@export var speed: float = 40.0
## Distancia a la que el zombi detecta al player y empieza a perseguirlo.
@export var detection_radius: float = 200.0
## Distancia a la que se considera que el zombi "atrapó" al player.
@export var kill_distance: float = 80.0
## Tiempo mínimo/máximo (segundos) entre cambios de dirección al patrullar.
@export var direction_change_min_time: float = 1.5
@export var direction_change_max_time: float = 3.5

@export_group("Área de patrullaje")
## Límite superior-izquierdo de la sala donde puede moverse el zombi.
@export var patrol_min: Vector2 = Vector2(0, 0)
## Límite inferior-derecho de la sala donde puede moverse el zombi.
@export var patrol_max: Vector2 = Vector2(1200, 700)

@export_group("Referencias")
## Opcional: si se deja vacío, el zombi busca automáticamente
## un nodo en el grupo "player".
@export var player_path: NodePath

var player: Node2D = null
var activo: bool = true

var _direccion: Vector2 = Vector2.RIGHT
var _detecta_player: bool = false
var _cambio_dir_timer: float = 0.0


func _ready() -> void:
	randomize()
	_direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_buscar_player()
	print("Zombi -> player encontrado: ", player)


func _buscar_player() -> void:
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		print("Zombi -> player encontrado: ", player)


## Permite que la escena que instancia al zombi le asigne el player manualmente
## (útil si no quieres depender del grupo "player").
func set_player(nuevo_player: Node2D) -> void:
	player = nuevo_player


## Permite pausar/reanudar el movimiento del zombi desde fuera
func set_activo(valor: bool) -> void:
	activo = valor
	print("Zombie activo = ", activo)


func _process(delta: float) -> void:
	if not activo or not player:
		return
	_mover(delta)


func _mover(delta: float) -> void:
	var distancia = global_position.distance_to(player.global_position)

	if distancia < detection_radius:
		# Perseguir al player
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * speed * delta
		_detecta_player = true
	else:
		# Patrullar dentro de los límites
		_detecta_player = false
		_cambio_dir_timer -= delta
		if _cambio_dir_timer <= 0:
			_cambio_dir_timer = randf_range(direction_change_min_time, direction_change_max_time)
			_direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

		global_position += _direccion * speed * delta

		# Rebotar en los límites de la sala
		if global_position.x < patrol_min.x or global_position.x > patrol_max.x:
			_direccion.x = -_direccion.x
			global_position.x = clamp(global_position.x, patrol_min.x, patrol_max.x)
		if global_position.y < patrol_min.y or global_position.y > patrol_max.y:
			_direccion.y = -_direccion.y
			global_position.y = clamp(global_position.y, patrol_min.y, patrol_max.y)

	# Game over si toca al player
	if distancia < kill_distance:
		player_detected.emit(player)
