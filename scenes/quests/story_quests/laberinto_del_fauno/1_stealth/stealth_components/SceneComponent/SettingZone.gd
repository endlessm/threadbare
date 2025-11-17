extends Node2D

func Zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.walk_speed *= 0.45
		body.run_speed *= 0.45

func Zone_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.walk_speed /= 0.45
		body.run_speed /= 0.45


func Zone1Attack(_body: Node2D) -> void:
	$"../Enemy/Zone1/Sapo1/Timer".start()
	$"../Enemy/Zone1/Sapo2/Timer".start()


func Zone1Stopt(_body: Node2D) -> void:
	$"../Enemy/Zone1/Sapo1/Timer".stop()
	$"../Enemy/Zone1/Sapo2/Timer".stop()

func Zone2Attack(_body: Node2D) -> void:
	$"../Enemy/Zone2/Sapo1/Timer".start()
	$"../Enemy/Zone2/Sapo2/Timer".start()
	$"../Enemy/Zone2/Sapo3/Timer".start()
	$"../Enemy/Zone2/Sapo4/Timer".start()


func Zone2Stopt(_body: Node2D) -> void:
	$"../Enemy/Zone2/Sapo1/Timer".stop()
	$"../Enemy/Zone2/Sapo2/Timer".stop()
	$"../Enemy/Zone2/Sapo3/Timer".stop()
	$"../Enemy/Zone2/Sapo4/Timer".stop()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.pos = $"../Checkpoint/Zona2".global_position
