# eco_base.gd
extends CharacterBody2D

signal player_detected

var player_in_area: bool = false
var player: CharacterBody2D = null

func _ready() -> void:
	$Area2D.body_entered.connect(_on_area_2d_body_entered)
	$Area2D.body_exited.connect(_on_area_2d_body_exited)

func _physics_process(delta: float) -> void:
	if player_in_area and player != null:
		$RayCast2D.target_position = to_local(player.global_position)
		$RayCast2D.force_raycast_update()

		if $RayCast2D.is_colliding():
			var collider = $RayCast2D.get_collider()
			if collider.is_in_group("player"):
				player_detected.emit()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		player = null
