extends Node2D
@onready var enemy_guards: Node2D = $EnemyGuards
@onready var transition_color: ColorRect = %TransitionColor
@onready var first_checkpoint: Marker2D = %FirstOne

func _ready():
	await create_tween().tween_property(transition_color, "color:a", 0.0, 0.5).from(1.0).finished
	for node in enemy_guards.get_children():
		var guard = node as Guard
		if guard:
			guard.player_detected.connect(self.on_player_detected)

func on_player_detected(player):
	%CameraShaker.start(0.5)
	player.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	await get_tree().create_timer(2.0).timeout
	await create_tween().tween_property(transition_color, "color:a", 1.0, 0.5).finished
	get_tree().reload_current_scene()
