class_name PlayerHook
extends Node2D

signal string_thrown

const NON_WALKABLE_FLOOR_LAYER: int = 10

@export_range(0.0, 500.0, 1.0, "or_greater") var string_throw_length: float = 200.0
@export_range(0.0, 500.0, 1.0, "or_greater") var string_max_length: float = 300.0
@export_range(0.0, 500.0, 1.0, "or_greater") var string_min_length: float = 10.0
@export_range(0.0, 500.0, 1.0, "or_greater") var string_stop_pulling_length: float = 10.0
@export var full_stop_after_pull: bool = true
@export_range(0.0, 5000.0, 1.0, "or_greater", "or_less") var pull_velocity: float = 1500.0
@export_range(0.0, 1.0, 0.1) var bounce_amount_when_stuck: float = 0.5
@export var hook_string_texture: Texture2D = preload("res://scenes/hook-string.png")

var hooked_to: HookableArea
var pulling: bool = false
var hook_angle: float
var hook_string: Line2D

@onready var player: Player = self.owner as Player
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	ray_cast_2d.target_position = Vector2(string_throw_length, 0)


func throw_string() -> void:
	if not ray_cast_2d.is_colliding():
		pass
		# return
	hooked_to = ray_cast_2d.get_collider() as HookableArea

	string_thrown.emit()

	var p: Vector2
	if hooked_to:
		p = hooked_to.get_hooking_point() - player.global_position - position
	else:
		p = Vector2(string_throw_length, 0).rotated(hook_angle)

	if hook_string:
		hook_string.queue_free()

	hook_string = Line2D.new()
	hook_string.width = 16
	hook_string.texture = hook_string_texture
	hook_string.texture_mode = Line2D.LINE_TEXTURE_TILE
	hook_string.joint_mode = Line2D.LINE_JOINT_ROUND
	hook_string.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	hook_string.add_point(p)
	hook_string.add_point(Vector2.ZERO)
	player.add_sibling(hook_string)
	hook_string.owner = player.owner
	hook_string.position = player.position + position


func remove_string() -> void:
	if pulling:
		return
	if hook_string:
		hook_string.queue_free()
	hooked_to = null


func pull_string() -> void:
	pulling = true
	player.set_collision_mask_value(NON_WALKABLE_FLOOR_LAYER, false)


func stop_pulling() -> void:
	player.set_collision_mask_value(NON_WALKABLE_FLOOR_LAYER, true)
	pulling = false
	remove_string()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"repel") and hook_string:
		remove_string()
		return

	if Input.is_action_just_pressed(&"throw"):
		if hooked_to:
			pull_string()
		else:
			throw_string()
		return

	var axis: Vector2
	if _event is InputEventMouseMotion:
		axis = get_global_mouse_position() - global_position
	else:
		axis = Input.get_vector(&"hook_left", &"hook_right", &"hook_up", &"hook_down")

	if not axis.is_zero_approx():
		hook_angle = axis.angle()


func _process(delta: float) -> void:
	rotation = hook_angle

	if ray_cast_2d.is_colliding():
		sprite_2d.modulate = Color.WHITE
	else:
		sprite_2d.modulate = Color(Color.WHITE, 0.2)

	if hook_string:
		hook_string.points[-1] = player.position + position - hook_string.position
		if hooked_to:
			hook_string.points[0] = hooked_to.get_hooking_point() - hook_string.position
		else:
			hook_string.points[-2] = hook_string.points[-2].move_toward(
				hook_string.points[-1], delta * 500
			)
			if (
				(hook_string.points[-2] - hook_string.points[-1]).length_squared()
				< string_min_length * string_min_length
			):
				hook_string.queue_free()

	if not pulling:
		if hook_string:
			var v: Vector2 = hook_string.points[0] - hook_string.points[-1]
			if v.length_squared() > string_max_length * string_max_length:
				remove_string()

	else:
		if not is_instance_valid(hooked_to):
			stop_pulling()
			return
		var target = hooked_to.owner
		var weight = hooked_to.weight if target is CharacterBody2D else 1.0
		# vector from player to first point
		var v1: Vector2 = (hook_string.points[-2] - hook_string.points[-1]) * weight

		# vector from target to previous point
		var v2: Vector2 = (hook_string.points[1] - hook_string.points[0]) * (1 - weight)

		if v1 != Vector2.ZERO:
			if v1.length_squared() < string_stop_pulling_length * string_stop_pulling_length:
				if full_stop_after_pull:
					player.velocity = Vector2.ZERO
				stop_pulling()
				return

		if v2 != Vector2.ZERO:
			if v2.length_squared() < string_stop_pulling_length * string_stop_pulling_length:
				if full_stop_after_pull:
					target.velocity = Vector2.ZERO
				stop_pulling()
				return

		player.velocity = v1.normalized() * pull_velocity * weight
		player.move_and_slide()

		if target is CharacterBody2D:
			target.velocity = v2.normalized() * pull_velocity * (1 - weight)
			target.move_and_slide()

		var stuck_tolerance = 400.0
		var player_collision: KinematicCollision2D = player.get_last_slide_collision()
		if (
			player_collision
			and (
				player_collision.get_travel().length_squared()
				< player_collision.get_remainder().length_squared() / stuck_tolerance
			)
		):
			player.velocity *= -1 * bounce_amount_when_stuck
			stop_pulling()

		if target is CharacterBody2D:
			var target_collision: KinematicCollision2D = target.get_last_slide_collision()
			if (
				target_collision
				and (
					target_collision.get_travel().length_squared()
					< target_collision.get_remainder().length_squared() / stuck_tolerance
				)
			):
				target.velocity *= -1 * bounce_amount_when_stuck
				stop_pulling()
