# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Guard


func _ready() -> void:
	collision_layer = 2
	super._ready()
	if detection_area and not detection_area.area_entered.is_connected(_on_detection_area_area_entered):
		detection_area.area_entered.connect(_on_detection_area_area_entered)


func _process(delta: float) -> void:
	super._process(delta)
	_check_quest_projectiles()


func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"projectiles"):
		area.queue_free()
		queue_free()


func _check_quest_projectiles() -> void:
	if not is_instance_valid(detection_area):
		return
	for area: Area2D in detection_area.get_overlapping_areas():
		if area.is_in_group(&"projectiles"):
			area.queue_free()
			queue_free()
			return
