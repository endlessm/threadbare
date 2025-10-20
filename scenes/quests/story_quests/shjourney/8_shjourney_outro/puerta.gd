# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Toggleable

@export var play_victory_fanfare_on_open: bool = false
@export var opened: bool = false:
	set(new_val):
		opened = new_val
		update_opened_state()
@onready var ring_sound: AudioStreamPlayer = $RingSound
@onready var door_sound: AudioStreamPlayer2D = $DoorSound
@onready var detector_jugador: Area2D = $DetectorJugador
var jugador_cerca := false


func _ready():
	detector_jugador.body_entered.connect(_on_body_entered)
	detector_jugador.body_exited.connect(_on_body_exited)


func _process(delta):
	if jugador_cerca and Input.is_action_just_pressed(&"interact"):
		if not opened:
			open()


func _on_body_entered(body):
	if body.name == "Player":
		jugador_cerca = true


func _on_body_exited(body):
	if body.name == "Player":
		jugador_cerca = false


func open() -> void:
	print("¡Golpe registrado!")
	if play_victory_fanfare_on_open:
		ring_sound.play()
	door_sound.play()
	set_toggled(true)

	# ✅ Esto debe ir dentro de la función, indentado correctamente
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.mode = Player.Mode.COZY


func close() -> void:
	set_toggled(false)


func set_toggled(value: bool) -> void:
	opened = value
	update_opened_state()


func update_opened_state() -> void:
	%DoorClosed.visible = !opened
	%DoorOpened.visible = opened
	%ColliderWhenClosed.set_collision_layer_value(Enums.CollisionLayers.WALLS, not opened)
	%ColliderWhenClosed.set_collision_mask_value(Enums.CollisionLayers.PLAYERS, not opened)
