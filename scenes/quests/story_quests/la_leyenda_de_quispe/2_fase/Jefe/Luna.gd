extends CharacterBody2D

@export var speed: float = 70.0
@export var move_distance: float = 250.0
@export var max_health: int = 3400
@export var invulnerability_time: float = 1.0
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 300.0
@export var random_fire_range: Vector2 = Vector2(1.0, 3.0)
@export var shoot_direction: Vector2 = Vector2.LEFT
@export var aim_at_player: bool = true
@export var fan_shot_angle: float = 40.0
@export var fan_shot_count: int = 7
@export var fan_shot_chance: float = 0.4
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.4
@export var dash_chance: float = 0.3
@export var dash_damage: int = 25
@export var dialogue_resource: DialogueResource
@export_group("Efecto de Vuelo")
@export var hover_amplitude: float = 5.0
@export var hover_speed: float = 2.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point: Marker2D = $SpawnPoint 
var player_node: Node2D = null
var is_dialogue_running: bool = false
var has_intro_played: bool = false
var player_in_range: bool = false
var start_position: Vector2
var moving_right: bool = true
var current_health: int = 0
var invulnerable: bool = false
var hits_taken: int = 0
var is_dead: bool = false
var is_attacking: bool = false
var is_returning: bool = false
var is_dashing: bool = false
var dash_target_direction: Vector2 = Vector2.ZERO
var is_transforming: bool = true 
var hover_timer: float = 0.0

func _ready() -> void:
	randomize()
	start_position = position
	current_health = max_health
	add_to_group("boss")
	if $Area2D:
		$Area2D.body_entered.connect(_on_Area2D_body_entered)
		$Area2D.body_exited.connect(_on_Area2D_body_exited)
	else:
		push_error("❌ No se encontró el nodo Area2D en el jefe")
	if not $ShootTimer:
		push_error("❌ Falta el nodo Timer llamado 'ShootTimer'.")
		return
	$ShootTimer.wait_time = randf_range(random_fire_range.x, random_fire_range.y)
	if not $ShootTimer.timeout.is_connected(_on_shoot_timer_timeout):
		$ShootTimer.timeout.connect(_on_shoot_timer_timeout)
	$ShootTimer.stop()
	if not has_node("InvulTimer"):
		var invul_timer: Timer = Timer.new()
		invul_timer.name = "InvulTimer"
		invul_timer.one_shot = true
		invul_timer.wait_time = invulnerability_time
		add_child(invul_timer)
		invul_timer.timeout.connect(_on_invul_timeout)
	print("🌀 Iniciando Fase 2: Secuencia de Transformación...")
	is_transforming = true
	invulnerable = true
	$ShootTimer.stop()
	await start_intro_sequence()
	print("🔥 Transformación completa. ¡Combate iniciado!")
	is_transforming = false
	invulnerable = false
	var reference_size: Vector2 = get_visual_size("Transformacion2")
	play_anim_scaled("Luna", reference_size) 
	if player_in_range and has_intro_played:
		$ShootTimer.start()

func _process(delta: float) -> void:
	if is_dead or is_dialogue_running:
		return
	if is_transforming:
		return
	if is_dashing:
		animated_sprite.position.y = 0
		if spawn_point: spawn_point.position.y = 0
		velocity = dash_target_direction * dash_speed
		move_and_slide()
		var collision: KinematicCollision2D = get_last_slide_collision()
		if collision and collision.get_collider().is_in_group("player"):
			print("💥 ¡Embestida golpeó al jugador!")
			if collision.get_collider().has_method("take_damage"):
				collision.get_collider().take_damage(dash_damage)
			stop_dash()
		return
	aplicar_efecto_vuelo(delta)
	if is_attacking:
		return
	var target_y: float = start_position.y
	var y_difference: float = target_y - global_position.y
	if abs(y_difference) > 1.0:
		is_returning = true
		return_to_lane(delta, y_difference)
	else:
		is_returning = false
		move_side_to_side(delta)

func aplicar_efecto_vuelo(delta: float) -> void:
	hover_timer += delta
	var visual_offset_y: float = sin(hover_timer * hover_speed) * hover_amplitude
	animated_sprite.position.y = visual_offset_y
	if spawn_point:
		spawn_point.position.y = visual_offset_y

func start_intro_sequence() -> void:
	var reference_size: Vector2 = get_visual_size("Transformacion2")
	play_anim_scaled("Transformacion", reference_size)
	await animated_sprite.animation_finished
	play_anim_scaled("Transformacion2", reference_size)
	await animated_sprite.animation_finished
	play_anim_scaled("Transicion", reference_size)
	await get_tree().create_timer(2.0).timeout 
	play_anim_scaled("Luna", reference_size)
	await get_tree().create_timer(1.5).timeout

func get_visual_size(anim_name: String) -> Vector2:
	var frames: SpriteFrames = animated_sprite.sprite_frames
	if frames.has_animation(anim_name):
		var texture: Texture2D = frames.get_frame_texture(anim_name, 0)
		if texture: return texture.get_size()
	return Vector2(100, 100)

func play_anim_scaled(anim_name: String, target_size: Vector2) -> void:
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.sprite_frames.set_animation_loop(anim_name, false)
	animated_sprite.play(anim_name)
	await get_tree().process_frame
	var current_texture: Texture2D = animated_sprite.sprite_frames.get_frame_texture(anim_name, animated_sprite.frame)
	if current_texture:
		var current_size: Vector2 = current_texture.get_size()
		if current_size.x == 0 or current_size.y == 0: return
		var scale_factor: float = min(target_size.x / current_size.x, target_size.y / current_size.y)
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(animated_sprite, "scale", Vector2(scale_factor, scale_factor), 0.1)

func return_to_lane(delta: float, y_diff: float) -> void:
	position.y += sign(y_diff) * speed * delta
	if moving_right:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true

func move_side_to_side(delta: float) -> void:
	if moving_right:
		animated_sprite.flip_h = false
		position.x += speed * delta
		if position.x > start_position.x + move_distance:
			moving_right = false
	else:
		animated_sprite.flip_h = true
		position.x -= speed * delta
		if position.x < start_position.x - move_distance:
			moving_right = true

func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_node = body
		if body.has_method("activar_camara_fija"):
			body.activar_camara_fija()
		print("👀 Jugador detectado cerca del jefe")
		if not has_intro_played and not is_dead:
			start_dialogue("boss_start")
		elif not is_transforming and not is_dead:
			$ShootTimer.start()

func _on_Area2D_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_node = null
		print("🚶‍♂️ Jugador salió del rango — deteniendo disparos")
		$ShootTimer.stop()

func _on_shoot_timer_timeout() -> void:
	if not player_in_range or is_attacking or is_dead or is_dialogue_running or is_returning or is_transforming:
		$ShootTimer.start()
		return
	is_attacking = true
	var attack_choice: float = randf()
	if attack_choice < dash_chance:
		print("Jefe embistiendo...")
		await dash_attack()
	elif attack_choice < dash_chance + fan_shot_chance:
		print("💥 Disparando escopeta...")
		shoot_shotgun()
	else:
		print("💥 Disparando...")
		shoot_single()
	is_attacking = false
	$ShootTimer.wait_time = randf_range(random_fire_range.x, random_fire_range.y)
	$ShootTimer.start()

func shoot_single() -> void:
	if bullet_scene == null or not $SpawnPoint: return
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.position = $SpawnPoint.global_position
	bullet.set("owner_type", "boss")
	bullet.set("direction", (get_player_direction() if aim_at_player else shoot_direction).normalized())
	bullet.set("speed", bullet_speed)
	get_tree().current_scene.add_child(bullet)

func shoot_shotgun() -> void:
	if bullet_scene == null or not $SpawnPoint: return
	var dir_to_player: Vector2 = get_player_direction()
	var total_spread_rad: float = deg_to_rad(fan_shot_angle)
	var start_angle: float = dir_to_player.angle() - (total_spread_rad / 2)
	var angle_step: float = 0.0
	if fan_shot_count > 1:
		angle_step = total_spread_rad / (fan_shot_count - 1)
	for i in range(fan_shot_count):
		var angle: float = start_angle + (i * angle_step)
		var bullet_dir: Vector2 = Vector2.from_angle(angle)
		var bullet: Node2D = bullet_scene.instantiate()
		bullet.position = $SpawnPoint.global_position
		bullet.set("owner_type", "boss")
		bullet.set("direction", bullet_dir)
		bullet.set("speed", bullet_speed)
		get_tree().current_scene.add_child(bullet)

func dash_attack() -> void:
	is_dashing = true
	dash_target_direction = get_player_direction()
	await get_tree().create_timer(dash_duration).timeout
	stop_dash()

func stop_dash() -> void:
	is_dashing = false
	velocity = Vector2.ZERO

func get_player_direction() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player:
		return (player.global_position - global_position).normalized()
	return Vector2.LEFT

func take_damage(amount: int) -> void:
	if invulnerable or current_health <= 0 or is_dead or is_transforming:
		return
	current_health -= amount
	hits_taken += 1
	print("💥 Jefe recibió ", amount, " de daño. Vida restante:", current_health)
	invulnerable = true
	$InvulTimer.start()
	blink()
	if current_health <= 0:
		die()

func _on_invul_timeout() -> void:
	if not is_transforming:
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
	$ShootTimer.stop()
	print("💀 Jefe de Fase 2 derrotado")
	start_dialogue("boss_defeated_fase2")
	await DialogueManager.dialogue_ended
	var ruta_fase_3: String = "res://scenes/quests/story_quests/la_leyenda_de_quispe/3_fase/Main/Main_Fase_3.tscn"
	var error: Error = get_tree().change_scene_to_file(ruta_fase_3)
	if error != OK:
		print("❌ ERROR CRÍTICO: No se pudo cargar la escena de la Fase 3.")

func start_dialogue(node_name: String) -> void:
	if dialogue_resource == null:
		print("❌ ERROR: No asignaste el archivo .dialogue al Jefe en el Inspector")
		return
	is_dialogue_running = true
	animated_sprite.pause()
	$ShootTimer.stop()
	if player_node:
		player_node.set_physics_process(false)
	DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
	DialogueManager.show_dialogue_balloon(dialogue_resource, node_name)

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	is_dialogue_running = false
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)
	if player_node:
		player_node.set_physics_process(true)
	animated_sprite.play()
	if not has_intro_played:
		has_intro_played = true
		if player_in_range and not is_transforming:
			$ShootTimer.start()
	elif player_in_range and not is_dead:
		$ShootTimer.start()
