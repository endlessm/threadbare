extends Node2D
@onready var player: CharacterBody2D = %Player
@onready var color_rect: ColorRect = %ColorRect


func _process(_delta: float) -> void:
	var w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h = ProjectSettings.get_setting("display/window/size/viewport_height")
	var pos = player.get_global_transform_with_canvas().origin
	var center = Vector2((pos.x)/w, pos.y/h)
	color_rect.material.set_shader_parameter(&"center", center)
	if Input.is_action_just_pressed(&"ui_cancel"):
		color_rect.material.set_shader_parameter(&"debug", not color_rect.material.get_shader_parameter(&"debug"))
		
	
