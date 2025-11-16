extends "res://scenes/game_elements/characters/player/components/player.gd"

## Custom player for Wizzy Quest
## Modifica atributos específicos del jugador sin tocar el Player base

# Sobrescribe atributos si lo necesitas
@export var custom_scale: Vector2 = Vector2(0.8, 0.8)
@export var custom_position: Vector2 = Vector2.ZERO  # Posición inicial (0,0 = sin cambio)
# @export var custom_speed: float = 150.0

func _ready() -> void:
	super._ready()  # Llama al _ready() del padre
	
	# Modifica el scale sin afectar al Player original
	scale = custom_scale
	
	# Modifica la posición si custom_position no es Vector2.ZERO
	if custom_position != Vector2.ZERO:
		position = custom_position
	
	print("Wizzy Player listo - modo: ", mode)

# Sobrescribe funciones específicas solo si necesitas cambiar comportamiento
# func take_damage(amount: int) -> void:
# 	super.take_damage(amount)
# 	# código adicional aquí
# 	pass
