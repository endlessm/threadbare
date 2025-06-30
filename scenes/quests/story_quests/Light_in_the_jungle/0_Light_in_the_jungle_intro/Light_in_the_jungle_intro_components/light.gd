# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends PointLight2D

@warning_ignore("unused_private_class_variable")
@export_tool_button("Generate sibling collision shape")
var _generate_collision_shape := generate_collision_shape
@export var debug_view: bool = false:
	set = set_debug_view

# Propiedades del efecto de fogata
@export_group("Firelight Effect")
@export var enable_firelight_animation: bool = true
@export_enum("campfire", "torch", "candle", "bonfire", "dying_ember", "custom") var firelight_preset: String = "campfire"
@export var base_energy: float = 2.0:  # Energía base de la luz
	set(value):
		base_energy = clamp(value, 0.0, 2.0)  # Limitar entre 0 y 2
@export var energy_variation: float = 0.3  # Variación de la energía (0.0 - 1.0)
@export var base_texture_scale: float = 1.0  # Escala base de la textura
@export var scale_variation: float = 0.2  # Variación de escala (0.0 - 1.0)
@export var flicker_speed: float = 2.0  # Velocidad del parpadeo
@export var use_circular_texture: bool = true  # Usar textura circular

var debug_sprite_2d: Sprite2D
var time_passed: float = 0.0
var original_energy: float
var original_texture_scale: float


func _ready() -> void:
	toggle_debug_sprite_2d(debug_view)
	
	# Configurar la luz circular para fogata
	if use_circular_texture:
		setup_circular_light()
	
	# Guardar valores originales
	original_energy = energy if base_energy == 0.0 else base_energy
	original_texture_scale = texture_scale if base_texture_scale == 0.0 else base_texture_scale
	
	# Establecer valores base
	energy = original_energy
	texture_scale = original_texture_scale
	
	# Aplicar preset de fogata seleccionado si está habilitada la animación
	if enable_firelight_animation and firelight_preset != "custom":
		set_firelight_preset(firelight_preset)


func set_debug_view(new_value: bool) -> void:
	debug_view = new_value
	if is_inside_tree():
		toggle_debug_sprite_2d(debug_view)


func toggle_debug_sprite_2d(should_show: bool) -> void:
	if not Engine.is_editor_hint():
		return
	if should_show:
		if not debug_sprite_2d:
			debug_sprite_2d = Sprite2D.new()
			add_child(debug_sprite_2d)
	else:
		if debug_sprite_2d:
			debug_sprite_2d.queue_free()


func setup_circular_light() -> void:
	# Crear una textura circular suave si no existe una
	if not texture:
		var size = 256
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(size / 2, size / 2)
		var max_radius = size / 2.0
		
		for x in range(size):
			for y in range(size):
				var pos = Vector2(x, y)
				var distance = pos.distance_to(center)
				var alpha = 1.0 - smoothstep(0.0, max_radius, distance)
				
				# Crear gradiente suave con colores cálidos de fogata
				var warmth = 1.0 - (distance / max_radius)
				var red = 1.0
				var green = 0.6 + (0.4 * warmth)
				var blue = 0.2 + (0.3 * warmth)
				
				image.set_pixel(x, y, Color(red, green, blue, alpha))
		
		var texture_resource = ImageTexture.new()
		texture_resource.set_image(image)
		texture = texture_resource


func generate_collision_shape() -> void:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image(), 0.6)
	bitmap.resize(Vector2(bitmap.get_size()) * scale * texture_scale)
	var polygons := bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), bitmap.get_size()))
	for polygon: PackedVector2Array in polygons:
		var collider := CollisionPolygon2D.new()
		collider.polygon = polygon
		get_parent().add_child(collider, true)
		collider.owner = owner


func _process(delta: float) -> void:
	# Animación de fogata (funciona tanto en editor como en juego)
	if enable_firelight_animation:
		animate_firelight(delta)
	
	# Debug sprite (solo en editor)
	if not Engine.is_editor_hint():
		return
	if debug_sprite_2d:
		debug_sprite_2d.texture = texture
		debug_sprite_2d.offset = offset


func animate_firelight(delta: float) -> void:
	time_passed += delta * flicker_speed
	
	# Crear variaciones usando múltiples ondas senoidales para un efecto más orgánico
	var flicker1 = sin(time_passed * 3.0) * 0.5 + 0.5
	var flicker2 = sin(time_passed * 5.7) * 0.5 + 0.5
	var flicker3 = sin(time_passed * 2.3) * 0.5 + 0.5
	
	# Combinar las ondas para crear un patrón más complejo
	var combined_flicker = (flicker1 * 0.5) + (flicker2 * 0.3) + (flicker3 * 0.2)
	
	# Aplicar variación de energía (intensidad de la luz)
	var energy_offset = (combined_flicker - 0.5) * energy_variation
	energy = original_energy + energy_offset
	
	# Aplicar variación de escala (tamaño del área iluminada)
	var scale_offset = (combined_flicker - 0.5) * scale_variation
	texture_scale = original_texture_scale + scale_offset
	
	# Asegurar que los valores estén en rangos válidos
	energy = max(energy, 0.2)  # Energía máxima de 2.0
	texture_scale = max(texture_scale, 0.1)


# Funciones adicionales para controlar la animación
func reset_firelight_animation() -> void:
	"""Reinicia la animación de fogata"""
	time_passed = 0.0
	energy = original_energy
	texture_scale = original_texture_scale


func set_firelight_intensity(intensity: float) -> void:
	"""Establece la intensidad base de la fogata (0.0 - 2.0)"""
	base_energy = clamp(intensity, 0.0, 2.0)
	original_energy = base_energy
	

func set_firelight_variation(variation: float) -> void:
	"""Establece qué tanto varía la fogata (0.0 - 1.0)"""
	energy_variation = clamp(variation, 0.0, 1.0)
	scale_variation = clamp(variation * 0.5, 0.0, 0.5)  # La escala varía menos que la energía


func set_firelight_speed(speed: float) -> void:
	"""Establece la velocidad del parpadeo (0.1 - 10.0)"""
	flicker_speed = clamp(speed, 0.1, 10.0)


# Función para crear diferentes tipos de fuego
func set_firelight_preset(preset_name: String) -> void:
	"""Aplica presets predefinidos para diferentes tipos de fuego"""
	match preset_name.to_lower():
		"campfire":
			set_firelight_intensity(1.3)
			set_firelight_variation(0.3)
			set_firelight_speed(2.0)
		"torch":
			set_firelight_intensity(1.2)
			set_firelight_variation(0.4)
			set_firelight_speed(3.0)
		"candle":
			set_firelight_intensity(0.5)
			set_firelight_variation(0.2)
			set_firelight_speed(1.5)
		"bonfire":
			set_firelight_intensity(1.5)
			set_firelight_variation(0.5)
			set_firelight_speed(1.5)
		"dying_ember":
			set_firelight_intensity(0.3)
			set_firelight_variation(0.6)
			set_firelight_speed(0.8)


# Inicio Aleatorio 
