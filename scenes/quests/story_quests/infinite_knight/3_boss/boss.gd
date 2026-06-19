extends Area2D

const ProyectilBola = preload("res://scenes/quests/story_quests/infinite_knight/3_boss/boss_ball.tscn")

signal jefe_derrotado

var vida_maxima: int = 1
var vida_actual: int

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var alpha_anillo: float = 0.4:
	set(value):
		alpha_anillo = value
		queue_redraw() 

func _ready() -> void:
	vida_actual = vida_maxima
	sprite.play("idle")
	shoot_timer.stop()
	
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(self, "alpha_anillo", 0.1, 0.8)
	tween.tween_property(self, "alpha_anillo", 0.4, 0.8)

func iniciar_combate() -> void:
	shoot_timer.start()

func recibir_dano(cantidad: int) -> void:
	vida_actual -= cantidad
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)
	
	if vida_actual <= 0:
		defeat()

func defeat() -> void:
	shoot_timer.stop()
	jefe_derrotado.emit()
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

func _on_shoot_timer_timeout() -> void:
	sprite.play("throw")
	var nueva_bola: CharacterBody2D = ProyectilBola.instantiate()
	nueva_bola.global_position = global_position
	var angulo_aleatorio: float = randf_range(0, PI * 2)
	nueva_bola.direccion = Vector2.RIGHT.rotated(angulo_aleatorio)
	get_parent().add_child(nueva_bola)
	await sprite.animation_finished
	if vida_actual > 0:
		sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if "es_devuelta" in body and body.es_devuelta == true:
		recibir_dano(1)
		body.queue_free()
		return
		
	if body.name == "Player":
		_castigar_jugador(body)

func _castigar_jugador(jugador: Node2D) -> void:
	var golpes: int = 0
	if jugador.has_meta("golpes_jefe"):
		golpes = jugador.get_meta("golpes_jefe")
		
	golpes += 1
	jugador.set_meta("golpes_jefe", golpes)
	
	if golpes >= 3:
		if jugador.has_method("defeat"):
			jugador.defeat()
	else:
		jugador.modulate = Color(1, 0, 0)
		var tween_color: Tween = jugador.create_tween()
		tween_color.tween_property(jugador, "modulate", Color(1, 1, 1), 0.3)
		
		var direccion_empuje: Vector2 = (jugador.global_position - global_position).normalized()
		var tween_empuje: Tween = jugador.create_tween()
		tween_empuje.tween_property(jugador, "global_position", jugador.global_position + (direccion_empuje * 100.0), 0.2).set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	if not collision_shape or not collision_shape.shape:
		return
		
	var color_borde: Color = Color(1, 0, 0, alpha_anillo)
	var color_relleno: Color = Color(1, 0, 0, alpha_anillo * 0.2)
	var grosor: float = 3.0
	
	if collision_shape.shape is CapsuleShape2D:
		var r: float = collision_shape.shape.radius
		var h: float = collision_shape.shape.height
		var cy: float = (h / 2.0) - r
		
		draw_rect(Rect2(-r, -cy, r * 2, cy * 2), color_relleno)
		draw_circle(Vector2(0, -cy), r, color_relleno)
		draw_circle(Vector2(0, cy), r, color_relleno)
		
		draw_line(Vector2(-r, -cy), Vector2(-r, cy), color_borde, grosor)
		draw_line(Vector2(r, -cy), Vector2(r, cy), color_borde, grosor)
		
		draw_arc(Vector2(0, cy), r, 0, PI, 32, color_borde, grosor, true)
		draw_arc(Vector2(0, -cy), r, PI, TAU, 32, color_borde, grosor, true)
		
	elif collision_shape.shape is CircleShape2D:
		var r: float = collision_shape.shape.radius
		draw_circle(Vector2.ZERO, r, color_relleno)
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, color_borde, grosor, true)
