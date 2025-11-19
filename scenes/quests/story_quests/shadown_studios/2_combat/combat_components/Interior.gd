extends Area2D

# Interior (TileMapLayers)
@export var interior_piso_central: TileMapLayer
@export var interior_piso_motor: TileMapLayer
@export var interior_elementos: TileMapLayer
@export var interior_almacen: TileMapLayer

# Exterior (Sprite2D)
@export var exterior_pared_nave: Sprite2D  # Cambiado a Sprite2D

var showing_interior = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Ocultar interior al inicio, mostrar exterior
	for layer in [interior_piso_central, interior_piso_motor, interior_elementos, interior_almacen]:
		if layer:
			layer.visible = false
			layer.modulate.a = 0.0
	
	# Asegurar que el sprite exterior esté visible al inicio
	if exterior_pared_nave:
		exterior_pared_nave.visible = true
		exterior_pared_nave.modulate.a = 1.0

func _on_body_entered(body):
	if body.name == "Player":
		toggle_interior_exterior()

func toggle_interior_exterior():
	showing_interior = !showing_interior
	
	if showing_interior:
		show_interior()
		hide_exterior()
	else:
		hide_interior()
		show_exterior()

func show_interior():
	for layer in [interior_piso_central, interior_piso_motor, interior_elementos, interior_almacen]:
		if layer:
			layer.visible = true
			var tween = create_tween()
			tween.tween_property(layer, "modulate:a", 1.0, 0.5)

func hide_interior():
	for layer in [interior_piso_central, interior_piso_motor, interior_elementos, interior_almacen]:
		if layer:
			var tween = create_tween()
			tween.tween_property(layer, "modulate:a", 0.0, 0.5)
			await tween.finished
			layer.visible = false

func show_exterior():
	if exterior_pared_nave:
		exterior_pared_nave.visible = true
		var tween = create_tween()
		tween.tween_property(exterior_pared_nave, "modulate:a", 1.0, 0.5)

func hide_exterior():
	if exterior_pared_nave:
		var tween = create_tween()
		tween.tween_property(exterior_pared_nave, "modulate:a", 0.0, 0.5)
		await tween.finished
		exterior_pared_nave.visible = false
