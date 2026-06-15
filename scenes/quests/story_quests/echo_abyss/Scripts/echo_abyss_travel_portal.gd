class_name TravelPortal
extends Node2D

@export_file("*.tscn") var destination_scene: String
@export var dialogue: DialogueResource
@export var dialogue_title := "start"
@export var sprite_frames: SpriteFrames:
	set(new_sprite_frames):
		sprite_frames = new_sprite_frames
		if _animated_sprite:
			_animated_sprite.sprite_frames = sprite_frames
			
@onready var interact_area: InteractArea = %InteractArea
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	_animated_sprite.play("idle")
	if sprite_frames:
		_animated_sprite.sprite_frames = sprite_frames
		
	interact_area.interaction_started.connect(_on_interaction_started)

func _on_interaction_started(player: Player, _from_right: bool) -> void:
	DialogueManager.show_dialogue_balloon(
		dialogue,
		dialogue_title,
		[self, player]
	)

	await DialogueManager.dialogue_ended

	interact_area.end_interaction()

func travel() -> void:
	SceneSwitcher.change_to_file_with_transition(
		destination_scene,
		^"",
		Transition.Effect.FADE,
		Transition.Effect.FADE
	)

func cancel_travel() -> void:
	pass
