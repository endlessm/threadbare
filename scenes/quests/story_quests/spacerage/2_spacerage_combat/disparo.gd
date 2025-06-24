extends CharacterBody2D
@export var speed = 500
var daño = 3
var direccion =Vector2.ZERO

func _physics_process(delta):
	velocity=direccion * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		print("La bala chocó con algo:", collision.get_collider())
		var objetivo = collision.get_collider()
		
		if objetivo.has_method("recibir_daño"):
			objetivo.recibir_daño(daño)
		queue_free()
