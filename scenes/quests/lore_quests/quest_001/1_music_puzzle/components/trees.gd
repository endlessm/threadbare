# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

const WOOL_PERCENTAGE: float = 0.4

const TREE_WOOL_GREEN_01 = preload(
	"res://scenes/game_elements/props/tree/components/Tree_Wool_Green_01.png"
)
const TREE = preload("res://scenes/game_elements/props/tree/components/Tree.png")

@export_tool_button("Randomize Trees Appearances") var a = func():
	for child in get_children():
		child.set("tree__texture", TREE if randf() > WOOL_PERCENTAGE else TREE_WOOL_GREEN_01)
