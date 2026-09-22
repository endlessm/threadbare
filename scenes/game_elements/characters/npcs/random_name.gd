# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

class_name RandomName
extends Node

## Available first names for Townies.
const FIRST_NAMES: Array[String] = [
	"Felicity", "Cedric", "Avery", "Rowan", "Morgan", "Jamie", "Taylor",
	"Riley", "Casey", "Jordan", "Quinn", "Harper", "Robin", "Ellis",
	"Darcy", "Finley", "Remy", "Jules", "Sage", "Blair", "Devon",
	"Skyler", "Emery", "Cameron", "Reese", "Marlowe", "Hollis", "Arden",
	"Kit", "Lennox", "Rory", "Parker", "Shiloh", "Drew", "Alex", "River"
]

## Available last names for Townies.
const LAST_NAMES: Array[String] = [
	"Fastneedle", "Chiffon", "Threadwell", "Woolstitch", "Patchwork",
	"Cottonweave", "Threadneedle", "Softspool", "Silkstitch", "Loomwright",
	"Velvet", "Hemline", "Ribbon", "Embroider", "Darning", "Flannel",
	"Ravel", "Jacquard", "Spindle", "Bobbin", "Damask", "Stitchwell",
	"Yarnspinner", "Clothbound", "Ripsaw", "Muslin", "Herringbone", "Artcloth",
	"Knitwell", "Linen", "Ruffle", "Pincushion", "Shuttle", "Drapewell",
	"Calico", "Appliqué", "Rosette", "Aran", "Ribstitch", "Mercer"
]

## The name assigned to this Townie.
var townie_name: String


func _ready() -> void:
	_assign_random_name()


## Assign one random name to this Townie.
## The name is stored so it does not change while this Townie exists.
func _assign_random_name() -> void:
	if FIRST_NAMES.is_empty() or LAST_NAMES.is_empty():
		push_warning("RandomName: No Townie names available.")
		return

	townie_name = FIRST_NAMES.pick_random() + " " + LAST_NAMES.pick_random()


## Returns the name assigned to this Townie.
func get_townie_name() -> String:
	return townie_name


## Returns a full name combined randomly using the provided RandomNumberGenerator.
## Useful for deterministic seed-based generation in @tool scripts.
static func get_random_name_from_rng(rng: RandomNumberGenerator) -> String:
	if FIRST_NAMES.is_empty() or LAST_NAMES.is_empty():
		return ""
	var first_idx := rng.randi_range(0, FIRST_NAMES.size() - 1)
	var last_idx := rng.randi_range(0, LAST_NAMES.size() - 1)
	return FIRST_NAMES[first_idx] + " " + LAST_NAMES[last_idx]
