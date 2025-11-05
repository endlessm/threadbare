extends Node
class_name FireBossFightLogic

@export var fire_boss_path: NodePath
@export var player_path: NodePath

@onready var fire_boss: Node2D = get_node_or_null(fire_boss_path)
@onready var player: Player = get_node_or_null(player_path)

var fight_started := false

func _ready() -> void:
	await get_tree().process_frame  # Esperar a que Player y Boss terminen su _ready

	if not player:
		player = get_tree().get_first_node_in_group("player")

	if not player or not fire_boss:
		push_warning("⚠️ FireBossFightLogic: referencias no asignadas correctamente.")
		return

	# Activar modo combate
	_start_fight()

	# Conectar evento de muerte del boss
	if fire_boss.has_signal("tree_exited"):
		fire_boss.tree_exited.connect(_on_boss_defeated)
	elif fire_boss.has_signal("defeated"):
		fire_boss.defeated.connect(_on_boss_defeated)

func _start_fight() -> void:
	if fight_started:
		return
	fight_started = true

	player.mode = Player.Mode.FIGHTING
	print("🔥 FireBossFightLogic: Jugador ahora en modo FIGHTING")

func _on_boss_defeated() -> void:
	if not player:
		return
	player.mode = Player.Mode.COZY
	print("🏁 Boss derrotado, jugador vuelve a modo COZY")
