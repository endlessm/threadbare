# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var extra_needles: Array[Node2D]
@onready var helper_camera: PhantomCamera2D = %HelperCamera


func _ready() -> void:
	for n in extra_needles:
		n.visible = false
		n.process_mode = Node.PROCESS_MODE_DISABLED


func add_extra_needles() -> void:
	CameraUtilities.copy_current_camera_limits(helper_camera)
	helper_camera.priority = 20
	await get_tree().create_timer(1.0).timeout
	for n in extra_needles:
		n.visible = true
		n.process_mode = Node.PROCESS_MODE_INHERIT
		await get_tree().create_timer(1.0).timeout
	helper_camera.priority = 0
	await get_tree().create_timer(1.0).timeout
