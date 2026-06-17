extends Node2D

@export var lifetime: float = 5.0

var velocidad: float = 200.0
var dano: int = 1
var direccion: Vector2 = Vector2.DOWN

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.set_meta("dano", dano)

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	global_position += direccion * velocidad * delta

func setup(pos: Vector2, dir: Vector2, nueva_velocidad: float, nuevo_dano: int) -> void:
	global_position = pos
	direccion = dir.normalized()
	velocidad = nueva_velocidad
	dano = nuevo_dano

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		queue_free()
