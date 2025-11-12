extends CharacterBody2D

@export var speed: float = 200.0
@export var max_health: int = 150
@export var invulnerability_time: float = 1.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var current_health: int = 0
var invulnerable: bool = false
var is_dead: bool = false

func _ready() -> void:
	animated_sprite.play("idle")
	add_to_group("player")
	current_health = max_health
	var invul_timer: Timer = Timer.new()
	invul_timer.name = "InvulTimer"
	invul_timer.one_shot = true
	invul_timer.wait_time = invulnerability_time
	add_child(invul_timer)
	invul_timer.timeout.connect(_on_invul_timeout)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	var dir: Vector2 = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = dir.normalized() * speed
	if velocity.is_zero_approx():
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		if dir.x != 0:
			animated_sprite.flip_h = (dir.x < 0)
	move_and_slide()

func take_damage(amount: int) -> void:
	if invulnerable or current_health <= 0 or is_dead:
		return
	current_health -= amount
	print("💥 Jugador recibió ", amount, " de daño. Vida restante:", current_health)
	invulnerable = true
	$InvulTimer.start()
	blink()
	if current_health <= 0:
		die()

func _on_invul_timeout() -> void:
	invulnerable = false
	modulate = Color(1, 1, 1)

func blink() -> void:
	var blink_tween: Tween = get_tree().create_tween()
	blink_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.3), 0.1)
	blink_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	blink_tween.set_loops(5)

func die() -> void:
	if is_dead: 
		return 
	is_dead = true
	print("💀 Jugador derrotado")
	velocity = Vector2.ZERO 
	animated_sprite.play("defeated") 
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
