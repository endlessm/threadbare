extends Projectile

@export var extra_speed := 350

func _ready():
	speed = extra_speed
	duration = 5
