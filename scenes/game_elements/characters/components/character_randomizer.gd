# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CharacterRandomizer
extends CharacterBody2D

## The random seed of this character. Setting another character to the same seed
## will make them identical. Setting it to zero will reset the skin color.
@export var character_seed: int

## The character name. Like sprites and palette, this is picked randomly using the
## [member character_seed].
@export var character_name: String

## The recoloring behavior to use in all sprites.
@export var cel_shading_recolor: CelShadingRecolor

## Where is the character facing. Relative to the character.
@export var look_at_side: Enums.LookAtSide = Enums.LookAtSide.LEFT:
	set = _set_look_at_side

## Click this button to update the randomization according to the [member character_seed].
@export_tool_button("Update") var update_button: Callable = apply_character_randomizations

## Click this button to create a random character.
@export_tool_button("Randomize") var randomize_character_button: Callable = randomize_character

## The inner AnimatedSprite2D nodes.
var animated_sprites: Array[AnimatedSprite2D] = []

## The inner nodes that randomize sprites textures.
var random_texture_nodes: Array[RandomTextureSpriteBehavior] = []

var _undoredo: Object  # EditorUndoRedoManager

var _random_number_generator := RandomNumberGenerator.new()

var _previous_look_at_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED

## The character head node. This can be used to show the head only in the HUD.
@onready var head: AnimatedSprite2D = %AnimatedSprite2DHead


## Randomize the skin color, textures, and name of the character.
## [br][br]
## Do it in a consistent way by first seeding the default random number generator
## with the [member character_seed].
func apply_character_randomizations() -> void:
	_random_number_generator.seed = character_seed

	if cel_shading_recolor:
		cel_shading_recolor.randomize(_random_number_generator)

	for n in random_texture_nodes:
		n.randomize_texture(_random_number_generator)

	if not RandomName.TOWNIE_NAMES.is_empty():
		var name_index := _random_number_generator.randi_range(0, RandomName.TOWNIE_NAMES.size() - 1)
		character_name = RandomName.TOWNIE_NAMES[name_index]


## Set a random seed and randomize the character.
## [br][br]
## With undo/redo when running in the editor.
func randomize_character() -> void:
	var new_character_seed := randi()
	if _undoredo:
		_undoredo.create_action("Randomize character")
		_undoredo.add_undo_property(self, "character_seed", character_seed)
		_undoredo.add_do_property(self, "character_seed", new_character_seed)
		_undoredo.add_undo_property(self, "character_name", character_name)
		_undoredo.add_undo_method(self, "apply_character_randomizations")
		_undoredo.add_do_method(self, "apply_character_randomizations")
		_undoredo.commit_action()
	else:
		character_seed = new_character_seed
		apply_character_randomizations()
		_randomize_all_sprites_progress()


func _ready() -> void:
	_setup_nodes()

	if cel_shading_recolor:
		for node in animated_sprites:
			node.material = cel_shading_recolor.shader_material

	if character_seed:
		apply_character_randomizations()

	if Engine.is_editor_hint():
		var plugin: Node = ClassDB.instantiate("EditorPlugin")
		_undoredo = plugin.get_undo_redo()
		plugin.queue_free()
	else:
		_randomize_all_sprites_progress()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			for node in animated_sprites:
				node.frame = 0


func _traverse(node: Node) -> void:
	if node is AnimatedSprite2D:
		animated_sprites.append(node)
		for child in node.get_children():
			_traverse(child)
	elif node is RandomTextureSpriteBehavior:
		random_texture_nodes.append(node)


func _setup_nodes() -> void:
	animated_sprites = []
	random_texture_nodes = []
	for child in get_children():
		_traverse(child)


func _randomize_all_sprites_progress() -> void:
	if not animated_sprites:
		return
	var default_animation := animated_sprites[-1].animation
	var frames_length := animated_sprites[-1].sprite_frames.get_frame_count(default_animation)
	var random_frame := randi_range(0, frames_length)
	var random_progress := randf()
	for sprite in animated_sprites:
		sprite.play("idle")
		sprite.set_frame_and_progress(random_frame, random_progress)


func _reset_sprite_frames_progress() -> void:
	for node in get_children():
		if node is AnimatedSprite2D:
			(node as AnimatedSprite2D).frame = 0


func _set_look_at_side(new_look_at_side: Enums.LookAtSide) -> void:
	look_at_side = new_look_at_side
	scale.x = -1 if look_at_side == Enums.LookAtSide.RIGHT else 1


func _on_interact_area_interaction_started(_player: Player, from_right: bool) -> void:
	_previous_look_at_side = look_at_side
	if look_at_side != Enums.LookAtSide.UNSPECIFIED:
		look_at_side = Enums.LookAtSide.LEFT if from_right else Enums.LookAtSide.RIGHT


func _on_interact_area_interaction_ended() -> void:
	look_at_side = _previous_look_at_side
