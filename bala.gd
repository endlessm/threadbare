extends Area2D

@export var velocidad = 500
@export var daño = 3  
var direccion = Vector2.ZERO

@onready var detector = $detector

func _ready():
	detector.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	if direccion != Vector2.ZERO:
		position += direccion * velocidad * delta

func _on_body_entered(body):
	if body.has_method("recibir_daño"):
		body.recibir_daño(daño)
		queue_free()
