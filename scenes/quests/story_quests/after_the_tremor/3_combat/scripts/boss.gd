# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ThrowingEnemy

@onready var barrel: FillingBarrel = $FillingBarrel
@onready var timer_attack: Timer = $TimerAttack
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var marker: Marker2D = $ProjectileMarker

var phase: int = 1   # 1 = fácil, 2 = normal, 3 = difícil

func _ready() -> void:
	# conectar señales de forma segura
	if barrel and not barrel.is_connected("completed", Callable(self, "_on_boss_defeated")):
		barrel.connect("completed", Callable(self, "_on_boss_defeated"))
	if timer_attack and not timer_attack.is_connected("timeout", Callable(self, "_on_attack_timeout")):
		timer_attack.connect("timeout", Callable(self, "_on_attack_timeout"))

	# Si la clase base depende de animation_player, intentamos asignárselo también
	# (no confiamos en el orden de ready del padre)
	if anim:
		# usar set() para asignar la propiedad en la clase base
		set("animation_player", anim)
		set("animated_sprite_2d", get_node_or_null("AnimatedSprite2D"))

	update_phase()
	if timer_attack:
		timer_attack.start()


# --- sobreescribimos _process para evitar llamadas nulas al animation_player del padre ---
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var state = _get_state()
	match state:
		State.ATTACKING, State.DEFEATED:
			return
		State.IDLE:
			# usamos anim local si existe, si no, intentamos animation_player (defensa)
			if anim:
				if animated_sprite_2d and animated_sprite_2d.animation not in [&"attack anticipation", &"attack"]:
					anim.play("idle")
			elif animation_player:
				if animated_sprite_2d and animated_sprite_2d.animation not in [&"attack anticipation", &"attack"]:
					animation_player.play("idle")
			return
		State.WALKING:
			velocity = _get_velocity()
			move_and_slide()
			if get_tree().is_debugging_collisions_hint():
				queue_redraw()
			if not velocity.is_zero_approx():
				if animated_sprite_2d:
					animated_sprite_2d.play(&"walk")


# LIFE → PHASES
func _get_barrel_amount() -> int:
	if not barrel:
		return 0
	var raw_value: Variant = barrel.get("_amount")
	if raw_value is int:
		return int(raw_value)
	return 0

func get_life_rate() -> float:
	if not barrel:
		return 0.0
	var raw_needed: Variant = barrel.get("needed_amount")
	var needed: int = 1
	if raw_needed is int:
		needed = int(raw_needed)
	if needed <= 0:
		needed = 1
	var amount: int = _get_barrel_amount()
	return float(amount) / float(needed)


func update_phase() -> void:
	var r: float = get_life_rate()
	var new_phase: int = 1
	if r < 0.33:
		new_phase = 1
	elif r < 0.66:
		new_phase = 2
	else:
		new_phase = 3
	if new_phase != phase:
		phase = new_phase
		apply_phase_settings()


func apply_phase_settings() -> void:
	match phase:
		1:
			if timer_attack: timer_attack.wait_time = 2.2
		2:
			if timer_attack: timer_attack.wait_time = 1.4
		3:
			if timer_attack: timer_attack.wait_time = 0.8
	if timer_attack:
		timer_attack.start()


# ATTACKS
func _on_attack_timeout() -> void:
	update_phase()
	var choice: int = randi() % 3
	match choice:
		0: attack_bryan()
		1: attack_charlie()
		2: attack_both()

func attack_bryan() -> void:
	if anim: anim.play("attack_bryan")
	spawn_projectile("bryan")

func attack_charlie() -> void:
	if anim: anim.play("attack_charlie")
	spawn_projectile("charlie")

func attack_both() -> void:
	if anim: anim.play("attack_both")
	spawn_projectile("bryan")
	spawn_projectile("charlie")

func spawn_projectile(target_group: String) -> void:
	var p = projectile_scene.instantiate()
	if not p:
		return

	# posición inicial
	if marker and is_instance_valid(marker):
		p.global_position = marker.global_position
	else:
		p.global_position = global_position

	# objetivo y dirección
	var target := get_tree().get_first_node_in_group(target_group)
	if target and is_instance_valid(target):
		var dir_vec: Vector2 = (target.global_position - p.global_position).normalized()

		# Si es concretamente Projectile, usar su API
		if p is Projectile:
			p.direction = dir_vec
		# Si tiene un setter expuesto por método
		elif p.has_method("set_direction"):
			p.call("set_direction", dir_vec)
		# Fallback: si es un RigidBody, aplicamos impulso inicial
		elif p is RigidBody2D and p.has_method("apply_impulse"):
			p.apply_impulse(dir_vec * projectile_speed)

	# fallback / asegurar speed (solo para Projectile)
	if p is Projectile:
		# si el wrapper ajusta speed en _ready(), no forzar salvo que sea 0
		if p.speed == 0.0:
			p.speed = projectile_speed

		# Propiedades visuales / FX (seguras porque es Projectile)
		p.sprite_frames = projectile_sprite_frames
		p.hit_sound_stream = projectile_hit_sound_stream
		p.trail_fx_scene = projectile_trail_fx_scene
		p.small_fx_scene = projectile_small_fx_scene
		p.big_fx_scene = projectile_big_fx_scene
	else:
		# Si el objeto define setters por método, puedes llamarles aquí
		# ejemplo (opcional):
		# if p.has_method("set_speed"):
		#     p.call("set_speed", projectile_speed)
		pass

	# Añadir al contenedor correcto
	var container: Node = null
	if get_parent() and get_parent().has_node("ProjectilesContainer"):
		container = get_parent().get_node("ProjectilesContainer")
	elif get_tree().current_scene and get_tree().current_scene.has_node("ProjectilesContainer"):
		container = get_tree().current_scene.get_node("ProjectilesContainer")
	else:
		container = get_tree().current_scene

	if container:
		container.add_child(p)
