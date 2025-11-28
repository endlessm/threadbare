# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FragileVase
extends FillingBarrel

## Emitted when [member current_health] reaches 0.
signal vase_destroyed(vase_instance: FragileVase)

## Maximum hits the vase can take before breaking.
@export_range(1, 100) var max_health: int = 4

var current_health: int

@onready var crack_overlay_node: AnimatedSprite2D = %CrackOverlay


func _ready() -> void:
	super._ready()
	current_health = max_health

	crack_overlay_node.visible = false
	crack_overlay_node.stop()
	crack_overlay_node.frame = 0


# Logic called by Projectile when it hits this object
func hit_by_droplet(droplet_label: String) -> void:
	# Ignore if already full or destroyed
	if _amount >= needed_amount or current_health <= 0:
		return

	if droplet_label == self.label:
		increment()
	else:
		take_damage()


func take_damage() -> void:
	current_health -= 1

	if current_health <= 0:
		break_vase()
	else:
		update_cracks()


func update_cracks() -> void:
	var damage_taken: int = max_health - current_health

	# IMPROVEMENT: Calculate frame index proportionally based on damage percentage.
	# This ensures cracks are distributed evenly regardless of max_health.
	var total_frames: int = crack_overlay_node.sprite_frames.get_frame_count("default")
	# Using float conversion to get a percentage (0.0 to 1.0) of damage taken relative to max health
	# We cast the result to int to satisfy static typing requirements
	var frame_index: int = int(floor((float(damage_taken) / max_health) * total_frames))

	# Clamp to ensure we don't exceed available frames (0-based index)
	frame_index = clamp(frame_index, 0, total_frames - 1)

	crack_overlay_node.visible = true
	crack_overlay_node.frame = frame_index


func break_vase() -> void:
	crack_overlay_node.visible = false

	# Play destruction animation directly
	animated_sprite_2d.play("shatter")
	await animated_sprite_2d.animation_finished

	vase_destroyed.emit(self)
