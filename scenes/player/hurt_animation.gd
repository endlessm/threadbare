extends AnimationPlayer

@onready var player_fighting: PlayerFighting = %PlayerFighting

func _ready() -> void:
	player_fighting.got_hit.connect(_on_got_hit)
	
func _on_got_hit() -> void:
	play(&"got hit")
