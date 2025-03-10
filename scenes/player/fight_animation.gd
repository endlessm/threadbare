extends AnimationPlayer


@onready var player_fighting: PlayerFighting = %PlayerFighting

var player: Player
var angle: float = 0
var cancellable: bool = false

func _ready() -> void:
	if owner is Player:
		player = owner

func _process(delta: float) -> void:
	if not player:
		return

	if not is_playing() and not player_fighting.is_fighting:
		cancellable = false
		
	if is_playing() and current_animation_position > 0.3:
		cancellable = true
		return

	if not player_fighting.is_fighting:
		if is_playing() and cancellable and current_animation_position <= 0.3:
			stop()
		return
	
	angle = player.last_nonzero_axis.angle()

	if abs(-PI/2 - angle) <= PI/3.9:
		play(&"push up")
	elif abs(PI/2 - angle) <= PI/3.9:
		play(&"push down")
	elif abs(PI - angle) <= PI/3.9:
		play(&"push left")
	elif abs(angle) <= PI/3.9:
		play(&"push right")
