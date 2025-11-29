extends CharacterBody2D

@export var puzzle: SequencePuzzle
@export var resting_position: Marker2D
@export var path_walk_behavior: PathWalkBehavior

var path: Path2D


func _ready() -> void:
	path = Path2D.new()
	get_parent().add_child.call_deferred(path)
	#hint.call_deferred()


func hint() -> void:
	if puzzle.is_solved():
		return

	var curve := Curve2D.new()

	# TODO: strictly speaking we need to make these positions be local to get_parent().
	assert(get_parent().position == Vector2.ZERO)
	curve.add_point(global_position, Vector2.ZERO, Vector2(64, -192))

	var step := puzzle.steps[puzzle.get_progress()]
	var sequence := step.sequence
	for object: SequencePuzzleObject in sequence:
		curve.add_point(object.global_position, Vector2(-32, -192), Vector2(32, -192))

	curve.add_point(resting_position.global_position, Vector2(-64, -192))

	path.curve = curve
	path_walk_behavior.walking_path = path

	path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT

	# The start of the path is pointy
	await path_walk_behavior.pointy_path_reached

	for object: SequencePuzzleObject in sequence:
		await path_walk_behavior.pointy_path_reached
		object.play(true)

	await path_walk_behavior.ending_reached
	path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
