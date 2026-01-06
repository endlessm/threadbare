# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
@onready var rock: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $AnimatedSprite2D/Area2D

## Boolean value representing if the rock is under water
@export var submerged = true

## Signal indicating the player is standing on a submerged rock (indicating an incorrect response)
signal water_entered

func _ready() -> void:
	if submerged:
		rock.play("waves")
	else:
		rock.play("default")

func _physics_process(delta: float) -> void:
	if area_2d.get_overlapping_bodies() != [] and submerged:
		_on_area_2d_body_entered(Node2D.new())

## Function to tell champ sequence puzzle script the player guessed wrong and must be moved back
func _on_area_2d_body_entered(body: Node2D) -> void:
	await get_tree().create_timer(1.5).timeout
	if submerged:
		water_entered.emit()

## Function to toggle the water level of the long rock by swapping sprite frames
## If submerged, it plays "default", otherwise "waves"
func toggle_water_level() -> void:
	if submerged:
		rock.play("default")
	else:
		rock.play("waves")
	submerged = not submerged
