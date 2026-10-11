# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Retejido
extends RefCounted
## Hace aparecer o desaparecer una capa de tiles con el efecto de retejido.

## world_rewoven.gdshader
const SHADER: Shader = preload("uid://dui35fhf12sp5")
## fabric_texture.png
const TRAMA_DE_TELA: Texture2D = preload("uid://drlsbgxh5e6vv")
const DURACION: float = 3.0
const DURACION_BREVE: float = 0.5
const META_TINTE: StringName = &"retejido_tinte_original"
const RAIZ_DEL_QUEST: String = "res://scenes/quests/story_quests/el_hilo_que_no_teji/"
const CARPETA_SONIDOS: String = RAIZ_DEL_QUEST + "shared/assets/sounds/enviroment/"
const RUTA_SONIDO_TABLON: String = CARPETA_SONIDOS + "puente_tablon.wav"
const RUTA_SONIDO_CAIDA: String = CARPETA_SONIDOS + "puente_cae.wav"
const VOLUMEN_TABLON_DB: float = -7.0
const TONO_TABLON := Vector2(0.92, 1.08)
const DISTANCIA_MAXIMA_DEL_SONIDO: float = 4000.0
const ESTIRAMIENTO_DEL_SHADER: float = 1.15
const RETRASO_PRIMERA_FRANJA: float = 0.08
const LADO_DE_LA_MASCARA: int = 64
const LARGO_MASCARA_ESCALONADA: int = 512
const ANCHO_MASCARA_ESCALONADA: int = 4


static func aparecer(capa: TileMapLayer, duracion: float = DURACION) -> void:
	if not is_instance_valid(capa):
		return
	var material_original := capa.material
	var material := _crear_material(capa, 0.0)
	_mostrar_con(capa, material, _mascara_en_direccion(-_avance_natural(capa)))
	var tenia_colision := capa.collision_enabled
	capa.collision_enabled = false

	var animacion := capa.create_tween()
	animacion.tween_property(material, "shader_parameter/progress", 0.5, duracion / 2.0)
	animacion.tween_callback(func() -> void: capa.collision_enabled = tenia_colision)
	animacion.tween_property(material, "shader_parameter/progress", 1.0, duracion / 2.0)
	animacion.tween_callback(_devolver_material.bind(capa, material_original))


static func desaparecer(
	capa: TileMapLayer, borrar: bool = false, duracion: float = DURACION
) -> void:
	if not is_instance_valid(capa):
		return
	var material_original := capa.material
	var material := _crear_material(capa, 1.0)
	capa.material = material

	var animacion := capa.create_tween()
	animacion.tween_property(material, "shader_parameter/progress", 0.5, duracion / 2.0)
	animacion.tween_callback(func() -> void: capa.collision_enabled = false)
	animacion.tween_property(material, "shader_parameter/progress", 0.0, duracion / 2.0)
	if borrar:
		animacion.tween_callback(capa.queue_free)
	else:
		animacion.tween_callback(
			func() -> void:
				capa.enabled = false
				capa.hide()
				_devolver_material(capa, material_original)
		)


static func tejer_por_franjas(capa: TileMapLayer, duracion: float = DURACION) -> void:
	if not is_instance_valid(capa):
		return
	var avance := _avance_natural(capa)
	var franjas := _franjas(capa, avance)
	var cantidad := maxi(franjas.size(), 1)
	var material_original := capa.material
	var material := _crear_material(capa, 0.0)
	_mostrar_con(capa, material, _mascara_escalonada(-avance, cantidad))

	var tejido := capa.create_tween()
	tejido.tween_property(material, "shader_parameter/progress", 1.0, duracion)
	tejido.tween_callback(_devolver_material.bind(capa, material_original))

	var primera := _momento_de_franja(0, cantidad, duracion)
	var pausa := _momento_de_franja(1, cantidad, duracion) - primera
	await capa.get_tree().create_timer(primera).timeout
	for franja in franjas:
		if not is_instance_valid(capa):
			return
		_sonar_tablon(capa, franja)
		await capa.get_tree().create_timer(pausa).timeout
	if tejido.is_valid() and tejido.is_running():
		await tejido.finished


static func momento_en_que_aparecen(
	capa: TileMapLayer, celdas: Array[Vector2i], duracion: float = DURACION
) -> float:
	var franjas := _franjas(capa, _avance_natural(capa))
	for indice in franjas.size():
		for celda in franjas[indice]:
			if celda in celdas:
				return _momento_de_franja(indice, franjas.size(), duracion)
	return duracion


static func _momento_de_franja(indice: int, cantidad: int, duracion: float) -> float:
	var avance := float(indice) / maxf(float(cantidad - 1), 1.0)
	return duracion * (avance + RETRASO_PRIMERA_FRANJA) / ESTIRAMIENTO_DEL_SHADER


static func _mascara_escalonada(hacia_lo_blanco: Vector2, cantidad: int) -> GradientTexture2D:
	var posiciones := PackedFloat32Array()
	var colores := PackedColorArray()
	for i in cantidad:
		var gris := float(i) / maxf(float(cantidad - 1), 1.0)
		posiciones.append(float(i) / float(cantidad))
		colores.append(Color(gris, gris, gris))
	var degradado := Gradient.new()
	degradado.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	degradado.offsets = posiciones
	degradado.colors = colores
	var direccion := hacia_lo_blanco.normalized()
	var mascara := GradientTexture2D.new()
	mascara.gradient = degradado
	var horizontal := absf(direccion.x) > absf(direccion.y)
	mascara.width = LARGO_MASCARA_ESCALONADA if horizontal else ANCHO_MASCARA_ESCALONADA
	mascara.height = ANCHO_MASCARA_ESCALONADA if horizontal else LARGO_MASCARA_ESCALONADA
	mascara.fill_from = Vector2(0.5, 0.5) - direccion * 0.5
	mascara.fill_to = Vector2(0.5, 0.5) + direccion * 0.5
	return mascara


static func deshacer_por_franjas(capa: TileMapLayer, duracion: float, avance: Vector2) -> void:
	if not is_instance_valid(capa):
		return
	var direccion := Vector2.DOWN if absf(avance.y) >= absf(avance.x) else Vector2.RIGHT
	if avance.dot(direccion) < 0.0:
		direccion = -direccion
	var franjas := _franjas(capa, direccion)
	var celdas := _guardar_celdas(capa)

	var pausa := duracion / maxf(float(franjas.size()), 1.0)
	for franja in franjas:
		for celda in franja:
			capa.erase_cell(celda)
		_sonar_tablon(capa, franja)
		await capa.get_tree().create_timer(pausa).timeout
		if not is_instance_valid(capa):
			return

	capa.enabled = false
	capa.hide()
	_restaurar_celdas(capa, celdas)


static func _franjas(capa: TileMapLayer, avance: Vector2) -> Array:
	var por_vertical := absf(avance.y) >= absf(avance.x)
	var grupos: Dictionary = {}
	for celda in capa.get_used_cells():
		var clave: int = celda.y if por_vertical else celda.x
		if not grupos.has(clave):
			grupos[clave] = []
		grupos[clave].append(celda)
	var claves := grupos.keys()
	claves.sort()
	if (avance.y if por_vertical else avance.x) < 0.0:
		claves.reverse()
	var franjas: Array = []
	for clave in claves:
		franjas.append(grupos[clave])
	return franjas


static func _guardar_celdas(capa: TileMapLayer) -> Dictionary:
	var celdas: Dictionary = {}
	for celda in capa.get_used_cells():
		celdas[celda] = [
			capa.get_cell_source_id(celda),
			capa.get_cell_atlas_coords(celda),
			capa.get_cell_alternative_tile(celda),
		]
	return celdas


static func _restaurar_celdas(capa: TileMapLayer, celdas: Dictionary) -> void:
	for celda in celdas:
		var datos: Array = celdas[celda]
		capa.set_cell(celda, datos[0], datos[1], datos[2])


static func _sonar_tablon(capa: TileMapLayer, franja: Array) -> void:
	if franja.is_empty():
		return
	var sonido := _crear_sonido(capa, RUTA_SONIDO_TABLON)
	if not sonido:
		return
	sonido.pitch_scale = randf_range(TONO_TABLON.x, TONO_TABLON.y)
	sonido.volume_db = VOLUMEN_TABLON_DB
	sonido.global_position = capa.to_global(capa.map_to_local(franja[franja.size() / 2]))
	sonido.play()


static func sonar_caida(capa: TileMapLayer) -> void:
	if not is_instance_valid(capa):
		return
	var sonido := _crear_sonido(capa, RUTA_SONIDO_CAIDA)
	if not sonido:
		return
	sonido.global_position = TileMapMaskBounds.get_world_bounds(capa).get_center()
	sonido.play()


static func _crear_sonido(capa: TileMapLayer, ruta: String) -> AudioStreamPlayer2D:
	if not ResourceLoader.exists(ruta):
		return null
	var sonido := AudioStreamPlayer2D.new()
	sonido.stream = load(ruta)
	sonido.bus = &"SFX"
	sonido.max_distance = DISTANCIA_MAXIMA_DEL_SONIDO
	capa.get_tree().current_scene.add_child(sonido)
	sonido.finished.connect(sonido.queue_free)
	return sonido


static func _crear_material(capa: TileMapLayer, progreso: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("target_canvas_group", false)
	material.set_shader_parameter("fabric_texture", TRAMA_DE_TELA)
	material.set_shader_parameter("progress", progreso)

	var limites := TileMapMaskBounds.get_world_bounds(capa)
	if limites.has_area():
		material.set_shader_parameter("mask_origin", limites.position)
		material.set_shader_parameter("mask_size", limites.size)

	# Sin el filtro del mundo durante el efecto, para que no cambie de tono.
	var filtro_del_mundo := capa.material as ShaderMaterial
	if filtro_del_mundo:
		var saturacion = filtro_del_mundo.get_shader_parameter("saturation")
		if saturacion != null:
			material.set_shader_parameter("gray_intensity", 1.0 - float(saturacion))
		var oscuridad = filtro_del_mundo.get_shader_parameter("darkness_factor")
		if oscuridad != null and not capa.has_meta(META_TINTE):
			capa.set_meta(META_TINTE, capa.self_modulate)
			var tono := float(oscuridad)
			capa.self_modulate = capa.self_modulate * Color(tono, tono, tono, 1.0)
	return material


static func _avance_natural(capa: TileMapLayer) -> Vector2:
	var limites := TileMapMaskBounds.get_world_bounds(capa)
	return Vector2.DOWN if limites.size.y >= limites.size.x else Vector2.LEFT


static func _mascara_en_direccion(avance: Vector2) -> GradientTexture2D:
	var direccion := avance.normalized()
	var degradado := Gradient.new()
	degradado.set_color(0, Color.BLACK)
	degradado.set_color(1, Color.WHITE)
	var mascara := GradientTexture2D.new()
	mascara.gradient = degradado
	mascara.width = LADO_DE_LA_MASCARA
	mascara.height = LADO_DE_LA_MASCARA
	mascara.fill_from = Vector2(0.5, 0.5) - direccion * 0.5
	mascara.fill_to = Vector2(0.5, 0.5) + direccion * 0.5
	return mascara


static func _mostrar_con(
	capa: TileMapLayer, material: ShaderMaterial, mascara: GradientTexture2D
) -> void:
	material.set_shader_parameter("mask_texture", mascara)
	capa.material = material
	capa.show()
	capa.enabled = true


static func _devolver_material(capa: TileMapLayer, material_original: Material) -> void:
	capa.material = material_original
	if capa.has_meta(META_TINTE):
		capa.self_modulate = capa.get_meta(META_TINTE)
		capa.remove_meta(META_TINTE)
