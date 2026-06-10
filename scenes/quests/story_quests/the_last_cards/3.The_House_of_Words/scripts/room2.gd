extends Node2D

const PALABRAS = [
	"BOSQUE"
]

const SPEED_NUBE = 55

var palabra_secreta = ""
var intento_actual = 0
var tiempo_restante = 120
var juego_activo = true
var escribiendo = false

func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]
	$CanvasGroup/InputLetra.text_submitted.connect(_on_palabra_enviada)
	$CanvasGroup/InputLetra.focus_entered.connect(_on_input_focus)
	$CanvasGroup/InputLetra.focus_exited.connect(_on_input_unfocus)
	$Timer.timeout.connect(_on_tiempo_agotado)
	
	var tick = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)
	
	# Configurar los 36 Labels del grid
	for i in range(36):
		var label = $CanvasGroup/Panel/GridLetras.get_child(i)
		label.custom_minimum_size = Vector2(65, 65)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.25)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.4, 0.6)
		label.add_theme_stylebox_override("normal", sb)
	
	_actualizar_timer_display()

func _process(delta):
	if not juego_activo:
		return
	var dir = ($Player.position - $NubeNegra.position).normalized()
	$NubeNegra.position += dir * SPEED_NUBE * delta
	var dist = $NubeNegra.position.distance_to($Player.position)
	if dist < 80:
		_game_over()

func _physics_process(delta):
	if not juego_activo or escribiendo:
		return
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		velocity.x = 150
		$Player/AnimatedSprite2D.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -150
		$Player/AnimatedSprite2D.flip_h = true
	if Input.is_action_pressed("ui_up"):
		velocity.y = -150
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 150
	$Player.velocity = velocity
	$Player.move_and_slide()

func _on_palabra_enviada(texto):
	if not juego_activo:
		return
	var intento = texto.to_upper().strip_edges()
	if intento.length() != 6:
		$CanvasGroup/Panel/LabelMensaje.text = "Escribe exactamente 6 letras"
		return
	_evaluar_intento(intento)
	$CanvasGroup/InputLetra.text = ""

func _evaluar_intento(intento):
	for i in range(6):
		var label = $CanvasGroup/Panel/GridLetras.get_child(intento_actual * 6 + i)
		label.text = intento[i]
		if intento[i] == palabra_secreta[i]:
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.5, 0.2)))
			label.add_theme_color_override("font_color", Color.GREEN)
		elif palabra_secreta.contains(intento[i]):
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.5, 0.4, 0.1)))
			label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.2, 0.2)))
			label.add_theme_color_override("font_color", Color.WHITE)

	if intento == palabra_secreta:
		juego_activo = false
		$CanvasGroup/Panel/LabelMensaje.text = "¡Correcto! Siguiente habitación..."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")
	else:
		intento_actual += 1
		if intento_actual >= 6:
			_game_over()
		else:
			$CanvasGroup/Panel/LabelMensaje.text = "Intento %d/6" % intento_actual

func _crear_fondo(color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	return sb

func _on_tiempo_agotado():
	_game_over()

func _on_timer_tick():
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()

func _actualizar_timer_display():
	var minutos = int(tiempo_restante) / 60
	var segundos = int(tiempo_restante) % 60
	$CanvasGroup/LabelTiempo.text = "%02d:%02d" % [minutos, segundos]

func _game_over():
	juego_activo = false
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/GameOver.tscn")

func _on_input_focus():
	escribiendo = true

func _on_input_unfocus():
	escribiendo = false
