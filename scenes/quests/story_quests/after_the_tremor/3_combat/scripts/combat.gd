extends Node2D

@onready var boss = $Boss
@onready var boss_health = $BossHealth
@onready var collectible = $CollectibleItem

@onready var charlie = $PlayersContainer/charlie
@onready var bryan = $PlayersContainer/bryan

@onready var tile_grass = $TileMapLayers/Grass
@onready var tile_stones = $TileMapLayers/Stones2

@onready var music = $Music
@onready var win_sound = $WinSound 

func _ready():
	if collectible:
		collectible.revealed = false
		collectible.visible = false 
	
	if boss_health:
		boss_health.completed.connect(_on_boss_defeated)
	
	if boss:
		boss.start()
	
	if charlie: _setup_combat_player(charlie, "move_left")
	if bryan: _setup_combat_player(bryan, "move_right")
	
	if music and not music.playing:
		music.play()

func _setup_combat_player(p_node, action_name):
	p_node.walk_speed = 0.0
	p_node.run_speed = 0.0
	
	var fighting_comp = p_node.get_node_or_null("PlayerFighting")
	if fighting_comp:
		fighting_comp.input_action = action_name
	
	p_node.mode = p_node.Mode.FIGHTING
	
	var interaction = p_node.get_node_or_null("PlayerInteraction")
	if interaction:
		interaction.position = Vector2(99999, 99999)

func _on_boss_defeated():
	print("¡Nivel completado!")
	
	if music: music.stop()
	if win_sound: win_sound.play()
	if boss: boss.remove()
	
	if collectible:
		collectible.reveal()
		collectible.visible = true
	
	if tile_grass: tile_grass.modulate = Color.WHITE
	if tile_stones: tile_stones.modulate = Color.WHITE
	
	# --- ARREGLO DEL BUG DE CHARLIE ---
	if charlie:
		var fighting = charlie.get_node_or_null("PlayerFighting")
		if fighting:
			# 1. Cortamos el input (ya lo tenías)
			fighting.set_process_unhandled_input(false)
			
			# 2. ¡NUEVO! Forzamos el estado a "No peleando"
			# Esto corta el bucle de animación inmediatamente.
			fighting.is_fighting = false 
			
		# 3. ¡NUEVO! Forzamos al sprite a ponerse en reposo (Idle)
		# Buscamos el sprite directamente y le decimos "cálmate".
		# Normalmente el nombre es "PlayerSprite" o está en el AnimatedSprite2D.
		var sprite = charlie.get_node_or_null("PlayerSprite") # Intenta con este nombre
		if not sprite: sprite = charlie.get_node_or_null("%PlayerSprite") # O acceso único
		if not sprite: sprite = charlie.find_child("AnimatedSprite2D", true, false) # O búsqueda
		
		if sprite:
			sprite.play("idle")
			sprite.stop() # O stop para congelarlo totalmente si prefieres
	
	# Liberar a Bryan
	if bryan:
		bryan.walk_speed = 300.0
		bryan.run_speed = 500.0
		bryan.mode = bryan.Mode.COZY
		
		# También reseteamos su estado de pelea por si acaso
		var fighting = bryan.get_node_or_null("PlayerFighting")
		if fighting:
			fighting.set_process_unhandled_input(false)
			fighting.is_fighting = false # Preventivo
		
		var interaction = bryan.get_node_or_null("PlayerInteraction")
		if interaction:
			interaction.position = Vector2.ZERO
