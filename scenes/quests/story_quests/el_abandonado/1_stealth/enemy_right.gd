extends Node2D

@onready var camara = $"../Camera2D"
@onready var anim = $AnimatedSprite2D
@onready var orbe_timer = $OrbeTimer
@onready var musica_normal = $"../Fondo"
@onready var musica_persecucion = $"../Persecucion"

@export var offset_x := 300.0
@export var offset_y := 0.0
@export var orbe_scene: PackedScene = null
var frases = [
	"Nos dejaste atrás, Brennan...",
	"¿Por qué tú tuviste que vivir?",
	"Corres como el cobarde que siempre fuiste...",
	"¡Tus esfuerzos son inútiles!",
	"¡La oscuridad te alcanzará!",
	"¡La muerte te sigue!",
	"¡No hay salida!",
	"¡Tu viaje termina aquí!"
]
var indice_frase := 0
var hablando := false
var entrando := false
var persecucion_iniciada := false

func _ready():

	visible = false

	orbe_timer.timeout.connect(crear_orbe)

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

	global_position = Vector2(
		camara.global_position.x - (get_viewport_rect().size.x * 0.5) + offset_x,
		camara.global_position.y + offset_y
	)

func iniciar_persecucion():

	await get_tree().create_timer(1.0).timeout

	var jugador = $"../Player"

	jugador.mode = Player.Mode.USER_CONTROLLED

	camara.persecucion_activa = true
	persecucion_iniciada = true

	musica_persecucion.volume_db = -40
	musica_persecucion.play()
	var tween = create_tween()
	tween.parallel().tween_property(musica_normal,"volume_db",-40,1.5)
	tween.parallel().tween_property(musica_persecucion,"volume_db",-10,1.5)
	
	orbe_timer.start()
	iniciar_dialogos()

func crear_orbe() -> void:

	if not persecucion_iniciada:
		return

	if orbe_scene == null:
		return

	anim.play("idle")

	var orbe = orbe_scene.instantiate()

	get_parent().add_child(orbe)

	orbe.lich = self
	orbe.offset = Vector2(
		100,
		randf_range(-80.0, 80.0)
	)

	orbe.global_position = global_position + orbe.offset

	await get_tree().create_timer(0.2).timeout

	anim.play("idle")
	
func _on_area_2d_body_entered(body):

	if body.name == "Player":
		reiniciar_dialogos()
		body.defeat()

func desaparecer():

	var tween = create_tween()

	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		1.5
	)

	tween.parallel().tween_property(
		self,
		"global_position:x",
		global_position.x - 100,
		1.5
	)

	await tween.finished

	visible = false
func iniciar_dialogos():

	if hablando:
		return

	hablando = true

	while camara.persecucion_activa:

		$Label.text = frases[indice_frase % frases.size()]
		$Label.visible = true

		await get_tree().create_timer(3.0).timeout

		$Label.visible = false

		await get_tree().create_timer(1.0).timeout

		indice_frase += 1

		if indice_frase >= frases.size():
			indice_frase = 0

func reiniciar_dialogos():

	indice_frase = 0
	hablando = false
	$Label.visible = false

func terminar_persecucion():

	persecucion_iniciada = false
	orbe_timer.stop()
	reiniciar_dialogos()

	var tween = create_tween()
	tween.parallel().tween_property(musica_persecucion, "volume_db", -40, 1.5)
	tween.parallel().tween_property(musica_normal, "volume_db", 0, 1.5)
	await tween.finished
	
	musica_persecucion.stop()

	if musica_normal:
		musica_normal.play()

	desaparecer()
