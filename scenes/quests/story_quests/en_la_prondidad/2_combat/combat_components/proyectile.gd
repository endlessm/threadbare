extends Node2D
@export var lifetime: float = 5.0

var velocidad: float = 200.0
var dano: int = 1
var direccion: Vector2 = Vector2.DOWN
var activo: bool = false

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.set_meta("dano", dano)

func _process(delta: float) -> void:
	if activo:
		global_position += direccion * velocidad * delta

func setup(pos: Vector2) -> void:
	global_position = pos

func activar_movimiento(dir: Vector2, nueva_velocidad: float, nuevo_dano: int) -> void:
	direccion = dir.normalized()
	velocidad = nueva_velocidad
	dano = nuevo_dano
	
	if is_inside_tree() and hitbox:
		hitbox.set_meta("dano", dano)
		
	rotation = direccion.angle() + PI / 2 + PI
	activo = true
	
	comenzar_lifetime()

func comenzar_lifetime() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		queue_free()
