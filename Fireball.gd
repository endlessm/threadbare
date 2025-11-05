extends Area2D
class_name Fireball

@export var speed := 250.0
var direction := Vector2.ZERO
var can_be_parried := true
var was_reflected := false
var reflected_by: Node2D

func _ready():
	# Temporizador de vida útil
	var timer := Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

	body_entered.connect(_on_body_entered)
	print("🔥 Fireball creada en:", global_position)

func shoot_toward(target_pos: Vector2):
	direction = (target_pos - global_position).normalized()
	rotation = direction.angle()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# 🔹 Reflejar si toca jugador y el jugador está presionando 'repel'
	if body.is_in_group("player") and can_be_parried and not was_reflected:
		if Input.is_action_pressed("repel"):
			_reflect(body)
			return
		else:
			if body.has_method("take_damage"):
				body.take_damage(10)
			queue_free()
			return

# 🔹 Si la fireball reflejada toca a un enemigo o al boss
		if was_reflected and (body.is_in_group("throwing_enemy") or body.name == "FireBoss"):
			if body.has_method("take_damage"):
				body.take_damage(20)
				print("🔥 Fireball reflejada golpeó a", body.name)
	queue_free()


	# 🔹 Se destruye si choca con paredes
	if body.is_in_group("walls"):
		queue_free()

func _reflect(player: Node2D):
	was_reflected = true
	can_be_parried = false
	reflected_by = player
	direction = -direction.normalized()
	modulate = Color(0.5, 1.0, 1.0)
	speed *= 1.2  # un poco más rápida al reflejar
	print("🪞 Fireball reflejada por jugador:", player.name)
