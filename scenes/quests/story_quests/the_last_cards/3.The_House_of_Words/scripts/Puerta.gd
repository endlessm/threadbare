extends Node2D

var abierta = false
var moviendose = false
var player_en_rango = false

@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $StaticBody2D/CollisionShape2D
@onready var area_interaccion = $AreaInteraccion


func _ready() -> void:
	if area_interaccion:
		area_interaccion.body_entered.connect(_on_body_entered)
		area_interaccion.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_en_rango = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_en_rango = false


func _input(event: InputEvent) -> void:
	# Solo reacciona si el player está dentro del área de esta puerta.
	# Así, si hay otra puerta en la escena, no se activan ambas a la vez.
	if not player_en_rango:
		return
	if moviendose:
		return
	if event.is_action_pressed("ui_accept"):
		_alternar_puerta()


func _alternar_puerta() -> void:
	moviendose = true
	if abierta:
		animation_player.play_backwards("abrir")
		await get_tree().create_timer(1.0).timeout
		collision_shape.disabled = false
	else:
		animation_player.play("abrir")
		await get_tree().create_timer(1.0).timeout
		collision_shape.disabled = true
	abierta = !abierta
	moviendose = false
