extends Node2D

@export var tiempo_carga: float = 1.0
@export var duracion: float = 0.5

var dano: int = 1
var direccion: Vector2 = Vector2.RIGHT

@onready var hitbox: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var activo: bool = false

func _ready() -> void:
	hitbox.set_meta("dano", dano)
	hitbox.monitoring = false

	rotation = direccion.angle()

	sprite.play("carga")

	await get_tree().create_timer(tiempo_carga).timeout
	
	activo = true
	hitbox.monitoring = true
	sprite.play("disparo")

	await get_tree().create_timer(duracion).timeout
	
	queue_free()


func setup(pos: Vector2, dir: Vector2, nueva_carga: float, nueva_duracion: float) -> void:
	global_position = pos
	direccion = dir.normalized()
	dano = dano
	tiempo_carga = nueva_carga
	duracion = nueva_duracion


func _on_Area2D_area_entered(area: Area2D) -> void:
	if activo and area.is_in_group("player_hitbox"):
		pass
