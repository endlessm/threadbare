extends Node2D

@export var hook_string_texture: Texture2D = preload("res://scenes/hook-string.png")

var hook_angle: float
var hook_string: Line2D

@onready var player: Player = self.owner as Player
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	pass


func add_string() -> void:
	if not ray_cast_2d.is_colliding():
		return
	var hookable = ray_cast_2d.get_collider() as HookableArea
	if not hookable:
		return
	var p = hookable.get_hooking_point()

	if hook_string:
		hook_string.queue_free()
	hook_string = Line2D.new()
	hook_string.width = 16
	hook_string.texture = hook_string_texture
	hook_string.texture_mode = Line2D.LINE_TEXTURE_TILE
	hook_string.joint_mode = Line2D.LINE_JOINT_ROUND
	hook_string.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# hook_string.add_point(Vector2(300, 0).rotated(rotation))
	hook_string.add_point(p - player.global_position - position)
	hook_string.add_point(Vector2.ZERO)
	# hook_string.z_index = player.z_index - 1
	player.add_sibling(hook_string)
	hook_string.owner = player.owner
	hook_string.position = player.position + position


func _unhandled_input(_event: InputEvent) -> void:
	if _event is InputEventMouseButton and _event.is_pressed():
		add_string()
	var axis: Vector2
	if _event is InputEventMouseMotion:
		axis = get_global_mouse_position() - global_position
	else:
		axis = Input.get_vector(&"hook_left", &"hook_right", &"hook_up", &"hook_down")

	if not axis.is_zero_approx():
		hook_angle = axis.angle()


func _process(_delta: float) -> void:
	rotation = hook_angle
	if ray_cast_2d.is_colliding():
		sprite_2d.modulate = Color.WHITE
	else:
		sprite_2d.modulate = Color(Color.WHITE, 0.2)

	if hook_string:
		hook_string.points[-1] = player.position + position - hook_string.position
