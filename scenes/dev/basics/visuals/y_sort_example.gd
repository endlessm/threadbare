# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const STARTING_OFFSET = Vector2(10, 0)
const ENDING_OFFSET = Vector2(100, 0)
const WIDTH = 3
const WALKING_PAUSE = 2.5
const WALKING_SPEED = 40

@onready var story_vore: Node2D = %StoryVore
@onready var ink_drinker: Node2D = %InkDrinker
@onready var ink_drinker_animation: AnimatedSprite2D = %InkDrinkerAnimation
@onready var path_walk_behavior: PathWalkBehavior = %PathWalkBehavior
@onready var unsorted_sprites: Node2D = %UnsortedSprites


func _ready() -> void:
	ink_drinker_animation.play("walk")


## Update the lines and circles drawn as the positions change.
func _process(_delta: float) -> void:
	queue_redraw()


## Draws lines to visualize the y position of sprites for y-sorting.
func _draw() -> void:
	draw_line(
		ink_drinker.global_position + STARTING_OFFSET,
		ink_drinker.global_position + ENDING_OFFSET,
		Color.PURPLE,
		WIDTH
	)
	draw_circle(ink_drinker.global_position, WIDTH, Color.WHITE)
	draw_line(
		story_vore.global_position + STARTING_OFFSET,
		story_vore.global_position + ENDING_OFFSET,
		Color.GREEN,
		WIDTH
	)
	draw_circle(story_vore.global_position, WIDTH, Color.WHITE)


## Sprite walks up and down, pausing at each end for emphasis on overlap.
func _on_path_walk_behavior_ending_reached() -> void:
	path_walk_behavior.speeds.walk_speed = 0
	ink_drinker_animation.play("idle")
	await get_tree().create_timer(WALKING_PAUSE).timeout
	ink_drinker_animation.play("walk")
	path_walk_behavior.speeds.walk_speed = WALKING_SPEED


## Toggle the y sorting of the sprites based on the rock interaction.
func _on_interact_area_interaction_started(area: InteractArea, y_sort: bool) -> void:
	unsorted_sprites.y_sort_enabled = y_sort
	area.end_interaction()
