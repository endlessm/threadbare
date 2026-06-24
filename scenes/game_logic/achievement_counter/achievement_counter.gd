# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name AchievementCounter
extends Node

@export var prefix: String


func increment() -> void:
	if not prefix:
		push_warning("AchievementCounter.add_achievement() was called without a prefix.")
		return
	var fact_name := "%s_count" % prefix
	if fact_name not in GameState.global.facts:
		GameState.global.facts[fact_name] = 1
	else:
		GameState.global.facts[fact_name] += 1
