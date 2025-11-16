extends FillGameLogic
## Custom fill game logic for Wizzy Quest Combat
## Extiende la lógica base sin modificar el archivo original

# Sobrescribe variables exportadas si necesitas valores diferentes
@export var custom_barrels_to_win: int = 2
# @export var custom_intro_dialogue: DialogueResource

func _ready() -> void:
	# Puedes modificar valores antes de llamar al _ready() del padre
	barrels_to_win = custom_barrels_to_win
	
	super._ready()  # Llama al _ready() del padre
	
	# Código adicional después de la inicialización
	pass


# Sobrescribe la función para agregar el efecto de temblor a los enemigos
func _on_barrel_completed() -> void:
	# Hacer temblar a todos los enemigos cuando se completa un barril
	for enemy in get_tree().get_nodes_in_group("throwing_enemy"):
		if enemy.has_method("shake"):
			enemy.shake()
	
	super._on_barrel_completed()  # Llama a la lógica original
