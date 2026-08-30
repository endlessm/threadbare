# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name RetellingManager
extends Node2D
## @experimental
##
## Manage the retelling at the Eternal Loom.
##
## Coordinate an array of townies to join the StoryWeaver at the Eternal Loom
## for listening the retelling.
## Call RetellingTownie.go_to_the_loom() on each townie so they join.
## Call EternalLoom.show_retelling_dialogue() when all townies have joined.
## May call RetellingTownie.become_helper() on one townie (at random).
## Call RetellingTownie.leave_the_loom() on each townie so they leave.

## The array of retelling townies in Fray's End.
@export var townies: Array[RetellingTownie] = []

var _waiting_for_townies: Array[RetellingTownie] = []

## The Eternal Loom, for listening to signals and calling
## EternalLoom.show_retelling_dialogue().
@onready var eternal_loom: EternalLoom = %EternalLoom


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	eternal_loom.retelling_started.connect(
		_on_eternal_loom_retelling_started
	)
	eternal_loom.retelling_finished.connect(
		_on_eternal_loom_retelling_finished
	)
	eternal_loom.give_retelling_upgrade.connect(
		_on_eternal_loom_give_retelling_upgrade
	)


func _on_eternal_loom_retelling_started() -> void:
	_waiting_for_townies = townies.duplicate()

	var travel_times: Array[float] = []

	# Prepare each townie and calculate its travel time.
	for t: RetellingTownie in townies:
		var travel_time: float = t.prepare_walk()
		travel_times.append(travel_time)

	# The slowest townie determines the target arrival time.
	var target_time: float = float(travel_times.max())

	print("================================")
	print("Tiempo objetivo: ", target_time, " s")
	print("================================")

	# Start each townie with a delay so they arrive together.
	for i in range(townies.size()):
		var townie: RetellingTownie = townies[i]
		var delay: float = target_time - travel_times[i]

		print(
			"Townie: ",
			townie.name,
			" | Retraso: ",
			delay,
			" s"
		)

		_start_townie_after_delay(townie, delay)


func _start_townie_after_delay(
	townie: RetellingTownie,
	delay: float
) -> void:
	# Connect before starting the townie so the arrival signal is captured.
	if not townie.loom_reached.is_connected(_on_loom_reached.bind(townie)):
		townie.loom_reached.connect(_on_loom_reached.bind(townie))

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	townie.go_to_the_loom()


func _on_loom_reached(townie: RetellingTownie) -> void:
	_waiting_for_townies.erase(townie)

	if _waiting_for_townies.size() == 0:
		eternal_loom.show_retelling_dialogue()


func _on_eternal_loom_retelling_finished() -> void:
	for t: RetellingTownie in townies:
		t.leave_the_loom()


func _on_eternal_loom_give_retelling_upgrade(
	type: InventoryItem.ItemType
) -> void:
	var t: RetellingTownie = townies.pick_random()
	t.become_helper(type)
