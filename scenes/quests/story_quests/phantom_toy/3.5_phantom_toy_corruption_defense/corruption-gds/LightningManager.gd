# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ColorRect

@onready var thunder_sound: AudioStreamPlayer = $"../ThunderSound"


func _ready():

	visible = false

	start_lightning_loop()


func start_lightning_loop() -> void:

	while true:

		await get_tree().create_timer(
			randf_range(15.0, 25.0)
		).timeout

		await flash()


func flash() -> void:

	visible = true

	modulate.a = 0.8

	await get_tree().create_timer(0.05).timeout

	modulate.a = 0.2

	await get_tree().create_timer(0.03).timeout

	modulate.a = 1.0

	await get_tree().create_timer(0.04).timeout

	modulate.a = 0.0

	visible = false

	thunder_sound.play()
