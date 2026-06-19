extends Node2D

@export var radio_base := 80.0
@export var velocidad := 2.0

var centro : Vector2
var angulo : float
var semilla : float
var hablando := false

var frases = [
	"✨ Agarra el hilo...",
	"✨ Ven a nuestro mundo...",
	"✨ Supera nuestra prueba...",
	"✨ Sigue nuestra luz...",
	"✨ El hilo te eligió...",
	"✨ Ya no puedes volver...",
	"✨ Quédate con nosotras...",
	"✨ No mires atrás...",
	"✨ El Lich era solo el comienzo...",
	"✨ Tu destino nos pertenece..."
]

func _ready():

	randomize()

	centro = global_position

	radio_base += randf_range(-30.0, 30.0)
	velocidad += randf_range(-0.8, 0.8)

	angulo = randf() * TAU
	semilla = randf() * 1000.0

	$AnimatedSprite2D.play("idle")

func _process(delta):

	angulo += velocidad * delta

	var tiempo = Time.get_ticks_msec() / 1000.0

	var radio = radio_base + sin(tiempo * 2.0 + semilla) * 20.0

	global_position = centro + Vector2(
		cos(angulo) * radio,
		sin(angulo) * radio
	)
func mostrar_frase():

	if hablando:
		return

	hablando = true

	await get_tree().create_timer(
		randf_range(0.0, 5.0)
	).timeout

	while true:

		$Label.text = frases.pick_random()
		$Label.visible = true

		await get_tree().create_timer(
			randf_range(2.0, 4.0)
		).timeout

		$Label.visible = false

		await get_tree().create_timer(
			randf_range(3.0, 8.0)
		).timeout
