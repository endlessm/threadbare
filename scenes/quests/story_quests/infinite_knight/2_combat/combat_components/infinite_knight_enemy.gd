extends CharacterBody2D

signal died

@export var speed: float = 70.0
var player_target: Node2D = null 
var hp: int = 2

var is_stunned: bool = false
var is_attacking: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_target):
		if not is_stunned and not is_attacking:
			anim.play("idle")
		return
		
	var direction: Vector2 = global_position.direction_to(player_target.global_position)
		
	if is_stunned:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	elif is_attacking:
		velocity = Vector2.ZERO 
	else:
		velocity = direction * speed
		if direction.x != 0:
			anim.flip_h = direction.x < 0
		anim.play("walk")
			
	move_and_slide()
	
	if is_stunned or is_attacking or get_slide_collision_count() == 0:
		return
		
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		
		if collider == player_target:
			_perform_attack(direction)
			break

func _perform_attack(hit_direction: Vector2) -> void:
	is_attacking = true
	anim.play("idle") 
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_instance_valid(self) or is_stunned:
		is_attacking = false
		return
		
	anim.play("alerted")
		
	# Valida la distancia de impacto tras el delay
	if is_instance_valid(player_target) and global_position.distance_to(player_target.global_position) < 85.0:
		var arena: Node = get_tree().current_scene
		if arena.has_method("damage_player"):
			arena.damage_player()
			
	is_stunned = true
	knockback_velocity = -hit_direction * 50.0
	
	await get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(self):
		is_stunned = false
		is_attacking = false

func receive_damage() -> void:
	hp -= 1
	if hp <= 0:
		var arena: Node = get_tree().current_scene
		if arena.has_method("on_enemy_defeated"):
			arena.on_enemy_defeated()
			
		died.emit()
		queue_free()

func got_repelled(push_direction: Vector2) -> void:
	var is_valid_hit: bool = false
	
	if is_instance_valid(player_target):
		var player_facing_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if player_facing_dir == Vector2.ZERO:
			var p_sprite: Node = player_target.find_child("PlayerSprite", true, false)
			if p_sprite and p_sprite.flip_h:
				player_facing_dir = Vector2.LEFT
			else:
				player_facing_dir = Vector2.RIGHT
		
		# Indica un golpe direccional valido (semi-frontal)
		if push_direction.dot(player_facing_dir.normalized()) >= 0.1:
			is_valid_hit = true
			
	if not is_valid_hit:
		return

	receive_damage()
	
	if hp > 0:
		is_stunned = true
		knockback_velocity = push_direction * 200.0 
		anim.play("alerted")
		
		await get_tree().create_timer(0.5).timeout
		
		if is_instance_valid(self):
			is_stunned = false
