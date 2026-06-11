extends CharacterBody2D

@export var velocidad: float = 220.0
@export var vida: int = 5
@export var iframes: float = 1.0

var vida_actual: int
var invencible: bool = false
var puede_moverse: bool = true

signal vida_cambio(vida_actual: int, vida_maxima: int)
signal murio

@onready var hitbox: Area2D = $Hitbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var barra: ProgressBar = $"../../CanvasLayer/Control/ProgressBarplayer"

func _ready() -> void:
	vida_actual = vida
	hitbox.area_entered.connect(_on_hitbox_area_entered)

	barra.max_value = vida
	barra.value = vida_actual

	vida_cambio.emit(vida_actual, vida)

func _physics_process(delta: float) -> void:
	if not puede_moverse:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direccion := Vector2.ZERO

	direccion.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direccion.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	direccion = direccion.normalized()
	velocity = direccion * velocidad

	move_and_slide()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if invencible:
		return

	if area.is_in_group("projectiles"):
		var dano_recibido: int = area.get_meta("dano", 1)
		recibir_dano(dano_recibido)

func recibir_dano(cantidad: int) -> void:
	if invencible:
		return

	vida_actual -= cantidad

	if vida_actual < 0:
		vida_actual = 0

	barra.value = vida_actual
	vida_cambio.emit(vida_actual, vida)

	if vida_actual <= 0:
		morir()
		return

	iniciar_invencibilidad()

func iniciar_invencibilidad() -> void:
	invencible = true

	sprite.modulate.a = 0.4

	await get_tree().create_timer(iframes).timeout

	sprite.modulate.a = 1.0
	invencible = false

func morir() -> void:
	puede_moverse = false
	murio.emit()
	queue_free()
