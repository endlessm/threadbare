class_name PlayerInteraction
extends Node2D

@onready var interact_ray: RayCast2D = %InteractRay

var is_interacting: bool = false

func _process(_delta: float) -> void:
	if is_interacting:
		return
	var interact_area: InteractArea = interact_ray.interact_area
	if not interact_area:
		return
	if Input.is_action_just_released(&"ui_accept"):
		interact_area.interaction_ended.connect(_on_interaction_ended)
		interact_area.start_interaction()
		is_interacting = true

func _on_interaction_ended() -> void:
	var interact_area: InteractArea = interact_ray.interact_area
	interact_area.interaction_ended.disconnect(_on_interaction_ended)
	is_interacting = false
