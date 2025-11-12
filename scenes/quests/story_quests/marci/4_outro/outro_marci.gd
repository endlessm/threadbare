extends Node2D

# --- Nodos principales ---
@onready var camera: Camera2D = $Camera2D
@onready var label_dialogue: Label = $CanvasLayer/LabelDialogue
@onready var marci: Node2D = $OnTheGround/Marci
@onready var mia: Node2D = $OnTheGround/Mia
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

# --- Variables ---
var step: int = 0
var can_advance: bool = true

var dialogues := [
	"Marci: Ahí está… luego de tanto tiempo.",
	"Marci: Al fin podré volver a verla.",
	"*Marci se acerca a la cabaña.*",
	"Marci: ¡Miaaaa!",
	"Mia: ¿Mamá…?",
	"Marci: ¡Miaaaa!",
	"Marci: Ya no te volveré a dejar sola. Te extrañé tanto.",
	"Mia: *Sollozo* Sí…",
	"FIN"
]

func _ready() -> void:
	# Estado inicial
	label_dialogue.text = ""
	label_dialogue.modulate = Color(1, 1, 1, 0) # iniciar invisible para el fade
	mia.visible = false
	marci.position = Vector2(0, 200)
	camera.position = marci.position

	# --- Estilo del texto ---
	# Centrado horizontal y anclado arriba, ocupando todo el ancho de la pantalla
	label_dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_dialogue.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label_dialogue.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label_dialogue.position.y = 50  # despegar del borde superior

	# Tamaño de fuente (Godot 4): override directo del "font_size"
	label_dialogue.add_theme_font_size_override("font_size", 40)

	# Sombra para legibilidad
	label_dialogue.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label_dialogue.add_theme_constant_override("font_shadow_size", 4)

	_show_next_dialogue()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_show_next_dialogue()

func _show_next_dialogue() -> void:
	if not can_advance:
		return

	if step >= dialogues.size():
		_end_scene()
		return

	can_advance = false
	var current := step

	var tween := create_tween()

	# Fade out del texto anterior
	tween.tween_property(label_dialogue, "modulate:a", 0.0, 0.4)

	# Cambiar texto y procesar movimientos de escena
	tween.tween_callback(func ():
		label_dialogue.text = dialogues[current]
		_process_scene_movement(current)
		step += 1
	)

	# Fade in del nuevo texto
	tween.tween_property(label_dialogue, "modulate:a", 1.0, 0.4)

	# Habilitar avance al terminar
	tween.tween_callback(func ():
		can_advance = true
	)

func _process_scene_movement(current_step: int) -> void:
	match current_step:
		0:
			# Marci corriendo en el bosque
			_move_marci(Vector2(300, 200), 2.0)
		1:
			# Pausa frente a la cabaña
			pass
		2:
			# Marci entra a la cabaña (fade o movimiento)
			_move_marci(Vector2(400, 200), 1.5)
		3:
			# Marci grita “Mia”
			mia.visible = true
			mia.position = Vector2(500, 200)
		8:
			# Cámara sube al cielo (final)
			_move_camera(Vector2(camera.position.x, camera.position.y - 200), 2.5)

func _move_marci(target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(marci, "position", target, duration)

func _move_camera(target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(camera, "position", target, duration)

func _end_scene() -> void:
	label_dialogue.text = "FIN"
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()  # o cambia a tu escena de créditos
