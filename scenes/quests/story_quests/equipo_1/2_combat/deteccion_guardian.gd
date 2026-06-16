extends Area2D
signal event
func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	print("ENTRO UN AREA")
	if area ==%ReanudarPlayer:
		%Player.process_mode= Node.PROCESS_MODE_INHERIT
