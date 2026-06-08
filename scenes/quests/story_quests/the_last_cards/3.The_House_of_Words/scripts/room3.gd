extends Node2D

const PALABRAS = [
	"TUMBA", "CRUDA", "BRUJA", "HORROR", "PANICO",
	"TERROR", "SOMBRA", "CRIPTA", "CADAVER", "ESPECTRO",
	"TINIEBLA", "FANTASMA", "OSCURIDAD", "MALDICION"
]

const LETRAS = ["A","B","C","D","E","F","G","H","I","J","K","L","M",
				"N","Ñ","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

const AHORCADO = [
	"",
	"  |  \n  |  \n  |  \n  |  \n__|__",
	"  ____\n  |  \n  |  \n  |  \n__|__",
	"  ____\n  |  |\n  |  \n  |  \n__|__",
	"  ____\n  |  |\n  |  O\n  |  \n__|__",
	"  ____\n  |  |\n  |  O\n  | /|\n__|__",
	"  ____\n  |  |\n  |  O\n  | /|\\\n__|__",
	"  ____\n  |  |\n  |  O\n  | /|\\\n__|__ /",
    "  ____\n  |  |\n  |  O\n  | /|\\\n__|__ / \\"
]

var palabra_secreta = ""
var letras_adivinadas = []
var letras_falladas = []
var fallos = 0
var tiempo_restante = 60
var juego_activo = true

func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]
	$Timer.timeout.connect(_on_tiempo_agotado)
	
	var tick = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)
	
	_actualizar_display()
	_actualizar_timer_display()

func _on_letra_presionada(letra: String):
	if not juego_activo:
		return
	if letra in letras_adivinadas or letra in letras_falladas:
		return
	
	if palabra_secreta.contains(letra):
		letras_adivinadas.append(letra)
	else:
		letras_falladas.append(letra)
		fallos += 1
	_actualizar_display()
	_verificar_victoria()

func _actualizar_display():
	# Mostrar palabra con guiones
	var display = ""
	for letra in palabra_secreta:
		if letra in letras_adivinadas:
			display += letra + " "
		else:
			display += "_ "
	$CanvasGroup/Panel/LabelPalabra.text = display.strip_edges()
	
	# Mostrar letras falladas
	$CanvasGroup/Panel/LabelLetrasUsadas.text = "Errores: " + " ".join(letras_falladas)
	
	# Mostrar ahorcado
	if fallos < AHORCADO.size():
		$CanvasGroup/Panel/LabelAhorcado.text = AHORCADO[fallos]

func _verificar_victoria():
	# Verificar si ganó
	var gano = true
	for letra in palabra_secreta:
		if letra not in letras_adivinadas:
			gano = false
			break
	
	if gano:
		juego_activo = false
		$CanvasGroup/Panel/LabelMensaje.text = "¡Escapaste! Abriendo puerta final..."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/Victory.tscn")
	
	# Verificar si perdió por fallos
	if fallos >= 8:
		_game_over()

func _process(delta):
	if not juego_activo:
		return
	# Bestia persigue al jugador continuamente
	var dir = ($Player.position - $Bestia.position).normalized()
	$Bestia.position += dir * 45 * delta
	
	var dist = $Bestia.position.distance_to($Player.position)
	if dist < 60:
		_game_over()

func _physics_process(delta):
	if not juego_activo:
		return
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		velocity.x = 150
		$Player/Sprite2D.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -150
		$Player/Sprite2D.flip_h = true
	if Input.is_action_pressed("ui_up"):
		velocity.y = -150
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 150
	$Player.velocity = velocity
	$Player.move_and_slide()

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
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _input(event):
	if not juego_activo:
		return
	if event is InputEventKey and event.pressed:
		var letra = OS.get_keycode_string(event.keycode).to_upper()
		if letra.length() == 1 and letra >= "A" and letra <= "Z":
			_on_letra_presionada(letra)
