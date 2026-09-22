# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name TaggedItem
extends Resource
## An [InventoryItem] that knows where it came from

@export var item: InventoryItem
@export var quest_path: String
@export var source_scene: String
## TODO: construct unique node path here...
@export var source_node: NodePath


static func make(an_item: InventoryItem, quest: Quest, a_source_node: Node = null) -> TaggedItem:
	var ci := new()
	ci.item = an_item
	ci.quest_path = quest.resource_path if quest else ""
	if a_source_node:
		ci.source_scene = a_source_node.owner.scene_file_path
		# TODO: use_unique_path doesn't work when called on the target's owner.
		# Reported as https://github.com/godotengine/godot/issues/122411. If
		# eventually fixed, remove the condition and just keep the else branch.
		if a_source_node.unique_name_in_owner:
			ci.source_node = "%" + a_source_node.name
		else:
			ci.source_node = a_source_node.owner.get_path_to(a_source_node, true)
	return ci


func matches(that: TaggedItem) -> bool:
	return (
		self.item == that.item
		and self.source_scene == that.source_scene
		and self.source_node == that.source_node
	)
