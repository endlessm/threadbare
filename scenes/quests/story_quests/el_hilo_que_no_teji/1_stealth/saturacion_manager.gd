# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var material_mundo: ShaderMaterial
@export var material_jugador: ShaderMaterial

func _ready() -> void:
	if material_mundo:
		_aplicar_material_al_mundo(get_tree().current_scene)

func _aplicar_material_al_mundo(nodo: Node) -> void:
	# 1. EXCEPCIONES: Si el nodo es Lino, o tiene la etiqueta de ignorar (como el Vacío), lo saltamos por completo.
	if nodo.is_in_group("player") or nodo.is_in_group("ignorar_shader"):
		return
		
	# 2. Inyectamos el material al resto de cosas visuales
	if nodo is TileMapLayer or nodo is Sprite2D or nodo is AnimatedSprite2D:
		# Verificamos si el nodo ya tenía un material propio importante para no sobreescribirlo por error
		# (Opcional: Si tienes otros shaders importantes en el futuro, este paso ayuda a no romperlos)
		nodo.material = material_mundo
		
	# 3. Recursividad
	for hijo in nodo.get_children():
		_aplicar_material_al_mundo(hijo)

func _process(_delta: float) -> void:
	# Actualizamos los porcentajes en tiempo real
	if material_mundo:
		var sat_mundo = ElHiloQueNoTejiState.world_saturation / 100.0
		material_mundo.set_shader_parameter("saturation", sat_mundo)
		
		# NUEVA LÍNEA: Aplicamos el factor de oscuridad al material del mundo
		# 0.60 reducirá el brillo general un 40%. Ajusta este número a tu gusto.
		material_mundo.set_shader_parameter("darkness_factor", 0.60)
		
	if material_jugador:
		var sat_lino = ElHiloQueNoTejiState.player_saturation / 100.0
		material_jugador.set_shader_parameter("saturation", sat_lino)
		
		# OPCIONAL: Si quieres que el jugador conserve su brillo original 
		# para que resalte en el mapa oscuro, déjalo en 1.0. 
		# Si quieres que se oscurezca igual que el mundo, ponle 0.60.
		material_jugador.set_shader_parameter("darkness_factor", 1.0)
		
