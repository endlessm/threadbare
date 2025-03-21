extends Node2D

var is_player_hiding_in_it: bool

func _ready():
	$HidingArea.interaction_started.connect(self.on_player_interaction_started)
	$Sprite2D2.z_as_relative = false

func on_player_interaction_started():
	var player = $HidingArea.get_overlapping_bodies().front()
	if is_player_hiding_in_it:
		create_tween().tween_property(player, "modulate:a", 1.0, 0.3)
		$Sprite2D2.z_index = player.z_index - 1
	else:
		create_tween().tween_property(player, "modulate:a", 0.7, 0.5)
		#create_tween().tween_property(player, "global_position", $HidingArea.global_position, 0.3)
		$Sprite2D2.z_index = player.z_index + 1
	is_player_hiding_in_it = !is_player_hiding_in_it
	player.set_meta("hiding", is_player_hiding_in_it)
	$HidingArea.end_interaction.call_deferred()

func _process(delta: float) -> void:
	$HidingArea.action = "Unhide" if is_player_hiding_in_it else "Hide"
