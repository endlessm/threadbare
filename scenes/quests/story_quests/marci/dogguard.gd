# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name DogGuard
extends Guard

## Perro guardián que patrulla con sprites personalizados y ladra al detectar al jugador.

# Ruta definitiva donde están los sprites del perro
const SHEPHERD_FRAMES_PATH := "res://scenes/quests/story_quests/marci/Perro/x2/"

# Sonido opcional de ladrido
@export var bark_sound: AudioStream
@onready var _bark_sound_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

func _ready() -> void:
	super() # ejecuta el _ready del Guard original

	print("📂 Buscando sprites en:", SHEPHERD_FRAMES_PATH)

	var test_path = SHEPHERD_FRAMES_PATH + "Shepherd_default.png"
	if ResourceLoader.exists(test_path):
		print("✅ Sprite encontrado:", test_path)
	else:
		print("❌ No se encontró:", test_path)

	_setup_shepherd_sprite()
	_setup_bark_sound()


func _setup_shepherd_sprite() -> void:
	var frames := SpriteFrames.new()

	# --- Animación caminar ---
	frames.add_animation("walk")
	for i in range(1, 7):
		var path = SHEPHERD_FRAMES_PATH + "Shepherd_walk_%d.png" % i
		if ResourceLoader.exists(path):
			frames.add_frame("walk", load(path))

	# --- Animación idle ---
	frames.add_animation("idle")
	var idle_path = SHEPHERD_FRAMES_PATH + "Shepherd_default.png"
	if ResourceLoader.exists(idle_path):
		frames.add_frame("idle", load(idle_path))

	# --- Animación correr ---
	frames.add_animation("run")
	for i in range(1, 6):
		var path = SHEPHERD_FRAMES_PATH + "Shepherd_run_%d.png" % i
		if ResourceLoader.exists(path):
			frames.add_frame("run", load(path))

	# --- Animación ladrar ---
	frames.add_animation("bark")
	for i in range(1, 4):
		var path = SHEPHERD_FRAMES_PATH + "Shepherd_bark_%d.png" % i
		if ResourceLoader.exists(path):
			frames.add_frame("bark", load(path))

	# Asignar al AnimatedSprite2D
	if animated_sprite_2d:
		animated_sprite_2d.sprite_frames = frames
		animated_sprite_2d.play("idle")


func _setup_bark_sound() -> void:
	if bark_sound:
		add_child(_bark_sound_player)
		_bark_sound_player.stream = bark_sound


# --- Sobrescribir el cambio de estado para animar y ladrar ---
func _set_state(new_state: State) -> void:
	state = new_state

	match new_state:
		State.ALERTED:
			print("🐕 ¡Jugador detectado!")

			# Reproducir sonido de ladrido si está configurado
			if bark_sound and not _bark_sound_player.playing:
				_bark_sound_player.play()

			# Girar hacia el jugador (opcional)
			if _player and _player.global_position.x < global_position.x:
				animated_sprite_2d.flip_h = true
			elif _player and _player.global_position.x > global_position.x:
				animated_sprite_2d.flip_h = false

			# Cambiar animación a 'alerted' o usar 'idle' si no existe
			if animated_sprite_2d:
				if animated_sprite_2d.sprite_frames.has_animation("alerted"):
					animated_sprite_2d.play("alerted")
				else:
					animated_sprite_2d.play("idle")

			# Pequeña pausa antes de emitir la señal
			await get_tree().create_timer(0.5).timeout

			# Emitir señal solo si _player sigue siendo válido
			if _player != null:
				player_detected.emit(_player)
			else:
				print("⚠️ _player es null, no se emite la señal.")



# Permite usar el botón “Add/Edit Patrol Path” en el editor como el guardia original
func edit_patrol_path() -> void:
	if not Engine.is_editor_hint():
		return

	var editor_interface := Engine.get_singleton("EditorInterface")

	if patrol_path:
		editor_interface.edit_node.call_deferred(patrol_path)
	else:
		var new_patrol_path: Path2D = Path2D.new()
		patrol_path = new_patrol_path
		get_parent().add_child(patrol_path)
		patrol_path.owner = owner
		patrol_path.global_position = global_position
		var patrol_path_curve: Curve2D = Curve2D.new()
		patrol_path.curve = patrol_path_curve
		patrol_path.name = "%s-PatrolPath" % name
		patrol_path_curve.add_point(Vector2.ZERO)
		patrol_path_curve.add_point(Vector2.RIGHT * 150.0)
		editor_interface.edit_node.call_deferred(patrol_path)
		
