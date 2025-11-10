# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var collision_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = Vector2(40, 40)  
	
	collision_shape.shape = rectangle_shape
	collision_area.add_child(collision_shape)
	add_child(collision_area)
	
	collision_area.connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("¡Jugador chocó con la roca!")
		
		if body.has_method("volver_al_inicio"):
			body.volver_al_inicio()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
