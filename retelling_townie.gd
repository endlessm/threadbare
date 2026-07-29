# Minimum and maximum speed bounds to ensure cutscene pacing remains fast and natural
const MIN_TOWNIE_WALK_SPEED: float = 85.0
const MAX_TOWNIE_WALK_SPEED: float = 120.0

func _setup_townie_path_walk() -> void:
	# Randomize the speed of each townie within a higher minimum threshold for variation without dragging
	var r: float = randf_range(MIN_TOWNIE_WALK_SPEED, MAX_TOWNIE_WALK_SPEED)
	
	path_walk_behavior.speeds = CharacterSpeeds.new()
	path_walk_behavior.speeds.walk_speed = r