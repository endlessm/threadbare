extends Node

# Variables exportadas
@export var collectible_item: Node2D
@export var show_debug_messages: bool = true

var total_minerals = 3  # Exactamente 3 items
var minerals_collected = 0

func _ready():
	# Ocultar el CollectibleItem al inicio
	if collectible_item:
		collectible_item.visible = false
		if collectible_item.has_node("CollisionShape2D"):
			collectible_item.get_node("CollisionShape2D").disabled = true
		
		if show_debug_messages:
			print("CollectibleItem ocultado al inicio")
	else:
		push_warning("¡No se asignó CollectibleItem en el Inspector!")
	
	await get_tree().process_frame
	register_all_minerals()

func register_all_minerals():
	var minerals = get_tree().get_nodes_in_group("Mineral")
	total_minerals = minerals.size()
	
	if show_debug_messages:
		print("Total de minerales: ", total_minerals)
	
	for mineral in minerals:
		if mineral.has_signal("mineral_collected"):
			mineral.mineral_collected.connect(_on_mineral_collected)

func _on_mineral_collected():
	minerals_collected += 1
	
	if show_debug_messages:
		print("Minerales recolectados: %d/%d" % [minerals_collected, total_minerals])
	
	if minerals_collected >= total_minerals:
		show_collectible_item()

func show_collectible_item():
	if collectible_item:
		collectible_item.visible = true
		
		if collectible_item.has_node("CollisionShape2D"):
			collectible_item.get_node("CollisionShape2D").disabled = false
		
		if show_debug_messages:
			print("¡Todos los minerales recolectados! CollectibleItem visible")
