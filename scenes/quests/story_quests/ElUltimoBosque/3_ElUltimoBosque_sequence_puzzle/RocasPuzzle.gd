extends SequencePuzzle

@onready var roca1 := $roca1
@onready var roca2 := $roca2
@onready var roca3 := $roca3
@onready var roca4 := $roca4

func _ready() -> void:
	super._ready()
	
	var puzzle_node := get_parent()

	if puzzle_node.has_signal("step_solved"):
		puzzle_node.step_solved.connect(_on_step_solved)
	
func _on_step_solved(step_index: int) -> void:
	print("Paso resuelto:", step_index)

	match step_index:
		0:
			_cambiar_roca(roca1, "roca1")
		1:
			_cambiar_roca(roca2, "roca2")
		2:
			_cambiar_roca(roca3, "roca3")
		3:
			_cambiar_roca(roca4, "roca4")


func _cambiar_roca(roca: Node, nombre: String) -> void:
	if is_instance_valid(roca):
		var anim_sprite = roca.get_node("AnimatedSprite2D")
		var colision = roca.get_node_or_null("CollisionShape2D")

		if anim_sprite:
			anim_sprite.play("abierto")
			print("Cambiando animación de", nombre)

		if colision:
			colision.disabled = true
			print("Desactivando colisión de", nombre)
