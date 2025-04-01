# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InventoryItem
extends Resource

enum ItemType {
	MEMORY,
	IMAGINATION,
	SPIRIT,
}

@export var name: String
@export var type: ItemType
