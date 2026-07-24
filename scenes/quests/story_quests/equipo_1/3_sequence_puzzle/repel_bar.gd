extends ProgressBar
@onready var timer: Timer = $Timer
@export var jugador: CharacterBody2D
@export var animacion: AnimationPlayer
var puedo_atacar: bool = true

func _ready() -> void:
	visible = false
	value = 100
	timer.timeout.connect(_on_timer_timeout)


func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("repel") and puedo_atacar:
		puedo_atacar=false
		await animacion.animation_finished
		jugador.player_repel.player_controlled = false
		activar_cooldown()

	if not timer.is_stopped():
		var porcentaje: float = (timer.time_left / timer.wait_time) * 100
		value = porcentaje


func activar_cooldown() -> void:
	visible = true
	value = 100
	timer.start() 


func _on_timer_timeout() -> void:
	jugador.player_repel.player_controlled = true
	puedo_atacar = true 
	visible = false
