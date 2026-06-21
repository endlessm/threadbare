# collectible_group.gd
extends Node2D

var count = 0

func _ready():
	$CollectibleItem_1.collected.connect(_on_collected)
	$CollectibleItem_2.collected.connect(_on_collected)
	$CollectibleItem_3.collected.connect(_on_collected)

func _on_collected(_item):
	count += 1
	if count >= 3:
		$CollectibleItem_4.reveal()
