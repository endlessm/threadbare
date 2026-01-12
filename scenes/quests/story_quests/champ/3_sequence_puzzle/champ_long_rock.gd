# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
@onready var rock: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $AnimatedSprite2D/Area2D

## Boolean value representing if the rock is under water
@export var submerged: bool = true:
	set = set_submerged

## Signal indicating the player is standing on a submerged rock (indicating an incorrect response)
signal water_entered

func set_submerged(is_submerged: bool) -> void:
	submerged = is_submerged
	if not is_node_ready():
		return
	area_2d.monitoring = submerged
	if submerged:
		rock.play("waves")
	else:
		rock.play("default")


func _ready() -> void:
	set_submerged(submerged)


## Function to tell champ sequence puzzle script the player guessed wrong and must be moved back
func _on_area_2d_body_entered(_body: Node2D) -> void:
	await get_tree().create_timer(1.5).timeout
	water_entered.emit()


## Toggles the water level of the rock, updating the animation and knocking the player back if necessary.
func toggle_water_level() -> void:
	submerged = not submerged
