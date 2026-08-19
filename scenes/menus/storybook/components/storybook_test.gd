# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const STORYBOOK_SCENE := preload("uid://bhm7fdjvppt8b")

@export_range(0, 100, 1, "or_greater") var quests_amount: int = 30

var titles := [
	"Lord of the Needles",
	"The Secret of Crochet",
	"The Dark Knit",
	"The Needle and the Sorcerer",
	"Conan the Weaver",
	"Return to Fray's End",
	"The Little HushRoom",
]


func _ready() -> void:
	var quests: Array[Quest] = []
	for i in range(quests_amount):
		var q := Quest.new()
		q.title = titles.pick_random()
		quests.append(q)
	var storybook := STORYBOOK_SCENE.instantiate()
	storybook.quests = quests
	add_child(storybook)
