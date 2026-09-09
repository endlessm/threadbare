# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D
class_name LoomOfferingAnimation

@onready var animation_path: Path2D = %AnimationPath
@onready var loom_offering_sound: AudioStreamPlayer2D = $LoomOfferingSound


@export var _play_animation: bool = false:
	set(value):
		play_loom_animation_debug()

@export var animation_time : float = 5.0
@export var debug_thread_count : int = 6


signal animation_finished

const WORLD_IMAGINATION = preload("uid://6bf8rum68wq3")
const WORLD_MEMORY = preload("uid://5wscjc8yqqts")
const WORLD_SPIRIT = preload("uid://cepg1o3ihp055")


func play_loom_animation() -> void:
	_loom_animation_play(GameState.quest.inventory.items)


func play_loom_animation_debug() -> void:
	var arr : Array[InventoryItem]
	for i in range(debug_thread_count):
		var _temp_item := InventoryItem.new()
		_temp_item.type = InventoryItem.ItemType.MEMORY
		arr.append(_temp_item)
	_loom_animation_play(arr)


func _loom_animation_play(thread_list : Array[InventoryItem]) -> void:
	
	var animation_points := animation_path.curve.get_baked_points()
	
	loom_offering_sound.play()
	
	
	var timer : float = animation_time / (animation_points.size() * 2.8)
	var modifier : int = animation_points.size() / floor(thread_list.size())
	
	var counter : int = 0
	for thread in thread_list:
		
		
		var sprite := Sprite2D.new()
		
		match (thread.type):
			InventoryItem.ItemType.MEMORY:
				sprite.texture = WORLD_MEMORY
			InventoryItem.ItemType.IMAGINATION:
				sprite.texture = WORLD_IMAGINATION
			InventoryItem.ItemType.SPIRIT:
				sprite.texture = WORLD_SPIRIT
			_ :
				sprite.texture = WORLD_SPIRIT
			 
		
		sprite.position = animation_points[counter * modifier]
		add_child(sprite)
		
		var tween := sprite.create_tween()
		
		if (counter == 0):
			tween.finished.connect(_on_animation_finished)
		
		# Animation Start
		tween.tween_property(sprite, "scale", Vector2(0,0), 0)
		
		tween.tween_property(sprite, "scale", Vector2(1,1), timer)
		tween.parallel().tween_property(sprite, "position", animation_points[(counter * modifier + 1) % animation_points.size()], timer)
		
		# Thread Roundabout
		for j in range(animation_points.size() - 1 + (thread_list.size() - counter) * modifier) :
			var position_index : int = (counter * modifier + j + 2 ) % animation_points.size()
			tween.tween_property(sprite, "position", animation_points[position_index], timer)
		
		# Final animation
		tween.tween_property(sprite, "position", Vector2(0, 0), timer*2)
		tween.tween_property(sprite, "modulate", Color(0,0,0,0), 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(3,3), 0.5)
		
		
		counter = counter + 1
	
	thread_list.back()


func _on_animation_finished() -> void:
	print("finished!")
	animation_finished.emit()
