# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var area_filler: AreaFiller = %AreaFiller


## Refill the FlowerBed on interaction with the FabricRock.
func _on_interact_area_interaction_started(area: InteractArea) -> void:
	area_filler.fill()
	area.end_interaction()


## Update minimum distance between scenes in AreaFiller.
func _on_interact_area_min_separation_interaction_started(
	area: InteractArea, min_separation_change: float
) -> void:
	area_filler.minimum_separation = clampf(
		area_filler.minimum_separation + min_separation_change, 32.0, 256.0
	)
	area.end_interaction()
