# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const STORYBOOK_SCENE := preload("uid://bhm7fdjvppt8b")

@export_range(0, 100, 1, "or_greater") var quests_amount: int = 30

var titles := [
	"El Señor de las Agujas",
	"The Secret of Crochet",
	"El tejido oscurot",
	"The Needle and the Sorcerer",
	"Conan the Weaver",
	"Return to Fray's End",
	"The Little HushRoom",
	"Le Seigneur des Aiguilles",
]

var spanish_titles := [
	"El Señor de las Agujas",
	"El tejido oscurot",
]

var french_titles := [
	"Le Seigneur des Aiguilles",
]


func _ready() -> void:
	var quests: Array[Quest] = []
	for i in range(quests_amount):
		var q := Quest.new()
		q.title = titles.pick_random()

		if q.title in spanish_titles:
			q.language = "es"
		elif q.title in french_titles:
			q.language = "fr"
		else:
			q.language = "en"

		quests.append(q)
	var storybook := STORYBOOK_SCENE.instantiate()
	storybook.quests = quests
	add_child(storybook)
