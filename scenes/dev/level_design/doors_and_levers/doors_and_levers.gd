# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var combined_toggleables: Array[Toggleable]

@onready var timed_lever: Lever = %TimedLever
@onready var lever_timer: Timer = %LeverTimer

@onready var combined_lever_1: Lever = %CombinedLever1
@onready var combined_lever_2: Lever = %CombinedLever2


func _ready() -> void:
	timed_lever.toggled.connect(_on_timed_lever_toggled)
	lever_timer.timeout.connect(_lever_timer_timeout)
	combined_lever_1.toggled.connect(_on_combined_lever_toggled)
	combined_lever_2.toggled.connect(_on_combined_lever_toggled)


func _on_timed_lever_toggled(is_on: bool) -> void:
	if is_on:
		lever_timer.start()


func _lever_timer_timeout() -> void:
	timed_lever.toggle(false)


func _on_combined_lever_toggled(_is_on: bool) -> void:
	var toggled := combined_lever_1.is_on and combined_lever_2.is_on
	for t in combined_toggleables:
		t.set_toggled(toggled)
