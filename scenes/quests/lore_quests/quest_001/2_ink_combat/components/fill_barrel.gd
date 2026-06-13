# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@onready var magenta_barrel: FillingBarrel = $"../../FillingBarrel"
@onready var cyan_barrel: FillingBarrel = $"../../FillingBarrel2"
@onready var yellow_barrel: FillingBarrel = $"../../FillingBarrel3"

@onready var _barrels: Array[Object] = [cyan_barrel, yellow_barrel, magenta_barrel]


func _get_barrel_to_fill() -> FillingBarrel:
	for b: Object in _barrels:
		if not is_instance_valid(b):
			continue
		if (b as FillingBarrel)._amount >= (b as FillingBarrel).needed_amount:
			continue
		return b as FillingBarrel
	return null


func has_barrel_to_fill() -> bool:
	return _get_barrel_to_fill() != null


func fill_barrel() -> void:
	var barrel := _get_barrel_to_fill()
	if barrel == null:
		# No barrel to fill!
		return

	while barrel._amount < barrel.needed_amount:
		barrel.increment(1)
		await Engine.get_main_loop().create_timer(0.5).timeout
