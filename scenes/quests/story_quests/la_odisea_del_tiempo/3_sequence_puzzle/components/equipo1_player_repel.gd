# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PlayerRepel
func _on_repel_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"repel":
		repelling = false #
