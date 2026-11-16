# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var time_and_weather: TimeAndWeather = %TimeAndWeather


func _on_set_time(area: InteractArea, time: float) -> void:
	time_and_weather.set_time(time)
	area.end_interaction()
