extends StaticBody2D
class_name Puerta
@export var next_scene_path: String = "res://Mundo/main_2.tscn"

@onready var interaction_area: Area2D = $InteractionArea
@onready var interact_label: Label = $ui_container/InteractLabel
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ui_container: Control = $ui_container

var player_in_range: bool = false
var is_unlocked: bool = false
var current_player: Player_l = null

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	ui_container.visible = false
	animated_sprite_2d.play("Cerrado")

func _on_body_entered(body):
	if body is Player_l:
		player_in_range = true
		current_player = body
		body.set_current_door(self)
		check_door_status()

func _on_body_exited(body):
	if body is Player_l:
		player_exit()

func player_exit():
	player_in_range = false
	if current_player:
		current_player.clear_current_door()
		current_player = null
	hide_ui()

func check_door_status():
	if not current_player:
		return
	var player_keys = current_player.keys_collected
	if player_keys >= 12 and not is_unlocked:
		unlock_door()
	elif player_keys <12:
		show_locked_ui(player_keys)
	elif is_unlocked:
		show_unlocked_ui()

func unlock_door():
	is_unlocked = true
	animated_sprite_2d.play("Abierto")
	show_unlocked_ui()
	print("¡Puerta desbloqueada!")

func show_locked_ui(current_keys: int):
	ui_container.visible = true
	interact_label.text = "Consigue " + str(12 - current_keys) + " llaves más"

func show_unlocked_ui():
	ui_container.visible = true
	interact_label.text = "Presiona E para continuar"

func hide_ui():
	ui_container.visible = false

func interact():
	if is_unlocked and player_in_range:
		change_scene()
func change_scene():
	print("Intentando cargar: ", next_scene_path)
	var result = get_tree().change_scene_to_file(next_scene_path)
	if result != OK:
		print("❌ Error al cargar la escena: ", result)
	else:
		print("✅ Escena cargada correctamente")
