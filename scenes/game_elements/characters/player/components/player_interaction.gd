# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerInteraction
extends Node2D
var is_interacting: bool:
	get = _get_is_interacting
@onready var interact_zone: Area2D = %InteractZone
@onready var interact_marker: Marker2D = %InteractMarker
@onready var interact_label: FixedSizeLabel = %InteractLabel
@onready var player: Player = self.owner as Player
# Guardamos zoom original solo si se desea usar en el futuro
@onready var arma_node := get_parent().get_node_or_null("arma")
@onready var camara: Camera2D = get_parent().get_node_or_null("Camera2D")
func _ready():
	# Ocultar el arma
	if arma_node:
		arma_node.visible = false
	else:
		print("❌ No se encontró el nodo 'arma' dentro del jugador.")
	# Aplicar el zoom aumentado (alejar cámara) al inicio
	if camara:
		camara.zoom *= 2.1  # Aumentar para alejar (zoom out)
		print("🔍 Zoom reducido desde el inicio:", camara.zoom)
	else:
		print("❌ No se encontró la cámara en el jugador.")

func _get_is_interacting() -> bool:
	return not interact_zone.monitoring

func _process(_delta: float) -> void:
	if is_interacting:
		return

	var interact_area: InteractArea = interact_zone.get_interact_area()
	if not interact_area:
		interact_label.visible = false
	else:
		interact_label.visible = true
		interact_label.label_text = interact_area.action
		interact_marker.global_position = interact_area.get_global_interact_label_position()

func _unhandled_input(_event: InputEvent) -> void:
	if is_interacting:
		return

	var interact_area: InteractArea = interact_zone.get_interact_area()
	if interact_area and Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		interact_zone.monitoring = false
		interact_label.visible = false
		interact_area.interaction_ended.connect(_on_interaction_ended, CONNECT_ONE_SHOT)
		interact_area.start_interaction(player, interact_zone.is_looking_from_right)
		if arma_node:
			arma_node.visible = false

func _on_interaction_ended() -> void:
	interact_zone.monitoring = true
	if arma_node:
		arma_node.visible = true
