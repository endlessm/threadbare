extends Node2D

@onready var puzzle: Node = $OnTheGround/SequencePuzzle

var _last_step: int = 0
var _last_pos: int = 0
var _original_colors: Dictionary = {}
var _is_showing_error: bool = false

func _ready() -> void:
	call_deferred("_setup_puzzle_tracking")
	if puzzle.has_signal("step_solved"):
		print("paso correcto!")

func _setup_puzzle_tracking() -> void:
	if not puzzle:
		print("Error: Nodo SequencePuzzle no encontrado.")
		return
	
	_last_step = puzzle.get("_current_step")
	_last_pos = puzzle.get("_position")
	
	var objects = get_tree().get_nodes_in_group(&"sequence_object")
	for obj in objects:
		if obj is SequencePuzzleObject:
			var target_sprite = obj.get_node_or_null("Sprite2D")
			if target_sprite:
				_original_colors[obj] = target_sprite.modulate
			
			obj.kicked.connect(_on_object_kicked.bind(obj))

func _on_object_kicked(obj: Node) -> void:
	# Si está mostrando el error en rojo, ignora nuevos golpes por 1 segundo
	if _is_showing_error:
		return 
	call_deferred("_evaluate_puzzle_state", obj)

func _evaluate_puzzle_state(obj: Node) -> void:
	var current_step = puzzle.get("_current_step")
	var current_pos = puzzle.get("_position")
	
	var step_changed = current_step > _last_step
	var pos_increased = current_pos > _last_pos

	if step_changed or pos_increased:
		# ACIERTO: Cambia el color del Sprite2D a verde
		_set_sprite_color(obj, Color(0, 1, 0, 1))
		_last_step = current_step
		_last_pos = current_pos
	elif current_pos == 0 and not step_changed:
		# FALLO: Secuencia rota
		_is_showing_error = true
		
		var steps_array = puzzle.get("steps")
		if _last_step < steps_array.size():
			var current_sequence = steps_array[_last_step].sequence
			
			# 1. Pintar todos los elementos de la secuencia actual en rojo
			for seq_obj in current_sequence:
				_set_sprite_color(seq_obj, Color(1, 0, 0, 1))
			
			# 2. Esperar exactamente 1 segundo
			await get_tree().create_timer(0.1).timeout
			
			# 3. Restaurar todos a su color original
			for seq_obj in current_sequence:
				_restore_sprite_color(seq_obj)
				
		_is_showing_error = false
		_last_step = current_step
		_last_pos = current_pos

func _set_sprite_color(obj: Node, color: Color) -> void:
	var target_sprite = obj.get_node_or_null("Sprite2D")
	if target_sprite:
		target_sprite.modulate = color

func _restore_sprite_color(obj: Node) -> void:
	if _original_colors.has(obj):
		var target_sprite = obj.get_node_or_null("Sprite2D")
		if target_sprite:
			target_sprite.modulate = _original_colors[obj]
