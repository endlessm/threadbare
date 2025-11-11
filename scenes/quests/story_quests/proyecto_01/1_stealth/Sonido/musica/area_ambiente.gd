extends Node2D

@onready var area: Area2D = $Area2D
@onready var audio: AudioStreamPlayer2D = $Area2D/Audio

var player_inside := false

func _ready() -> void:
	# Aseguramos que esté activo
	area.monitoring = true
	area.monitorable = true

	# Forzamos Layer / Mask correctos (capa 1)
	for i in range(20):
		area.set_collision_layer_value(i + 1, false)
		area.set_collision_mask_value(i + 1, false)
	area.set_collision_layer_value(1, true)
	area.set_collision_mask_value(1, true)

	audio.stop()

	# Conectamos señales por código (evita errores si no están enlazadas)
	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)
	if not area.body_exited.is_connected(_on_area_body_exited):
		area.body_exited.connect(_on_area_body_exited)

	print("✅ AreaAmbiente lista. Esperando detección...")

func _on_area_body_entered(body: Node) -> void:
	if _is_player(body):
		player_inside = true
		print("🎧 Jugador detectado — iniciando ambiente.")
		audio.play()

func _on_area_body_exited(body: Node) -> void:
	if _is_player(body):
		player_inside = false
		print("🔇 Jugador salió del área — deteniendo ambiente.")
		audio.stop()

func _is_player(body: Node) -> bool:
	# Opción segura: el jugador está en grupo "player"
	return body.is_in_group("player")

# Seguridad extra (si la señal fallara)
func _physics_process(_delta: float) -> void:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			if not audio.playing:
				print("🎵 Reproducción forzada (respaldo)")
				audio.play()
			return

	if audio.playing and not player_inside:
		print("⏹️ Parada forzada (respaldo)")
		audio.stop()
