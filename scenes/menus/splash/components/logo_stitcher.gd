# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name LogoStitcher
extends Node2D
## Simulates stitching along a continuous path with variable width, in order to draw the Endless
## logo (though other things could be animated in the same way).

## Emitted when the animation finishes.
signal finished

## The path tracing the centre-line of the logo
@export var path: Path2D

## The peak width of the logo swirl in pixels
@export_range(50, 150, 1.0, "suffix:px") var max_width: float = 105

## Unit curve describing the relative width of the logo swirl
@export var width_curve: Curve

## Colour to stitch the logo with
@export var color: Color = Color.LIGHT_GRAY

## Number of stitches to use. The actual number of stitches will be twice this (minus one) since a
## diagonal stitch is added between each generated stitch.
@export_range(100, 500, 25, "or_greater") var stitch_count: int = 350

## Width of each stitch
@export_range(0.1, 2.0, 0.1, "or_greater", "or_less", "suffix:px") var stitch_width: float = 1.2

## Duration of the animation. Ignored at runtime if [member audio] is set.
@export_range(1.0, 20.0, 0.1, "or_greater", "suffix:s") var duration: float = 4.1

## Sewing sound effect. If set, [member duration] will be adjusted to match the length of this sound
@export var audio: AudioStreamPlayer

## How much randomness to add to each end of each stitch
@export_range(0, 10, 0.25, "suffix:px") var perturbation: float = 5.0

## Update the stitch data (including new random perturbations) and rerun the animation
@export_tool_button("Rerun animation") var restart: Callable = _restart

var _progress: float = 0
var _stitch_points: PackedVector2Array

## Line to visualise the combination of [member path], [member max_width] and
## [member width_curve] during development. Not shown in game.
var _line: Line2D


func _ready() -> void:
	if not Engine.is_editor_hint() and audio:
		duration = audio.stream.get_length() / audio.pitch_scale
		audio.play()

	_update()


func _restart() -> void:
	_progress = 0
	_update()
	if not Engine.is_editor_hint():
		audio.play()


func _update_debug_line() -> void:
	if not path:
		if _line:
			_line.queue_free()
			_line = null

		return

	if not _line:
		_line = Line2D.new()
		_line.default_color = Color(0.28, 1, 0.844, 0.254902)
		add_child(_line)

	_line.points = path.curve.get_baked_points()
	_line.width_curve = width_curve
	_line.width = max_width
	_line.width_curve = width_curve


func _update() -> void:
	if Engine.is_editor_hint():
		_update_debug_line()

	_stitch_points.clear()
	var length: float = path.curve.get_baked_length()
	var last: Vector2
	for i: int in range(stitch_count):
		var progress: float = float(i) / (stitch_count - 1)

		var offset: float = progress * length
		var sample: Transform2D = path.curve.sample_baked_with_rotation(offset)
		var width: float = width_curve.sample_baked(progress) * max_width

		var point: Vector2 = sample.origin
		# Unit vector perpendicular to the line at this point
		var tangent: Vector2 = sample.y

		var p1: Vector2 = _perturb(point + (tangent * width / 2))
		var p2: Vector2 = _perturb(point - (tangent * width / 2))
		if last:
			_stitch_points.append(last)
			_stitch_points.append(p1)

		_stitch_points.append(p1)
		_stitch_points.append(p2)
		last = p2


func _process(delta: float) -> void:
	if _progress < duration:
		_progress += delta
		queue_redraw()

		if _progress >= duration:
			# In the web build, audio may not play until the user clicks the mouse or presses a key.
			# So even though the animation is synched to the duration of the sound effect, the effect
			# may have started playing some time after the animation started. Explicitly stop it so that
			# it ends when the animation ends.
			audio.stop()
			finished.emit()


func _perturb(v: Vector2) -> Vector2:
	var angle: float = randf_range(0, TAU)
	return v + randf_range(0, perturbation) * Vector2.from_angle(angle)


func _draw() -> void:
	var l: int = _stitch_points.size()
	assert(l % 2 == 0)
	l /= 2
	var j: int = ceil(l * (_progress / duration))

	var points: PackedVector2Array = _stitch_points.slice(0, j * 2)
	if not points:
		return

	draw_multiline(points, color, stitch_width, true)

	# Round the ends of each stitch
	for point: Vector2 in points:
		draw_circle(point, stitch_width / 2, color, true, -1.0, true)
