extends Area2D

@export var velocidad := 500.0
@export var tiempo_carga := 1

var disparado := false
var lich: Node2D = null
var offset := Vector2(100, 0)

func _ready():

	body_entered.connect(_on_body_entered)

	$AnimatedSprite2D.play("idle")

	await get_tree().create_timer(tiempo_carga).timeout

	$AnimatedSprite2D.play("shoot")

	disparado = true

func _process(delta):

	if not disparado:

		if lich:
			global_position = lich.global_position + offset

		return

	global_position.x += velocidad * delta

func _on_body_entered(body):

	if body.name == "Player":
		body.defeat()
