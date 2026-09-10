# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name LoomOfferingAnimation
extends Node2D

signal animation_finished

const WORLD_IMAGINATION = preload("uid://6bf8rum68wq3")
const WORLD_MEMORY = preload("uid://5wscjc8yqqts")
const WORLD_SPIRIT = preload("uid://cepg1o3ihp055")

## The time in seconds it takes for the animation to finish, determines the speed of threads
@export var animation_time: float = 5.0
## Number of threads in the animation for the in-editor preview
@export var debug_thread_count: int = 6

@export_tool_button("Play") var play_animation: Callable = play_loom_animation_debug

@onready var animation_path: Path2D = %AnimationPath
@onready var loom_offering_sound: AudioStreamPlayer2D = $LoomOfferingSound


func play_loom_animation() -> void:
	_loom_animation_play(GameState.quest.inventory.items)


## Only used for the in-editor preview
func play_loom_animation_debug() -> void:
	var arr: Array[InventoryItem]
	for i in range(debug_thread_count):
		var temp_item := InventoryItem.new()
		temp_item.type = InventoryItem.ItemType.values().pick_random()
		arr.append(temp_item)
	_loom_animation_play(arr)


func _loom_animation_play(thread_list: Array[InventoryItem]) -> void:
	if thread_list.is_empty():
		animation_finished.emit()
		return

	var animation_points := animation_path.curve.get_baked_points()

	loom_offering_sound.play()

	# Time between each animation_point
	var timer: float = animation_time / (animation_points.size() * 2.8)
	# Separation between threads
	var separator: int = animation_points.size() / floor(thread_list.size())

	var counter: int = 0
	for thread in thread_list:
		var sprite := Sprite2D.new()
		sprite.texture = thread.get_world_texture()

		sprite.position = animation_points[counter * separator]
		add_child(sprite)

		var tween := sprite.create_tween()

		## The first thread is the last to enter the loom
		if counter == 0:
			tween.finished.connect(_on_animation_finished)

		# Animation Start
		tween.tween_property(sprite, "scale", Vector2(0, 0), 0)

		tween.tween_property(sprite, "scale", Vector2(1, 1), timer)
		tween.parallel().tween_property(
			sprite,
			"position",
			animation_points[(counter * separator + 1) % animation_points.size()],
			timer
		)

		# Thread Cycle
		for i in range(animation_points.size() - 1 + (thread_list.size() - counter) * separator):
			var position_index: int = (counter * separator + i + 2) % animation_points.size()
			tween.tween_property(sprite, "position", animation_points[position_index], timer)

		# Final animation
		tween.tween_property(sprite, "position", Vector2(0, 0), timer * 2)
		tween.tween_property(sprite, "modulate", Color(0, 0, 0, 0), 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(3, 3), 0.5)

		counter = counter + 1


func _on_animation_finished() -> void:
	animation_finished.emit()
