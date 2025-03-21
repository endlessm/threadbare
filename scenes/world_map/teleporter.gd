class_name Teleporter
extends Area2D

@export_file("*.tscn") var scene_to_go_to: String


func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)


func _on_body_entered(_body: PhysicsBody2D) -> void:
	if scene_to_go_to:
		get_tree().change_scene_to_file(scene_to_go_to)
