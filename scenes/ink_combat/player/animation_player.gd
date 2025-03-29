extends AnimationPlayer

var cancellable: bool = false

@onready var player: FightingPlayer = owner
@onready var player_fighting: Node2D = %PlayerFighting


func _process(_delta: float) -> void:
	if current_animation == &"blow_right":
		return

	if not player_fighting.is_fighting:
		if player.velocity.is_zero_approx():
			play(&"idle")
		else:
			play(&"walk")
		return

	play(&"blow_right")
	#if is_playing() and current_animation_position > 0.3:
	#cancellable = true
	#return
