# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends SequencePuzzleHintSign

signal hint_sequence_finished

@onready var collision_shape: CollisionShape2D = $InteractArea/CollisionShape2D

const COLLISION_OFFSET : int = 50
const COLLISION_SCALE : Vector2 = Vector2(0.5, 0.5)

func _ready() -> void:
	# Ensure the second hint sign camera movement does not cut off a step
	collision_shape.scale = COLLISION_SCALE
	collision_shape.position.y = collision_shape.position.y - COLLISION_OFFSET
	super._ready()
	
## Function to emit a signal to champ specific sequence puzzle script so path can be reset
func demonstration_finished() -> void:
	hint_sequence_finished.emit()
	super.demonstration_finished()
