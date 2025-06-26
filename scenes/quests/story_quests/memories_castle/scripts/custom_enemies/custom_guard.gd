class_name CustomGuard extends Guard

@export var max_health: float = 100
var health: float = max_health

func recive_damage(lost_live = 0) -> void:
	health -= lost_live
	print("Recibió daño: ", health, " - ", lost_live)
	if health <= 0:
		self.remove()

func remove()  -> void:
	set_physics_process(false)
	self.queue_free()
