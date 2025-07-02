@tool
class_name checkpointnathan
extends Area2D

const DEFAULT_SPRITE_FRAMES: SpriteFrames = preload("uid://dmg1egdoye3ns")
const REQUIRED_ANIMATIONS := [&"idle", &"appear"]

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames

@export var dialogue: DialogueResource = preload("uid://bug2aqd47jgyu")
@export_file("*.tscn") var next_scene: String

@onready var spawn_point: SpawnPoint = %SpawnPoint
@onready var sprite: AnimatedSprite2D = %Sprite

var activated := false


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
			warnings.append("sprite_frames is missing the animation: %s" % animation)
	return warnings


func _ready() -> void:
	_set_sprite_frames(sprite_frames)

	if Engine.is_editor_hint():
		return

	sprite.visible = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"):
		return

	activated = true

	sprite.visible = true
	sprite.play(&"appear")
	await sprite.animation_finished
	sprite.play(&"idle")

	# Guardar punto de retorno
	GameState.current_spawn_point = owner.get_path_to(spawn_point)

	# Mostrar diálogo automáticamente (sin necesidad de interacción)
	DialogueManager.show_dialogue_balloon(dialogue, "", [self, body])
	await DialogueManager.dialogue_ended

	# Cambiar a minijuego
	SceneSwitcher.change_to_file_with_transition(next_scene)
