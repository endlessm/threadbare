extends SequencePuzzle

@onready var roca1 := $roca1
@onready var roca2 := $roca2
@onready var roca3 := $roca3
@onready var roca4 := $roca4

func _ready() -> void:
	super._ready()
	
	var puzzle_node := get_parent() # o usa get_parent().get_parent() si es necesario subir más

	if puzzle_node.has_signal("step_solved"):
		puzzle_node.step_solved.connect(_on_step_solved)
	
func _on_step_solved(step_index: int) -> void:
	print("Paso resuelto:", step_index)

	match step_index:
		0:
			if is_instance_valid(roca1):
				print("Eliminando roca1")
				roca1.queue_free()
		1:
			if is_instance_valid(roca2):
				print("Eliminando roca2")
				roca2.queue_free()
		2:
			if is_instance_valid(roca3):
				print("Eliminando roca3")
				roca3.queue_free()
		3:
			if is_instance_valid(roca4):
				print("Eliminando roca4")
				roca4.queue_free()
