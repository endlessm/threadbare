extends CharacterBody2D

@export var speed: float = 60.0
@export var knockback_force: float = 300.0 
@export var hp: int = 2 

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_target: Node2D = null
var is_dead: bool = false
var is_knocked_back: bool = false 

var player_combat_target: Node2D = null
var ya_recibio_golpe: bool = false

func _ready() -> void:
	anim_sprite.play("Idle")

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if is_knocked_back:
		move_and_slide()
		chequear_ataque_jugador()
		return

	if player_target:
		var direction: Vector2 = (player_target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		anim_sprite.play("Float")
		
		if velocity.x != 0:
			anim_sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		anim_sprite.play("Idle")
		
	chequear_ataque_jugador()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_target = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_target:
		player_target = null


func _on_area_tocar_jugador_body_entered(body: Node2D) -> void:
	if is_dead: return
	
	if body.name == "Player":
		if body.has_method("defeat"):
			body.defeat() 
		take_damage()


func chequear_ataque_jugador() -> void:
	if is_dead or not is_instance_valid(player_combat_target) or not player_combat_target.is_node_ready(): 
		player_combat_target = null
		return
		
	var anim_actual: String = player_combat_target.player_sprite.animation
	
	var esta_atacando: bool = anim_actual == "attack_01" or anim_actual == "attack_02" or anim_actual == "throw_string"
	
	if esta_atacando:
		if not ya_recibio_golpe:
			ya_recibio_golpe = true
			aplicar_empuje(player_combat_target.global_position)
	else:
		ya_recibio_golpe = false

func _on_area_recibir_ataque_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_combat_target = body

func _on_area_recibir_ataque_body_exited(body: Node2D) -> void:
	if body == player_combat_target:
		player_combat_target = null
		ya_recibio_golpe = false

func aplicar_empuje(origen_ataque: Vector2) -> void:
	hp -= 1
	
	if hp <= 0:
		take_damage()
		return 
		
	is_knocked_back = true
	var direccion_empuje: Vector2 = (global_position - origen_ataque).normalized()
	velocity = direccion_empuje * knockback_force
	
	anim_sprite.modulate = Color(1, 0.3, 0.3)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "velocity", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(terminar_empuje)

func terminar_empuje() -> void:
	if is_dead: return
	is_knocked_back = false
	anim_sprite.modulate = Color(1, 1, 1)


func take_damage() -> void:
	if is_dead: return
	is_dead = true

	set_physics_process(false)
	velocity = Vector2.ZERO

	anim_sprite.stop()
	anim_sprite.animation = "Death"
	anim_sprite.frame = 0
	anim_sprite.modulate = Color(1, 1, 1, 1)

	$CollisionShape2D.set_deferred("disabled", true)
	$AreaTocarJugador/CollisionShape2D.set_deferred("disabled", true)
	$AreaRecibirAtaque/CollisionShape2D.set_deferred("disabled", true)

	anim_sprite.play("Death")

	var tween: Tween = create_tween()
	
	tween.tween_interval(0.7) 
	
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)
