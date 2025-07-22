extends Control

signal analog_input(analog: Vector2, activated: bool)

@export var radius = 120
@export var action_radius = 200
@export var dead_zone = 0.1

var mouse_pos = Vector2()


func _ready() -> void:
	get_viewport().warp_mouse(position)
	# Input.warp_mouse(position)


func _unhandled_input(_event: InputEvent) -> void:
	if not _event is InputEventMouseMotion:
		return
	var activated: bool = false
	var local_mouse = get_local_mouse_position()
	if local_mouse.length() <= radius:
		mouse_pos = local_mouse
	else:
		if local_mouse.length() >= action_radius:
			activated = true
		mouse_pos = local_mouse.normalized() * radius

	var analog = Vector2(mouse_pos.x / radius, mouse_pos.y / radius)
	if analog.length() > dead_zone:
		analog_input.emit(analog, activated)
	else:
		analog_input.emit(Vector2.ZERO, activated)
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0, 360, 40, Color.WHITE, 5, true)
	draw_arc(Vector2.ZERO, action_radius, 0, 360, 40, Color.WHITE, 5, true)
	draw_circle(Vector2.ZERO, dead_zone * 100, Color.RED)
	draw_circle(mouse_pos, 10, Color.WHITE)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DISABLED:
			analog_input.emit(Vector2.ZERO, false)
		NOTIFICATION_ENABLED:
			get_viewport().warp_mouse(position)
			# Input.warp_mouse(position)
