extends Polygon2D

@export var defense: Node
@export var min_distance := 150.0


func _ready():

	var tween = create_tween()

	tween.set_loops()

	tween.tween_property(
		self,
		"scale",
		Vector2(1.2, 1.2),
		0.5
	)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.5
	)


func _process(_delta):

	var player = get_parent()

	var target_position: Vector2

	if defense.game_finished:

		if not is_instance_valid(defense.collectible_item):
			visible = false
			return

		target_position = defense.collectible_item.global_position

	elif defense.current_zone != null:

		target_position = defense.current_zone.global_position

	else:

		visible = false
		return

	var direction = (
		target_position
		- player.global_position
	)

	visible = direction.length() > min_distance

	rotation = direction.angle() + PI / 2
