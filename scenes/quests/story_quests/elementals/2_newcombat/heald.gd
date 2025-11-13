extends Control

# --- Arrastra tus texturas aquí (igual que antes) ---
@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D

# --- Referencia al jugador (igual que antes) ---
var player

# --- Variable para guardar nuestros corazones ---
# (Array[TextureRect] significa que solo guardará nodos TextureRect)
@onready var heart_nodes: Array[TextureRect] = []

func _ready():
	# --- 1. Encontrar y guardar los corazones ---
	# Recorremos todos los hijos del nodo "Hearts"
	for heart in $Hearts.get_children():
		# Nos aseguramos de que sea un TextureRect
		if heart is TextureRect:
			# Lo añadimos a nuestra lista
			heart_nodes.append(heart)

	# --- 2. Conectarse al jugador (igual que antes) ---
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("ERROR en HealthUI: No se encontró al jugador.")
		return 

	player.health_changed.connect(update_hearts)
	
	# --- 3. Dibujo inicial (igual que antes) ---
	update_hearts(player.current_health_halves)


# --- 4. La nueva función de dibujo ---
func update_hearts(current_health_halves):
	
	# Obtenemos la vida máxima (ej. 3 contenedores = 6 mitades)
	var max_halves = player.max_health_halves
	var total_containers = max_halves / 2

	# --- Recorremos los corazones que ENCONTRAMOS (Heart1, Heart2, etc.) ---
	for i in range(heart_nodes.size()):
		
		var heart_ui = heart_nodes[i] # Obtenemos Heart1, luego Heart2, etc.

		# --- ¿Este corazón debe estar visible? ---
		# Si 'i' (0, 1, 2...) es menor que el total (ej. 3)
		if i < total_containers:
			
			heart_ui.visible = true # ¡Muéstralo!

			# --- Misma lógica de antes para cambiar la textura ---
			var heart_value = current_health_halves - (i * 2)
			
			if heart_value >= 2:
				heart_ui.texture = heart_full
			elif heart_value == 1:
				heart_ui.texture = heart_half
			else:
				heart_ui.texture = heart_empty
		
		else:
			# Si el jugador solo tiene 3 corazones (total_containers = 3)
			# pero este es Heart4 (i = 3), lo ocultamos.
			heart_ui.visible = false
