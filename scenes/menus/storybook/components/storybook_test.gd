# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const STORYBOOK_SCENE := preload("uid://bhm7fdjvppt8b")

@export_range(0, 100, 1, "or_greater") var quests_amount: int = 30

var english_titles := [
	"The Secret of Crochet",
	"The Needle and the Sorcerer",
	"Conan the Weaver",
	"Return to Fray's End",
	"The Little HushRoom",
]

var spanish_titles := [
	"El tejido oscuro",
	"El Señor de las Agujas",
]

var french_titles := [
	"Le Seigneur des Aiguilles",
]

var titles := english_titles + spanish_titles + french_titles


func _ready() -> void:
	var quests: Array[Quest] = []
	var titles_count: Dictionary[String, int] = {}
	var debug_info := {
		"en": 0,
		"es": 0,
		"fr": 0,
	}
	for t: String in titles:
		titles_count[t] = 0

	for i in range(quests_amount):
		var q := Quest.new()
		var t: String = titles.pick_random()
		titles_count[t] += 1
		q.title = "%s %d" % [t, titles_count[t]] if titles_count[t] > 1 else t

		if t in spanish_titles:
			q.language = "es"
			debug_info["es"] += 1
		elif t in french_titles:
			q.language = "fr"
			debug_info["fr"] += 1
		else:
			q.language = "en"
			debug_info["en"] += 1

		quests.append(q)
	var storybook := STORYBOOK_SCENE.instantiate()
	storybook.quests = quests
	add_child(storybook)
	debug_info["total"] = quests_amount
	prints(debug_info)
