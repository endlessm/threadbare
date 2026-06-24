extends Area2D
## Calcula automáticamente el rectángulo del jardín a partir del área
## ocupada por el TileMapLayer "Grass" (no hace falta escribir números a
## mano). Además dibuja un rectángulo ROJO en pantalla mientras jugás,
## para que confirmes a simple vista que coincide con el césped real.
##
## Cómo usarlo:
## 1. En el Inspector, asigná grass_layer arrastrando el nodo "Grass".
## 2. Listo. Al darle Play, este script calcula los límites solos y los
##    dibuja en rojo para que los puedas verificar.
##
## Si por algún motivo el cálculo automático no da bien (por ejemplo si
## tenés varias capas de césped, o el TileMapLayer tiene escala rara),
## podés tildar "Use Manual Bounds" y escribir garden_min/garden_max a
## mano como respaldo.

@export var grass_layer: TileMapLayer
## Mostrar el rectángulo de debug mientras se juega.
@export var show_debug_rect: bool = true

@export_group("Respaldo manual (opcional)")
## Si lo activás, se ignora grass_layer y se usan los valores de abajo.
@export var use_manual_bounds: bool = false
@export var garden_min: Vector2 = Vector2(-360, -256)
@export var garden_max: Vector2 = Vector2(1368, 960)


func _ready() -> void:
	if not use_manual_bounds:
		_calculate_bounds_from_grass()
	queue_redraw()


func _process(_delta: float) -> void:
	if show_debug_rect:
		queue_redraw()


## Calcula garden_min / garden_max en coordenadas GLOBALES (píxeles) a
## partir del área ocupada por grass_layer.
func _calculate_bounds_from_grass() -> void:
	if grass_layer == null:
		push_warning("JardinArea: no se asignó grass_layer; usando garden_min/garden_max actuales.")
		return
	if grass_layer.tile_set == null:
		push_warning("JardinArea: grass_layer no tiene un TileSet asignado.")
		return

	var used_rect: Rect2i = grass_layer.get_used_rect()
	var tile_size: Vector2 = grass_layer.tile_set.tile_size

	# used_rect está en coordenadas de CELDA. Lo pasamos a píxeles locales
	# del TileMapLayer (celda * tile_size), y luego a posición global
	# usando to_global, que ya tiene en cuenta la posición/rotación/escala
	# del propio nodo Grass.
	var local_top_left: Vector2 = Vector2(used_rect.position) * tile_size
	var local_bottom_right: Vector2 = Vector2(used_rect.position + used_rect.size) * tile_size

	var global_top_left: Vector2 = grass_layer.to_global(local_top_left)
	var global_bottom_right: Vector2 = grass_layer.to_global(local_bottom_right)

	garden_min = Vector2(
		min(global_top_left.x, global_bottom_right.x),
		min(global_top_left.y, global_bottom_right.y)
	)
	garden_max = Vector2(
		max(global_top_left.x, global_bottom_right.x),
		max(global_top_left.y, global_bottom_right.y)
	)

	print(">>> JardinArea: limites calculados desde Grass -> min=", garden_min, " max=", garden_max)


func _draw() -> void:
	if not show_debug_rect:
		return
	# _draw() trabaja en coordenadas LOCALES del nodo, así que convertimos
	# garden_min/garden_max (que son globales) a locales antes de dibujar.
	var local_min: Vector2 = to_local(garden_min)
	var local_max: Vector2 = to_local(garden_max)
	var rect := Rect2(local_min, local_max - local_min)
	draw_rect(rect, Color(1, 0, 0, 0.12), true)        # relleno semi-transparente
	draw_rect(rect, Color(1, 0, 0, 1.0), false, 2.0)    # borde rojo sólido


## Devuelve los límites del jardín en coordenadas globales como [min, max].
## La Serpiente (u otros scripts) llaman a esto para confinarse al área.
func get_bounds() -> Array:
	return [garden_min, garden_max]
