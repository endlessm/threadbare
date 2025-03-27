extends RayCast2D

@export var character: CharacterBody2D

var _target_position_right: Vector2
var _target_position_left: Vector2


func _ready() -> void:
	_target_position_right = target_position
	_target_position_left = target_position.reflect(Vector2.UP)
	if not character and owner is CharacterBody2D:
		character = owner


func interact_area() -> InteractArea:
	if is_colliding():
		return get_collider() as InteractArea
	return null


func _process(_delta: float) -> void:
	if not character:
		return
	if not enabled:
		return
	if not is_zero_approx(character.velocity.x):
		if character.velocity.x < 0:
			target_position = _target_position_left
		else:
			target_position = _target_position_right
