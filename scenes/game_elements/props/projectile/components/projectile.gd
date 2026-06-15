# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Projectile
extends RigidBody2D

@export var label: String = "???"

@export var color: Color:
	set = _set_color

@export var can_hit_player: bool = true:
	set = _set_can_hit_player

@export var can_hit_enemy: bool = false:
	set = _set_can_hit_enemy

@export_group("Movement")

@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var speed: float = 30.0

@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var hit_speed: float = 100.0

@export var direction: Vector2 = Vector2(0, -1):
	set = _set_direction

@export_range(0., 10., 0.1, "or_greater", "suffix:s") var duration: float = 5.0

@export var node_to_follow: Node2D = null

@export_group("FXs")

@export var small_fx_scene: PackedScene

@export var big_fx_scene: PackedScene

@export var trail_fx_scene: PackedScene

var _trail_particles: GPUParticles2D

@onready var visible_things: Node2D = %VisibleThings
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var trail_fx_marker: Marker2D = %TrailFXMarker
@onready var duration_timer: Timer = %DurationTimer
@onready var hit_sound: AudioStreamPlayer2D = %HitSound


func _set_color(new_color: Color) -> void:
	color = new_color
	modulate = color if color else Color.WHITE


func _set_direction(new_direction: Vector2) -> void:
	if not new_direction.is_normalized():
		direction = new_direction.normalized()
	else:
		direction = new_direction


func _set_can_hit_player(new_can_hit_player: bool) -> void:
	can_hit_player = new_can_hit_player
	set_collision_mask_value(Enums.CollisionLayers.PLAYERS_HITBOX, can_hit_player)


func _set_can_hit_enemy(new_can_hit_enemy: bool) -> void:
	can_hit_enemy = new_can_hit_enemy
	set_collision_mask_value(Enums.CollisionLayers.ENEMIES_HITBOX, can_hit_enemy)


func _ready() -> void:
	# Forzamos las colisiones por si el editor falla
	contact_monitor = true
	max_contacts_reported = 5
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if trail_fx_scene:
		_trail_particles = trail_fx_scene.instantiate()
		trail_fx_marker.add_child(_trail_particles)

	_set_color(color)

	duration_timer.wait_time = duration
	duration_timer.start()
	var impulse: Vector2 = direction * speed
	apply_impulse(impulse)


func _process(_delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	
	# PERSECUCIÓN DEL TARGET (Cuando es repelido por el escudo)
	if node_to_follow and is_instance_valid(node_to_follow):
		var direction_to_target: Vector2 = global_position.direction_to(node_to_follow.global_position)
		constant_force = direction_to_target * speed
	else:
		constant_force = Vector2.ZERO


func add_small_fx() -> void:
	if not small_fx_scene:
		return
	var small_fx: Node2D = small_fx_scene.instantiate()
	if color:
		small_fx.modulate = color
	get_tree().current_scene.add_child(small_fx)
	small_fx.global_position = global_position


func _on_body_entered(body: Node2D) -> void:
	add_small_fx()
	duration_timer.start()

	# --- COLISIÓN FÍSICA NATIVA CONTRA FLORESTA ---
	if body.has_method("defeat"):
		body.defeat()
		explode()
		return
	elif body.owner and body.owner.has_method("defeat"):
		body.owner.defeat()
		explode()
		return
	# ----------------------------------------------

	if body.owner is FragileBarrel:
		body.owner.hit_by_droplet(label)
		queue_free()
		return

	if body.owner is FillingBarrel:
		var filling_barrel: FillingBarrel = body.owner as FillingBarrel
		if filling_barrel.label == label:
			filling_barrel.increment()
			queue_free()


# AQUÍ ESTÁ LA FUNCIÓN QUE PREGUNTABAS:
func got_repelled(repel_direction: Vector2) -> void:
	add_small_fx()
	duration_timer.start()

	# Redirección inteligente hacia los contenedores de reciclaje
	var barrels = get_tree().get_nodes_in_group("filling_barrels")
	for barrel in barrels:
		if not barrel.is_locked:
			node_to_follow = barrel
			speed = hit_speed
			break

	var hit_vector: Vector2 = repel_direction * hit_speed
	hit_sound.play()
	animated_sprite_2d.speed_scale = 2
	if _trail_particles:
		_trail_particles.amount_ratio = 1.
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)


func explode() -> void:
	if big_fx_scene:
		var big_fx: Node2D = big_fx_scene.instantiate()
		if color:
			big_fx.modulate = color
		get_tree().current_scene.add_child(big_fx)
		big_fx.global_position = global_position
	queue_free()


func _on_duration_timer_timeout() -> void:
	explode()


func remove() -> void:
	await get_tree().create_timer(randf_range(0., 3.)).timeout
	explode()


func _on_damage_area_area_entered(area: Area2D) -> void:
	# Como el área es parte de Floresta, buscamos al "dueño" del área
	if area.owner and area.owner.has_method("defeat"):
		print("¡Impacto físico nativo contra Floresta!")
		area.owner.defeat()
		explode()
