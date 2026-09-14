# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const MAX_LINEAS: int = 3
const MAX_CARACTERES_POR_LINEA: int = 10

@export_multiline var zone_name: String:
	set(valor):
		var lineas: PackedStringArray = valor.split("\n")

		if lineas.size() > MAX_LINEAS:
			lineas = lineas.slice(0, MAX_LINEAS)

		for i in range(lineas.size()):
			if lineas[i].length() > MAX_CARACTERES_POR_LINEA:
				lineas[i] = lineas[i].substr(0, MAX_CARACTERES_POR_LINEA)

		_zone_name = "\n".join(lineas)
	get:
		return _zone_name

@export_range(1, 3) var time: int = 2

var _zone_name: String = ""
var normalized_zone_id: String = ""

func _ready() -> void:
	#Clean the name to use it as a unique ID (no line breaks, no spaces, and lowercase)
	normalized_zone_id = _zone_name.replace("\n", "").replace(" ", "").to_lower()


func _on_detect_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	# If we are already in this same zone according to global state, do nothing
	if GameState.global.current_area_name == normalized_zone_id:
		return
	
	# Update the current area in the game state
	GameState.global.current_area_name = normalized_zone_id
	
	# Check if the area has already been unlocked before
	if not GameState.global.is_area_unlocked(normalized_zone_id):
		# It's the first time: Unlock the area and show the "big" notification
		GameState.global.set_unlock_area(normalized_zone_id)
		GameState.save()
		
		var first_unlock: Control = preload("res://scenes/ui_elements/area_name/first_unlock.tscn").instantiate()
		$CanvasLayer.add_child(first_unlock)
		await first_unlock.animate_first_unlock(zone_name, time)
		first_unlock.queue_free()
	else:
		# Already known: Show the "small" re-entry notification through the HUD
		await %HUD.show_re_entry_zone(zone_name, time)
