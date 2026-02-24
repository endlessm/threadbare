# SPDX-FileCopyrightText: 2025 Game-Lab-5-0-UTP-Group-1-Team-1 Contributors
# SPDX-License-Identifier: MPL-2.0
@tool
extends ThrowingEnemy
## Wizzy Quest throwing enemy with visual feedback
##
## Extends base ThrowingEnemy with:
## - Shake animation when player completes a barrel (visual feedback)

# Shake animation constants
const SHAKE_OFFSET := 5.0
const SHAKE_DURATION := 0.05


## Plays horizontal shake animation as feedback when barrel is completed
func shake() -> void:
	if not _can_shake():
		return

	var original_pos := position
	var tween := create_tween()

	# Shake pattern: right, left, right, left, center
	tween.tween_property(self, "position", original_pos + Vector2(SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos + Vector2(-SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos + Vector2(SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos + Vector2(-SHAKE_OFFSET, 0), SHAKE_DURATION)
	tween.tween_property(self, "position", original_pos, SHAKE_DURATION)

	await tween.finished


## Returns true if enemy can shake (not attacking or defeated)
func _can_shake() -> bool:
	var current_state := _get_state()
	return current_state != State.ATTACKING and current_state != State.DEFEATED
