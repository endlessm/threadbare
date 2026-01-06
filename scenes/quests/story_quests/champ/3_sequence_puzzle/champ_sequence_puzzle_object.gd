# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool 
class_name ChampSequencePuzzleObject
extends SequencePuzzleObject

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var rock: AnimatedSprite2D = %AnimatedSprite2D

var new_col: RectangleShape2D = RectangleShape2D.new()
const COLLISION_SCALE : Vector2 = Vector2(60,50)

func _ready() -> void:
	# Manually setting collision shape to block character from
	# moving before selecting the correct sequence object
	new_col.size = COLLISION_SCALE
	collision.shape = new_col
	super._ready()

## Function to change sprite frames from the submerged rock to dry rock
func dry_off() -> void:
	# Current implementation changes file path of "default" animation, since `_stop` in parent sequence puzzle script plays "default" sprite frames 
	rock.sprite_frames.set_frame("default", 0, preload("res://scenes/quests/story_quests/champ/3_sequence_puzzle/champ_dry_rock.png"), 1)
	if collision:
		collision.disabled = true

## Function to change object to default animation with waves, frees interactive node
func submerge() -> void:
	rock.play("default")
	if interact_area:
		interact_area.queue_free()
