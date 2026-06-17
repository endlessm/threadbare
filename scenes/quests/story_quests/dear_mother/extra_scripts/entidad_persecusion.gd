extends Area2D

## Ajustar velocidad
@export var velocidad: float = 80.0 

@export var objetivo_path: NodePath 
var jugador: Node2D

func _ready() -> void:
	# Buscamos al jugador al iniciar la escena
	if objetivo_path:
		jugador = get_node(objetivo_path)

func _process(delta: float) -> void:
	if jugador:
		# Calculamos la dirección hacia donde está el jugador en este instante
		@warning_ignore("untyped_declaration")
		var direccion = global_position.direction_to(jugador.global_position)
		
		# Movemos la entidad en esa dirección constantemente
		global_position += direccion * velocidad * delta

# Conecta esta función usando la pestaña "Señales" del Area2D -> body_entered
func _on_body_entered(body: Node2D) -> void:
	# Si lo que chocó con la entidad fue el jugador:
	if body.name == "Player" or body.name == "Character":
		# Reiniciamos la escena actual desde cero
		get_tree().call_deferred("reload_current_scene")
