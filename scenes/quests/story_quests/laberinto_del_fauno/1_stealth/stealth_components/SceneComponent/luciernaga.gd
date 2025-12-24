extends Node2D

## La escena de luz (LuciernagaLight.tscn) que queremos generar.
## Debe ser un PointLight2D para que funcione el script de pulsación.
@export var light_scene: PackedScene

## Cuántas luciérnagas deben aparecer en el mapa.
@export_range(1, 1000) var spawn_count: int = 50

## Referencia al nodo Polygon2D que define el área de generación.
## ¡IMPORTANTE! Arrastra tu nodo Polygon2D aquí.
@export var Zone1: NodePath
@export var Zone2: NodePath


func _ready() -> void:
	var polygon_node_Zone1: Polygon2D = get_node_or_null(Zone1)
	var polygon_node_Zone2: Polygon2D = get_node_or_null(Zone2)
	_spawn_lights(polygon_node_Zone1)
	_spawn_lights(polygon_node_Zone2)
	
func _spawn_lights(polygon_node: Polygon2D) -> void:
	var spawned_lights: int = 0
	
	var polygon_points_local: PackedVector2Array = polygon_node.polygon
	
	var polygon_points_global: PackedVector2Array = []
	for p in polygon_points_local:
		polygon_points_global.append(polygon_node.to_global(p))
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	
	for p in polygon_points_global:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var bounding_box: Rect2 = Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
	
	var max_attempts: int = spawn_count * 10 
	var attempts: int = 0
	
	while spawned_lights < spawn_count and attempts < max_attempts:
		attempts += 1
		
		var random_pos_global: Vector2 = Vector2(
			randf_range(bounding_box.position.x, bounding_box.end.x),
			randf_range(bounding_box.position.y, bounding_box.end.y)
		)
		
		var is_inside: bool = Geometry2D.is_point_in_polygon(random_pos_global, polygon_points_global)
		
		if is_inside:
			var light_instance: PointLight2D = light_scene.instantiate()
			
			light_instance.global_position = random_pos_global
			
			add_child(light_instance)
			spawned_lights += 1
