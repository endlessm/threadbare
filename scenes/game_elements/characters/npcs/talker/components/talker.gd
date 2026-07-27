# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Talker
extends NPC
## @deprecated: Instead of instantiating this class, use a [TalkBehavior] node instead.

@export var dialogue: DialogueResource = preload("uid://cc3paugq4mma4")

var _previous_look_at_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED

@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: Node = %TalkBehavior


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	talk_behavior.dialogue = dialogue
	interact_area.interaction_started.connect(_on_interaction_started)
	interact_area.interaction_ended.connect(_on_interaction_ended)


func _on_interaction_started(_player: Player, from_right: bool) -> void:
	_previous_look_at_side = look_at_side
	if look_at_side != Enums.LookAtSide.UNSPECIFIED:
		look_at_side = Enums.LookAtSide.RIGHT if from_right else Enums.LookAtSide.LEFT


func _on_interaction_ended() -> void:
	look_at_side = _previous_look_at_side
