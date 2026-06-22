extends Node2D

var abierta = false
var moviendose = false
var player_en_rango = false

var puede_abrirse = false

@export var mensaje_bloqueo := "No se puede abrir todavía"

@onready var collision_shape  = $StaticBody2D/CollisionShape2D
@onready var area_interaccion = $AreaInteraccion
@onready var sprite           = $Sprite2D
@onready var tween            = $Tween
@onready var mensaje          = $Mensaje

var mensaje_timer = null

func _ready() -> void:
	if area_interaccion:
		area_interaccion.body_entered.connect(_on_body_entered)
		area_interaccion.body_exited.connect(_on_body_exited)

	if has_node("AnimationPlayer"):
		var anim = $AnimationPlayer
		if anim.has_animation("abrir"):
			print("Animación 'abrir' encontrada")
		else:
			print("Animación 'abrir' NO existe. Usando Tween en su lugar.")

	if mensaje:
		mensaje.text = ""

	mensaje_timer = Timer.new()
	mensaje_timer.wait_time = 2.0
	mensaje_timer.one_shot = true
	add_child(mensaje_timer)
	mensaje_timer.timeout.connect(_on_mensaje_timeout)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	player_en_rango = true
	mostrar_mensaje("Presiona ESPACIO para abrir/cerrar")

func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	player_en_rango = false
	if mensaje:
		mensaje.text = ""
	if mensaje_timer:
		mensaje_timer.stop()

func _input(event: InputEvent) -> void:
	if not player_en_rango:
		return
	if moviendose:
		return
	if event.is_action_pressed("ui_accept"):
		_alternar_puerta()

func _alternar_puerta() -> void:
	if not abierta and not puede_abrirse:
		mostrar_mensaje(mensaje_bloqueo)
		return

	moviendose = true

	if abierta:
		_cerrar_puerta()
	else:
		_abrir_puerta()

	abierta = !abierta
	moviendose = false

func _abrir_puerta() -> void:
	collision_shape.disabled = true

	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("abrir"):
		$AnimationPlayer.play("abrir")
		await $AnimationPlayer.animation_finished
	else:
		var pos_final = position + Vector2(0, -200)
		tween = create_tween()
		tween.tween_property(self, "position", pos_final, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

func _cerrar_puerta() -> void:
	collision_shape.disabled = false

	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("abrir"):
		$AnimationPlayer.play_backwards("abrir")
		await $AnimationPlayer.animation_finished
	else:
		var pos_bajada = position - Vector2(0, -200)
		tween = create_tween()
		tween.tween_property(self, "position", pos_bajada, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

func mostrar_mensaje(texto: String) -> void:
	if not mensaje:
		return
	mensaje.text = texto
	if mensaje_timer:
		mensaje_timer.stop()
		mensaje_timer.start()

func _on_mensaje_timeout() -> void:
	if mensaje:
		mensaje.text = ""
