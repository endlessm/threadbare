extends Area2D

@export var velocidad := 500
@export var daño := 3
@export var tilemap_paredes: TileMap  # TileMap asignado desde el editor

var direccion := Vector2.ZERO

@onready var detector = $detector

func _ready():
	detector.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	if direccion != Vector2.ZERO:
		position += direccion * velocidad * delta

		# Verificar colisión con tilemap
		if tilemap_paredes:
			var celda = tilemap_paredes.local_to_map(global_position)
			if tilemap_paredes.get_cell_source_id(0, celda) != -1:
				print("Bala impactó contra pared en celda ", celda)
				queue_free()

func _on_body_entered(body):
	if body.has_method("recibir_daño"):
		body.recibir_daño(daño)
	queue_free()
