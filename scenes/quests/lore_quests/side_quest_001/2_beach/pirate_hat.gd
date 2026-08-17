extends Area2D

var skeleton_pirate: Node = null

func give_hat_to_skeleton() -> void:
	if skeleton_pirate != null:
		skeleton_pirate.got_hat = true
		skeleton_pirate.put_hat_on()

	hide()
