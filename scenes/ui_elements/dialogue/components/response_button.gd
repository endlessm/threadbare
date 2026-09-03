# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Button
## Dialogue response button, possibly with an icon depending on tags

var response: DialogueResponse:
	set = set_response


func set_response(value: DialogueResponse) -> void:
	response = value
	text = response.text

	var thread_type := response.get_tag_value("thread")
	if thread_type and thread_type.to_upper() in InventoryItem.ItemType:
		var item_type: InventoryItem.ItemType = InventoryItem.ItemType[thread_type.to_upper()]
		icon = InventoryItem.with_type(item_type).hud_texture
	else:
		icon = null
