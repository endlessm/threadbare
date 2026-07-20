# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const HUM_WAVE := preload("res://scenes/quests/lore_quests/quest_004/menhir/hum_wave.tscn")

@export var required_ability: Enums.PlayerAbilities = Enums.PlayerAbilities.ABILITY_C
@export var hum_key: Key = KEY_Q
@export var radius: float = 200.0
@export var grow_time: float = 0.5
@export var hum_sound: AudioStream = preload(
	"res://scenes/quests/lore_quests/quest_004/assets/audio/humEffect.wav"
)

var _on_cooldown: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).physical_keycode == hum_key:
			_try_hum()


func _try_hum() -> void:
	if _on_cooldown:
		return
	if not GameState.player.has_ability(required_ability):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	_hum(player.global_position)


func _hum(origin: Vector2) -> void:
	_on_cooldown = true

	var parent := get_tree().current_scene

	if hum_sound:
		var sfx := AudioStreamPlayer2D.new()
		sfx.stream = hum_sound
		sfx.bus = &"SFX"
		parent.add_child(sfx)
		sfx.global_position = origin
		sfx.play()
		sfx.finished.connect(sfx.queue_free)

	var wave: Node2D = HUM_WAVE.instantiate()
	parent.add_child(wave)
	wave.global_position = origin
	wave.play(radius, grow_time)

	await get_tree().create_timer(grow_time).timeout

	for menhir: Node in get_tree().get_nodes_in_group("menhir"):
		if menhir is Node2D and menhir.has_method("got_hummed"):
			if origin.distance_to((menhir as Node2D).global_position) <= radius:
				menhir.got_hummed()

	_on_cooldown = false
