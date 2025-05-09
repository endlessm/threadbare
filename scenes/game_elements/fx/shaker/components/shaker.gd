# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Shaker extends Node2D

## Node that applies a shake to a target by applying a shift in its position
## and rotation over time.
## Useful for visual effects like characters being attacked or camera shakes.

## Emitted when the target starts shaking
signal started
## Emitted when the target stopped shaking
signal finished

## Node that will be shaked
@export var target: CanvasItem
## Maximum possible value in which the position of the node might be offset.
@export_range(1.0, 100.0, 1.0, "or_greater", "or_less") var shake_intensity: float = 30.0
## How much time (in seconds) the node will be shaken.
@export_range(0.5, 5.0, 0.1, "or_greater", "or_less", "suffix:s") var duration: float = 1.5
## Higher frequencies means that the node's position will be offset faster.
@export_range(1.0, 30.0, 1.0, "or_greater", "or_less") var frequency: float = 10.0
## Test out the shake parameters in the editor
@export_tool_button("Test") var _test = shake

## Noise used to generate random values between -1 and 1
var noise: FastNoiseLite = FastNoiseLite.new()
## Original position of the node, this is used to return the node to its
## original position when the effect stops.
var original_position: Vector2
## Original rotation of the node, this is used to return the node to its
## original rotation when the effect stops.
var original_rotation: float
## Time incremented every frame of the effect to sample a different
## value from the noise.
var time_passed: float = 0.0
## How much the noise value (which goes from -1 to 1) is amplified.
## It decreases since the shake starts until it reaches 0.
var current_intensity: float = 0.0
## Reference to the tween that will decrease the [member current_intensity]
var shake_tween: Tween


func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 1.0


## Shake the node's position by a maximum of [param intensity] and rotation by
## a maximum of [param intensity] * 0.01 during [param time].
## When the effect finishes, [member target]'s position and rotation end up
## at the same values it had before the effect started. [br]
## If shake is called a second time before it finishes, the new effect will
## override the previous one, and when that shake effect finishes,
## the [member target]'s position and rotation will end up at the values it
## had before the first shake effect started. [br]
## Emits the [signal started] signal as soon as it's called. [br]
## If the shake is called multiple times, it will only emit the [signal
## finished] signal when the last effect is completed.
func shake(intensity: float = shake_intensity, time: float = duration):
	noise.seed = randi()
	started.emit()
	var shaking_already_in_progress: bool = shake_tween and shake_tween.is_valid()
	if shaking_already_in_progress:
		shake_tween.kill()
	else:
		if target is Camera2D:
			original_position = target.offset
		else:
			original_position = target.position
		original_rotation = target.rotation
	shake_tween = create_tween()
	time_passed = 0.0
	await shake_tween.tween_property(self, "current_intensity", 0.0, time).from(intensity).finished
	shake_tween.kill()
	target.position = Vector2(original_position.x, original_position.y)
	rotation = original_rotation
	finished.emit()


func _process(delta):
	if current_intensity > 0.0:
		time_passed += delta * frequency
		var offset_x = noise.get_noise_1d(time_passed) * current_intensity
		var offset_y = noise.get_noise_1d(time_passed + 100) * current_intensity
		var rotation_offset = noise.get_noise_1d(time_passed + 200) * current_intensity * 0.01

		var new_position = Vector2(original_position.x + offset_x, original_position.y + offset_y)
		var new_rotation = original_rotation + rotation_offset
		if target is Camera2D:
			target.offset = new_position
		else:
			target.position = new_position
		target.rotation = original_rotation + rotation_offset
