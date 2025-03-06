extends AnimationPlayer

@onready var player_fighting: PlayerFighting = %PlayerFighting

func _process(delta: float) -> void:
	if player_fighting.is_fighting:
		play(&"shield")
