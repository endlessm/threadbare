# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Checkpoint
extends Area2D
## A place where the player respawns if the current scene is reloaded.
##
## A checkpoint is initially invisible. It becomes visible when the player enters the area, which
## activates the checkpoint. When the current scene is reloaded (due to the player being detected in
## a stealth challenge, for example), the player will respawn at the most recently activated
## checkpoint.

const DEFAULT_SPRITE_FRAMES: SpriteFrames = preload("uid://dmg1egdoye3ns")

## Animations that [member sprite_frames] must have.
##
## [code]appear[/code] is played when the player activates the checkpoint by moving close to it,
## and should not loop.
##
## [code]idle[/code] is played once the [code]appear[/code] animation finishes.
const REQUIRED_ANIMATIONS := [&"idle", &"appear"]

## Animations for this checkpoint. The SpriteFrames must have specific animations;
## see [constant Checkpoint.REQUIRED_ANIMATIONS].
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames

## Dialogue to trigger when the player interacts with the checkpoint. If empty, the player will not
## be able to interact with the checkpoint.
@export var dialogue: DialogueResource = preload("uid://bug2aqd47jgyu")

## The point where the player will spawn.
@onready var spawn_point: SpawnPoint = %SpawnPoint

## The sprite displayed when this checkpoint is activate.
@onready var sprite: AnimatedSprite2D = %Sprite

@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: TalkBehavior = %TalkBehavior


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAMES
	sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array = []
	for animation: StringName in REQUIRED_ANIMATIONS:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)
	return warnings


func _ready() -> void:
	_set_sprite_frames(sprite_frames)

	if Engine.is_editor_hint():
		return

	talk_behavior.dialogue = dialogue
	sprite.visible = false
	body_entered.connect(func(_body: Node2D) -> void: self.activate())
	interact_area.interaction_started.connect(_on_interaction_started)
	interact_area.interaction_ended.connect(_on_interaction_ended)


## Makes this the active checkpoint.
func activate() -> void:
	GameState.set_current_spawn_point(owner.get_path_to(spawn_point))
	if sprite.visible:
		return

	sprite.visible = true
	sprite.play(&"appear")
	interact_area.disabled = dialogue == null
	await sprite.animation_finished
	sprite.play(&"idle")


func _on_interaction_started(_player: Player, from_right: bool) -> void:
	sprite.flip_h = from_right


func _on_interaction_ended() -> void:
	sprite.flip_h = false
