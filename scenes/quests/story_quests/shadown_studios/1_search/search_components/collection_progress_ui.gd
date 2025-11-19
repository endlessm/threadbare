extends CanvasLayer

@export var counter_label: Label

func _ready():
	if counter_label == null:
		push_error("ERROR: counter_label no está asignado en el Inspector")
	else:
		print("Counter Label configurado correctamente")

func update_counter(current: int, required: int) -> void:
	if counter_label == null:
		return
		
	counter_label.text = "%d/%d" % [current, required]
	
	if current >= required:
		counter_label.modulate = Color.GREEN
		await get_tree().create_timer(0.5).timeout
		counter_label.modulate = Color.WHITE
	else:
		counter_label.modulate = Color.WHITE

func show_ui() -> void:
	visible = true

func hide_ui() -> void:
	visible = false
