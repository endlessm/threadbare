extends Node2D

var abierta = false
var moviendose = false
var player_en_rango = false

# Controlado externamente (ej. desde Room1.gd / Room2.gd) cuando se cumpla la condición de la sala
var puede_abrirse = false

# Texto que se muestra al intentar abrir mientras puede_abrirse == false.
# Cada escena puede asignar el mensaje que corresponda
@export var mensaje_bloqueo := "No se puede abrir todavía"

@onready var collision_shape = $StaticBody2D/CollisionShape2D
@onready var area_interaccion = $AreaInteraccion
@onready var sprite = $Sprite2D  
@onready var tween = $Tween  
@onready var mensaje = $Mensaje  

var mensaje_timer = null

func _ready() -> void:
	if area_interaccion:
		area_interaccion.body_entered.connect(_on_body_entered)
		area_interaccion.body_exited.connect(_on_body_exited)

	# Verificar si la animación existe (solo para debug)
	if has_node("AnimationPlayer"):
		var anim = $AnimationPlayer
		if anim.has_animation("abrir"):
			print("Animación 'abrir' encontrada")
		else:
			print("Animación 'abrir' NO existe. Usando Tween en su lugar.")

	if mensaje:
		mensaje.text = ""

	# Timer interno para ocultar el mensaje automáticamente tras 2 segundos
	mensaje_timer = Timer.new()
	mensaje_timer.wait_time = 2.0
	mensaje_timer.one_shot = true
	add_child(mensaje_timer)
	mensaje_timer.timeout.connect(_on_mensaje_timeout)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_en_rango = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_en_rango = false

func _input(event: InputEvent) -> void:
	if not player_en_rango:
		return
	if moviendose:
		return
	if event.is_action_pressed("ui_accept"):
		_alternar_puerta()

func _alternar_puerta() -> void:
	# Si está cerrada y todavía no se puede abrir, bloquear y avisar
	if not abierta and not puede_abrirse:
		mostrar_mensaje(mensaje_bloqueo)
		return

	moviendose = true

	if abierta:
		# Cerrar: bajar la puerta
		_cerrar_puerta()
	else:
		# Abrir: subir la puerta
		_abrir_puerta()

	abierta = !abierta
	moviendose = false

func _abrir_puerta() -> void:
	# Desactivar colisión
	collision_shape.disabled = true

	# Opción 1: Usar AnimationPlayer si existe
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("abrir"):
		$AnimationPlayer.play("abrir")
		# Esperar a que termine (opcional)
		await $AnimationPlayer.animation_finished
	else:
		# Opción 2: Usar Tween para mover hacia arriba
		var pos_final = position + Vector2(0, -200)  # sube 200 px
		tween = create_tween()  
		tween.tween_property(self, "position", pos_final, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

	mostrar_mensaje("Puerta abierta")

func _cerrar_puerta() -> void:
	# Habilitar colisión
	collision_shape.disabled = false

	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation("abrir"):
		$AnimationPlayer.play_backwards("abrir")
		await $AnimationPlayer.animation_finished
	else:
		# Bajar la puerta a la posición original
		var pos_inicial = position  # guarda la posición inicial en una variable al inicio

		var pos_bajada = position - Vector2(0, -200)  
		tween = create_tween()
		tween.tween_property(self, "position", pos_bajada, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

	mostrar_mensaje("Puerta cerrada")

## Único punto de acceso para escribir en el Label "Mensaje".
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
