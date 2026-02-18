# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@onready var champ_animation: AnimatedSprite2D = $"Champ Animation"

var swim_speed: int = 100

func _ready() -> void:
	# Give champ a starting swim speed
	velocity.x = swim_speed

func _physics_process(_delta: float) -> void:
	# Make sure Champ doesn't swim out of the water! 
	# If he gets too close, turn him around and start swimming the other direction
	if position.x > 400 or position.x < 0:
		champ_animation.scale.x *= -1
		velocity.x *= -1

	# TODO: Can we make Champ swim in a more interesting pattern?
	# Can we change the way Champ swims vertically? Can we accelerate?

	# Continues to move the CharacterBody2D Object based on it's velocity
	move_and_slide()
