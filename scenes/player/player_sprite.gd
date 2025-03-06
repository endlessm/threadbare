extends AnimatedSprite2D

@export var player: Player

@onready var player_fighting: PlayerFighting = %PlayerFighting
var angle: float = 0

func _ready() -> void:
	if not player and owner is Player:
		player = owner

func _process_fighting() -> void:
	var current_frame = 0
	var current_frame_progress = 0
	if animation in [&"action side A", &"action up A", &"action down A"]:
		current_frame = frame
		current_frame_progress = frame_progress
	flip_h = abs(angle) > PI/2
	if abs(-PI/2 - angle) <= PI/3.9:
		play(&"action up A")
	elif abs(PI/2 - angle) <= PI/3.9:
		play(&"action down A")
	elif abs(PI - angle) <= PI/3.9:
		play(&"action side A")
	elif abs(angle) <= PI/3.9:
		play(&"action side A")
		
	set_frame_and_progress(current_frame, current_frame_progress)

func _process(_delta: float) -> void:
	if not player:
		return
	if not player.axis.is_zero_approx():
		angle = player.axis.angle()
	if player_fighting.is_fighting:
		_process_fighting()
		return
	if player.velocity.is_zero_approx():
		play(&"idle")
	else:
		if not is_zero_approx(player.velocity.x):
			flip_h = player.velocity.x < 0
		play(&"walk")
