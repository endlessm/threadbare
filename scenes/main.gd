extends Node2D
@onready var color_rect: ColorRect = %ColorRect


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_cancel"):
		color_rect.material.set_shader_parameter(&"debug", not color_rect.material.get_shader_parameter(&"debug"))
		
	
