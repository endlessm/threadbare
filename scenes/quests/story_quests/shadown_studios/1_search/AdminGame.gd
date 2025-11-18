extends Node

# Variables exportadas para configurar desde el Inspector
@export var collectible_item: Node2D  # Arrastra aquí el nodo CollectibleItem
@export var show_debug_messages: bool = true

# Total de minerales en el nivel
var total_minerals = 0
var minerals_collected = 0

func _ready():
	# Ocultar el CollectibleItem al inicio
	if collectible_item:
		collectible_item.visible = false
		# También deshabilitar colisiones mientras está invisible
		if collectible_item.has_node("CollisionShape2D"):
			collectible_item.get_node("CollisionShape2D").disabled = true
		
		if show_debug_messages:
			print("CollectibleItem ocultado al inicio")
	else:
		push_warning("¡No se asignó CollectibleItem en el Inspector!")
	
	# Esperar un frame para asegurar que todos los nodos estén listos
	await get_tree().process_frame
	
	# Contar y registrar todos los minerales
	register_all_minerals()

func register_all_minerals():
	# Obtener todos los nodos del grupo "Mineral"
	var minerals = get_tree().get_nodes_in_group("Mineral")
	total_minerals = minerals.size()
	
	if show_debug_messages:
		print("Total de minerales en el nivel: ", total_minerals)
	
	if total_minerals == 0:
		push_warning("No se encontraron minerales en el grupo 'Mineral'")
		return
	
	# Conectar la señal de cada mineral
	for mineral in minerals:
		if mineral.has_signal("mineral_collected"):
			mineral.mineral_collected.connect(_on_mineral_collected)

func _on_mineral_collected():
	minerals_collected += 1
	
	if show_debug_messages:
		print("Minerales recolectados: %d/%d" % [minerals_collected, total_minerals])
	
	# Verificar si se recolectaron todos
	if minerals_collected >= total_minerals:
		show_collectible_item()

func show_collectible_item():
	if collectible_item:
		collectible_item.visible = true
		
		# Habilitar colisiones
		if collectible_item.has_node("CollisionShape2D"):
			collectible_item.get_node("CollisionShape2D").disabled = false
		
		if show_debug_messages:
			print("¡Todos los minerales recolectados! CollectibleItem ahora visible")
		
		# Opcional: Efecto visual o sonido
		if collectible_item.has_node("AnimationPlayer"):
			collectible_item.get_node("AnimationPlayer").play("appear")
