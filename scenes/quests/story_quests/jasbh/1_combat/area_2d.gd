extends Area2D
@export var animacion: Node
@export var TiempoParaActivar: float = 2.0
@export var TiempoActivo: float = 1.5
@export var daño: int = 1
@export var hit: bool = false


var _state: String = "idle"
var _timer: float = 0.0

func _ready() -> void:
	monitoring = false
	$CollisionShape2D.disabled = true

func _process(delta: float) -> void:
	_timer += delta
	if _state == "idle":
		if _timer >= TiempoParaActivar:
			_activate()
	elif _state == "active":
		if _timer >= TiempoParaActivar + TiempoActivo:
			_deactivate()


func _activate() -> void:
	_state = "active"
	monitoring = true
	$CollisionShape2D.disabled = false
	print("🔴 Círculo activado y haciendo daño")
	# Aquí puedes poner animación, sonido o daño inicial si quieres
	
func _deactivate() -> void:
	_state = "done"
	monitoring = false
	$CollisionShape2D.disabled = true
	print("⚫ Círculo desactivado y eliminado")
	queue_free() # elimina el nodo del juego
	
