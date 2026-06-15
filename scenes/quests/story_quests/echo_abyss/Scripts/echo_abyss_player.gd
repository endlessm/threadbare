# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EchoAbyssPlayer
extends Player

signal health_changed(current_health: int, max_health: int)
signal essence_changed(current_essence: int, max_essence: int)
signal echo_abyss_defeated

@export_range(1, 99, 1) var max_health: int = 3
@export_range(0, 100, 1) var starting_essence: int = 0
@export_range(1, 100, 1) var max_essence: int = 100
@export var reset_stats_on_ready: bool = true
@export var reload_scene_on_defeat: bool = true
@export_range(0.0, 10.0, 0.1, "suffix:s") var defeat_reload_delay: float = 1.0

var current_health: int = max_health
var current_essence: int = starting_essence


func _ready() -> void:
	super._ready()
	if reset_stats_on_ready:
		current_health = max_health
		current_essence = starting_essence
	else:
		current_health = clampi(current_health, 0, max_health)
		current_essence = clampi(current_essence, 0, max_essence)

	health_changed.emit(current_health, max_health)
	essence_changed.emit(current_essence, max_essence)


func take_damage(amount: int = 1) -> void:
	if amount <= 0 or mode == Mode.DEFEATED:
		return

	set_health(current_health - amount)
	CameraShake.shake()
	$SFX_daño.play()

	if current_health == 0:
		_handle_echo_abyss_defeat()


func heal(amount: int = 1) -> void:
	if amount <= 0:
		return
	set_health(current_health + amount)


func set_health(new_health: int) -> void:
	var clamped_health := clampi(new_health, 0, max_health)
	if current_health == clamped_health:
		return

	current_health = clamped_health
	health_changed.emit(current_health, max_health)


func add_essence(amount: int) -> void:
	if amount <= 0:
		return
	set_essence(current_essence + amount)
	$SFX_esencia.play()

func spend_essence(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_essence < amount:
		return false

	set_essence(current_essence - amount)
	return true


func set_essence(new_essence: int) -> void:
	var clamped_essence := clampi(new_essence, 0, max_essence)
	if current_essence == clamped_essence:
		return

	current_essence = clamped_essence
	essence_changed.emit(current_essence, max_essence)


func get_current_health() -> int:
	return current_health


func get_max_health() -> int:
	return max_health


func get_current_essence() -> int:
	return current_essence


func get_max_essence() -> int:
	return max_essence


func _handle_echo_abyss_defeat() -> void:
	mode = Mode.DEFEATED
	velocity = Vector2.ZERO
	echo_abyss_defeated.emit()
	if owner:
			for nodo in owner.find_children("*", "AudioStreamPlayer", true, false):
				if nodo != $SFX_muerte and nodo.is_playing():
					nodo.stop()
	$SFX_muerte.play()
	if reload_scene_on_defeat:
		await get_tree().create_timer(defeat_reload_delay).timeout
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
