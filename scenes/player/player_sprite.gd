extends AnimatedSprite2D

@export var player: Player
@onready var fight_animation: AnimationPlayer = %FightAnimation

@onready var player_fighting: PlayerFighting = %PlayerFighting

func _ready() -> void:
	if not player and owner is Player:
		player = owner

func _process(_delta: float) -> void:
	if fight_animation.is_playing():
		return
	if player.velocity.is_zero_approx():
		play(&"idle")
	else:
		if not is_zero_approx(player.velocity.x):
			flip_h = player.velocity.x < 0
		play(&"walk")
