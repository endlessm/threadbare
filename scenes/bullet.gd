extends RigidBody2D

enum INK_COLOR_NAMES {
		CYAN = 0,
		MAGENTA = 1,
		YELLOW = 2,
		BLACK = 3,
}

const INK_COLORS = {
		INK_COLOR_NAMES.CYAN: Color(0., 1., 1.),
		INK_COLOR_NAMES.MAGENTA: Color(1., 0., 1.),
		INK_COLOR_NAMES.YELLOW: Color(1., 1., 0.),
		INK_COLOR_NAMES.BLACK: Color(0.2, 0.2, 0.2),
}

# @export var ink_color: Color = INK_COLORS[INK_COLOR_NAMES.CYAN]

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0

@onready var visible_things: Node2D = %VisibleThings


func _ready() -> void:
	var color: Color = INK_COLORS[ink_color_name]
	visible_things.modulate = color
	var impulse = Vector2(0, -60).rotated(randf_range(-PI/16, PI/16))
	apply_impulse(impulse)

func _process(delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	

func _on_body_entered(body: Node2D) -> void:
	var hit_vector = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)
	if body.owner is Enemy:
		body.owner.got_hit(global_position, hit_vector)
