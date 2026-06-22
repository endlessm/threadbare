extends Node

@export var max_proyectiles: int = 3

var proyectiles_recibidos: int = 0 
var esta_derrotado: bool = false

@onready var player: Player = get_parent() as Player

func _on_hit_box_body_entered(body: Node2D) -> void:
	if esta_derrotado:
		return
		
	if body is Projectile:
		proyectiles_recibidos += 1
		print("¡Impacto registrado! Llevas: ", proyectiles_recibidos, " de ", max_proyectiles)
		
		if proyectiles_recibidos >= max_proyectiles:
			esta_derrotado = true
			if player and player.has_method("defeat"):
				player.defeat()
