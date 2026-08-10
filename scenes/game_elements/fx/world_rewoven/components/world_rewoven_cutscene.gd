# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)


func _on_animation_finished(_anim_name: StringName) -> void:
	# Go back home. Usually Fray's End and next to the Eternal Loom:
	var home_scene: String = ThreadbareProjectSettings.get_setting(
		ThreadbareProjectSettings.HOME_SCENE
	)
	SceneSwitcher.change_to_file_with_transition(
		home_scene, "", Transitions.Effect.FADE, Transitions.Effect.FADE
	)
