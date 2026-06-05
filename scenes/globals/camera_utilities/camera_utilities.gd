# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CameraUtilities


## Return the absolute path to the limit target of the current active camera, if it has one.
static func _get_phantom_camera_limit_target() -> NodePath:
	var phantom_camera_hosts: Array[PhantomCameraHost] = PhantomCameraManager.phantom_camera_hosts
	if not phantom_camera_hosts:
		return ""
	var active_pcam := phantom_camera_hosts[0].get_active_pcam() as PhantomCamera2D
	if not active_pcam:
		return ""
	if not active_pcam.limit_target:
		return ""
	if active_pcam.limit_target.is_absolute():
		return active_pcam.limit_target
	var absolute_target_path := active_pcam.get_node(active_pcam.limit_target).get_path()
	return absolute_target_path


## Assign the camera limits of the current active camera to this camera.
static func copy_current_camera_limits(camera: PhantomCamera2D) -> void:
	var limit_target := _get_phantom_camera_limit_target()
	if limit_target:
		camera.limit_target = limit_target
