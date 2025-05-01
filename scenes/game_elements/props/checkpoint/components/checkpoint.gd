# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Checkpoint
extends Area2D
## A place where the player respawns if the current scene is reloaded.

const DIALOGUE: DialogueResource = preload(
	"res://scenes/game_elements/props/checkpoint/components/checkpoint.dialogue"
)

## The point where the player will spawn.
@onready var spawn_point: SpawnPoint = %SpawnPoint

## The sprite displayed when this checkpoint is activated
@onready var sprite: Sprite2D = %Sprite

## The collision shape for the sprite, when this checkpoint is activated
@onready var collision_shape: CollisionShape2D = %CollisionShape

@onready var interact_area: InteractArea = %InteractArea


func _ready() -> void:
	sprite.visible = false
	body_entered.connect(func(_body: Node2D) -> void: self.activate())
	interact_area.interaction_started.connect(_on_interaction_started)


## Makes this the active checkpoint.
func activate() -> void:
	GameState.current_spawn_point = owner.get_path_to(spawn_point)
	sprite.visible = true
	collision_shape.set_deferred(&"disabled", false)
	interact_area.disabled = false


func _on_interaction_started(player: Player, _from_right: bool) -> void:
	DialogueManager.show_dialogue_balloon(DIALOGUE, "", [self, player])
	await DialogueManager.dialogue_ended
	interact_area.interaction_ended.emit()
