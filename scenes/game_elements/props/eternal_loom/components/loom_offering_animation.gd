# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name LoomOfferingAnimation
extends Node2D

signal animation_finished

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
	var debug_items: Array[InventoryItem]
	# TODO: InventoryItem needs a utility function to obtain all types except NONE.
	var item_types := InventoryItem.COLORS_PER_TYPE.keys()
	for i in range(debug_thread_count):
		var item := InventoryItem.new()
		item.type = item_types.pick_random()
		debug_items.append(item)
	_loom_animation_play(debug_items)


func _loom_animation_play(thread_list: Array[InventoryItem]) -> void:
	if thread_list.is_empty():
		animation_finished.emit()
		return

	var separation := 1.0 / thread_list.size()

	# Time it takes for all threads to loop
	var loop_time := animation_time * 0.7

	loom_offering_sound.play()

	var counter: int = 0
	for thread in thread_list:
		var path_follow := PathFollow2D.new()
		path_follow.rotates = false
		var sprite := Sprite2D.new()

		sprite.texture = thread.get_world_texture()
		path_follow.add_child(sprite)

		animation_path.add_child(path_follow)

		# Starting point for each thread
		path_follow.progress_ratio = counter * separation

		# Time variation between threads
		var time_variation := loop_time / (2.0 * thread_list.size())

		var tween := path_follow.create_tween()

		# The first thread is the last to end
		if counter == 0:
			tween.finished.connect(_on_animation_finished)

		# Animation Start
		tween.tween_property(sprite, "scale", Vector2(0, 0), 0)

		tween.tween_property(sprite, "scale", Vector2(1, 1), 0.5)
		# Loop around
		tween.parallel().tween_property(
			path_follow, "progress_ratio", 2.0, loop_time - time_variation * counter
		)

		# Animation end
		(
			tween
			. tween_property(sprite, "global_position", animation_path.global_position, 0.25)
			. set_ease(Tween.EASE_OUT)
		)
		tween.parallel().tween_property(sprite, "modulate", Color(0, 0, 0, 0), 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(3, 3), 0.5)
		tween.tween_callback(_thread_free.bind(sprite))
		counter += 1


# Remove thread once animation finishes
func _thread_free(thread: Sprite2D) -> void:
	thread.queue_free()


func _on_animation_finished() -> void:
	animation_finished.emit()
