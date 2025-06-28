extends CharacterBody2D

@export var velocidad = 350
@export var daño = 2
var direccion = Vector2.ZERO

@onready var detector = $detector_de_daño
@onready var colision = $CollisionShape2D
@onready var detector_col = $detector_de_daño/CollisionShape2D

func _ready():

	colision.disabled = true
	detector_col.disabled = true


	if detector:
		detector.connect("body_entered", Callable(self, "_on_body_entered"))


	await get_tree().create_timer(0.1).timeout
	colision.disabled = false
	detector_col.disabled = false

func _physics_process(delta):
	if direccion != Vector2.ZERO:
		velocity = direccion * velocidad
		move_and_slide()

	if is_on_wall():
		queue_free()

func _on_body_entered(body):
	print("Bala tocó a: ", body.name)
	print("¿Tiene recibir_daño?: ", body.has_method("recibir_daño"))
	if body.has_method("recibir_daño"):
		body.recibir_daño(daño)
		queue_free()
