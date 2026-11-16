extends RigidBody2D

## Señal emitida cuando el objeto es interactuado
signal interactuado3
signal boton_presionado(valor: int)

@onready var interact_area: InteractArea = get_node("InteractArea") as InteractArea
@export var desplazamiento_presionado: Vector2 = Vector2(0, 6)
@export var color_presionado: Color = Color(0.85, 0.85, 0.95, 1.0)
@export var color_sin_presionar: Color = Color(1, 1, 1, 1)
@export_node_path("Sprite2D") var sprite_path: NodePath = NodePath("ColllsionNumber3/SpriteNumber3")
@export var valor_boton: int = 3

var _boton_usado: bool = false
var _sprite: Sprite2D = null
var _posicion_base_sprite: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Conectar la señal de interacción
	if interact_area:
		# Verificar que el InteractArea pertenece a este objeto
		if interact_area.get_parent() == self:
			interact_area.interaction_started.connect(_on_interaction_started)
			print("Number3: InteractArea encontrado y conectado correctamente")
		else:
			print("Number3: ERROR - InteractArea no pertenece a este objeto! Parent: ", interact_area.get_parent().name if interact_area.get_parent() else "null")
	else:
		print("Advertencia: No se encontró InteractArea en Number2")
	
	_sprite = _obtener_sprite()
	if _sprite:
		_posicion_base_sprite = _sprite.position
	_actualizar_estado_visual()


func _on_interaction_started(_player: Player, _from_right: bool) -> void:
	if _boton_usado:
		print("Number3: ignorando interacción, ya fue utilizado")
		call_deferred("_end_interaction")
		return
	# Esta función se llama cuando el jugador interactúa con el objeto
	print("Number3: _on_interaction_started llamado")
	interactuado3.emit()
	boton_presionado.emit(valor_boton)
	print("¡Number3 fue interactuado!")
	_marcar_como_usado()
	
	# Aquí puedes agregar tu lógica personalizada
	# Por ejemplo: cambiar sprite, reproducir sonido, etc.
	
	# Finalizar la interacción (usar call_deferred para asegurar que se ejecute después)
	call_deferred("_end_interaction")


func _end_interaction() -> void:
	if interact_area:
		print("Number3: Emitiendo interaction_ended")
		interact_area.interaction_ended.emit()
	else:
		print("Number3: ERROR - interact_area es null al intentar finalizar")


func _marcar_como_usado() -> void:
	if _boton_usado:
		return
	_boton_usado = true
	if interact_area:
		interact_area.disabled = true
	_actualizar_estado_visual()


func reiniciar_boton() -> void:
	if not _boton_usado:
		return
	_boton_usado = false
	if interact_area:
		interact_area.disabled = false
	_actualizar_estado_visual()


func esta_usado() -> bool:
	return _boton_usado


func _actualizar_estado_visual() -> void:
	if _sprite:
		var desplazamiento := desplazamiento_presionado if _boton_usado else Vector2.ZERO
		_sprite.position = _posicion_base_sprite + desplazamiento
		_sprite.modulate = color_presionado if _boton_usado else color_sin_presionar


func _obtener_sprite() -> Sprite2D:
	if sprite_path != NodePath(""):
		return get_node_or_null(sprite_path) as Sprite2D
	return _buscar_sprite_recursivo(self)


func _buscar_sprite_recursivo(node: Node) -> Sprite2D:
	for child in node.get_children():
		if child is Sprite2D:
			return child
		var nested := _buscar_sprite_recursivo(child)
		if nested:
			return nested
	return null
