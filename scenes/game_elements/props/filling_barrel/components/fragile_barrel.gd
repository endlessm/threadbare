# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FragileBarrel
extends FillingBarrel

## Emitted when [member current_health] reaches 0.
signal barrel_destroyed(barrel_instance: FragileBarrel)

@onready var crack_overlay_node: AnimatedSprite2D = %CrackOverlay
@onready var crack_sound: AudioStreamPlayer2D = %CrackSound
@onready var shatter_sound: AudioStreamPlayer2D = %ShatterSound
@onready var health_component: HealthComponent = %HealthComponent


func _ready() -> void:
	super._ready()
	crack_overlay_node.visible = false


# Logic called by Projectile when it hits this object
func hit_by_droplet(droplet_label: String) -> void:
	# Ignore if already full or destroyed
	if _amount >= needed_amount or health_component.has_depleted_health:
		return

	if droplet_label == self.label:
		increment()
	else:
		health_component.damage(1)


func take_damage(_current_health: int, has_depleted_health: bool) -> void:
	if not has_depleted_health:
		crack_sound.play()
		update_cracks()


func update_cracks() -> void:
	# IMPROVEMENT: Calculate frame index proportionally based on damage percentage.
	var total_frames: int = crack_overlay_node.sprite_frames.get_frame_count("default")
	var frame_index: int = int(floor((health_component.damage_taken_percentage) * total_frames))

	# Clamp to ensure we don't exceed available frames (0-based index)
	frame_index = clamp(frame_index, 0, total_frames - 1)

	crack_overlay_node.visible = true
	crack_overlay_node.frame = frame_index


func break_barrel() -> void:
	crack_overlay_node.visible = false

	shatter_sound.play()

	# Play destruction animation directly
	animated_sprite_2d.play("shatter")
	await animated_sprite_2d.animation_finished

	barrel_destroyed.emit(self)
