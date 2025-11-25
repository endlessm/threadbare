# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FragileVase
extends FillingBarrel

# Signal emitted when the vase is destroyed
signal vase_destroyed(vase_instance: FragileVase)

@export_group("Fragility")
@export_range(3, 5) var max_health: int = 4
## Reference to the AnimatedSprite2D containing the crack frames.
@export var crack_overlay_node: AnimatedSprite2D

var current_health: int


func _ready() -> void:
	super._ready()
	current_health = max_health

	if crack_overlay_node:
		crack_overlay_node.visible = false
		crack_overlay_node.stop()
		crack_overlay_node.frame = 0
	else:
		if not Engine.is_editor_hint():
			push_warning("FragileVase: 'Crack Overlay Node' is not assigned in %s" % name)


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
	if not crack_overlay_node:
		return

	var damage_taken: int = max_health - current_health

	crack_overlay_node.visible = true
	if damage_taken > 0:
		# Frame 0 = 1 damage, Frame 1 = 2 damage, etc.
		crack_overlay_node.frame = damage_taken - 1


func break_vase() -> void:
	if crack_overlay_node:
		crack_overlay_node.visible = false

	# Play destruction animation
	# Usamos el acceso directo para evitar variables temporales sin tipo
	if animated_sprite_2d and animated_sprite_2d.sprite_frames.has_animation("shatter"):
		animated_sprite_2d.play("shatter")
		await animated_sprite_2d.animation_finished

	vase_destroyed.emit(self)
