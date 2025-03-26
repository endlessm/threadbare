extends AnimationPlayer

@onready var player: Player = owner


func _process(_delta: float) -> void:
	if player.velocity.is_zero_approx():
		play(&"idle")
	else:
		play(&"walk")
