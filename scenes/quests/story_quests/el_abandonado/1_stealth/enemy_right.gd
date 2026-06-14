extends Node2D

@onready var camara = $"../Camera2D"
@onready var anim = $AnimatedSprite2D

@export var offset_x := 300.0
@export var offset_y := 0.0

var entrando := false

func _ready():
	visible = false


func iniciar_entrada():

	if entrando:
		return
	modulate.a = 1.0
	visible = true
	entrando = true

	var ancho = get_viewport_rect().size.x

	global_position.x = camara.global_position.x - ancho
	global_position.y = camara.global_position.y + offset_y

	anim.play("idle")


func _process(delta):

	if entrando:

		var ancho = get_viewport_rect().size.x

		var destino = camara.global_position.x - (ancho * 0.5) + offset_x

		global_position.x = move_toward(
			global_position.x,
			destino,
			130 * delta
		)

		global_position.y = camara.global_position.y + offset_y

		if abs(global_position.x - destino) < 5:

			entrando = false

			iniciar_persecucion()

		return


	if not camara.persecucion_activa:
		return


	var ancho = get_viewport_rect().size.x

	global_position = Vector2(
		camara.global_position.x - (ancho * 0.5) + offset_x,
		camara.global_position.y + offset_y
	)


func iniciar_persecucion():

	await get_tree().create_timer(1.0).timeout

	var jugador = $"../Player"

	jugador.mode = Player.Mode.USER_CONTROLLED

	camara.persecucion_activa = true


func _on_area_2d_body_entered(body):

	if body.name == "Player":
		body.defeat()
		
func desaparecer():

	var tween = create_tween()

	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.5)

	tween.parallel().tween_property(
		self,
		"global_position:x",
		global_position.x - 100,
		1.5
	)

	await tween.finished

	visible = false
