# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Node

## Names available for Townies.
## Names are not separated by gender.
const TOWNIE_NAMES: Array[String] = [
	"Felicity Fastneedle",
	"Cedric Chiffon",
	"Avery Threadwell",
	"Rowan Woolstitch",
	"Morgan Patchwork",
	"Jamie Cottonweave",
	"Taylor Threadneedle",
	"Riley Softspool",
	"Casey Silkstitch",
	"Jordan Loomwright",
	"Quinn Velvet",
	"Harper Hemline",
	"Robin Ribbon",
	"Ellis Embroider",
	"Darcy Darning",
	"Finley Flannel",
	"Remy Ravel",
	"Jules Jacquard",
	"Sage Spindle",
	"Blair Bobbin",
	"Devon Damask",
	"Skyler Stitchwell",
	"Emery Yarnspinner",
	"Cameron Clothbound",
	"Reese Ripsaw",
	"Marlowe Muslin",
	"Hollis Herringbone",
	"Arden Artcloth",
	"Kit Knitwell",
	"Lennox Linen",
	"Rory Ruffle",
	"Parker Pincushion",
	"Shiloh Shuttle",
	"Drew Drapewell",
	"Casey Calico",
	"Alex Appliqué",
	"River Rosette",
	"Ashen Aran",
	"Rowan Ribstitch",
	"Morgan Mercer",
	"Avery Alpaca",
	"Taylor Tapestry",
	"Riley Rayon",
	"Jordan Jersey",
	"Quinn Quilter",
	"Harper Haberdash",
	"Ellis Eyelet",
	"Finley Felt",
	"Remy Raglan",
	"Jules Jute",
	"Sage Selvage",
	"Blair Brocade",
	"Devon Dobby",
	"Emery Elastic",
	"Cameron Cashmere",
	"Reese Reticule",
	"Marlowe Mohair",
	"Hollis Homespun",
	"Arden Angora",
	"Kit Kersey",
	"Lennox Lattice",
	"Rory Rosette",
	"Parker Poplin",
	"Shiloh Shirring",
	"Drew Duckcloth",
	"Alex Ajour",
	"River Roving",
	"Jamie Jacquard",
	"Darcy Damask",
	"Robin Ribbing",
	"Skyler Spunthread",
	"Marlowe Macramé",
	"Hollis Handloom",
	"Avery Weft",
	"Morgan Warp",
	"Quinn Warpwood",
	"Riley Bobbin",
	"Taylor Thimble",
	"Casey Spool",
	"Jordan Needlework",
	"Harper Stitcher",
	"Ellis Loom",
	"Finley Shuttle",
	"Remy Threader",
	"Jules Weaverton",
	"Sage Stitchford",
	"Blair Clothier",
	"Devon Weaver",
	"Emery Needlebend",
	"Cameron Spoolwright",
	"Reese Threadsong",
	"Rowan Loomsong",
	"Felicity Threadwhistle",
	"Cedric Softstitch",
]

## The name assigned to this Townie.
var townie_name: String


func _ready() -> void:
	_assign_random_name()


## Assign one random name to this Townie.
## The name is stored so it does not change while this Townie exists.
func _assign_random_name() -> void:
	if TOWNIE_NAMES.is_empty():
		push_warning("RandomName: No Townie names available.")
		return

	townie_name = TOWNIE_NAMES.pick_random()

	print("Townie generated: ", townie_name)


## Returns the name assigned to this Townie.
func get_townie_name() -> String:
	return townie_name
	
