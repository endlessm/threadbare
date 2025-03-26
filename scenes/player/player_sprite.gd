extends AnimatedSprite2D

@onready var player: Player = owner


func _process(_delta: float) -> void:
	if not player:
		return
	if player.velocity.is_zero_approx():
		return
	if not is_zero_approx(player.velocity.x):
		flip_h = player.velocity.x < 0
