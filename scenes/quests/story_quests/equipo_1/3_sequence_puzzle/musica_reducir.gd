extends AudioStreamPlayer
@export var volumen:float
func _ready() -> void:
	self.volume_db = volumen 
