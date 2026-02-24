# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name TimeAndWeather
extends Node2D
## @experimental
##
## Add post-processing and visual effects.
##
## This is a drop-in effect. Place this node on top of all
## the elements of your scene, at the very bottom of the SceneTree.
##
## TODO: Randomize the weather per day.
## TODO: Add sound effects. What is a morning without dawn chorus?

## The amount of seconds in a day.
const SECONDS_PER_DAY: float = 24 * 60 * 60

## Use system time for determining the time in game.
## [br][br]
## For example if the system time is 15 (3 PM) and the time scale is:[br]
## - 1: 15 (same time in game than in system).
## - 2: 6 (30 hours in game have passed today).
## - 4: 12 (noon in game, exactly 2 and a half days have passed in game today).
## - 8: 0 (midnight in game, exactly 5 days have passed in game today).
@export var use_system_time: bool = true:
	set = _set_use_system_time

## The start time, when not using the system time.[br]
## - 0: Midnight.[br]
## - 4: 4 AM.[br]
## - 12: Noon.[br]
## - 16: 4 PM.[br]
@export_range(0.0, 24.0, 0.1) var start_time: float = 10.0

## How fast should time pass in the game.[br]
## - 1: One day in game matches one day in reality. Don't do this![br]
## - 24: One hour in game matches one day in reality.[br]
## - 144: 10 minutes in game matches one day in reality (default).[br]
## - 1440: One minute in game matches one day in reality.[br]
## - 3600: 24 seconds in game matches one day in reality.[br]
@export_range(1.0, 3600.0, 1.0) var time_scale: float = 144.0:
	set = _set_time_scale

@export_group("Debugging")

## Display debugging information on screen.
@export var show_debug_label: bool = false

## The environment for post-processing effects.
@onready var world_environment: WorldEnvironment = %WorldEnvironment

## The day-night cycle is in this animation player.
@onready var animation_player: AnimationPlayer = %AnimationPlayer

## The clouds shadow overlay effect.
@onready var clouds_shadow: Parallax2D = %CloudsShadow

## The fog overlay effect.
@onready var fog: Parallax2D = %Fog

@onready var lights_on_timer: Timer = %LightsOnTimer
@onready var lights_off_timer: Timer = %LightsOffTimer
@onready var clouds_shadow_start_timer: Timer = %CloudsShadowStartTimer
@onready var clouds_shadow_stop_timer: Timer = %CloudsShadowStopTimer
@onready var fog_start_timer: Timer = %FogStartTimer
@onready var fog_stop_timer: Timer = %FogStopTimer

## Label to show debug information.
@onready var debug_label: Label = %DebugLabel


func _set_use_system_time(new_use_system_time: bool) -> void:
	use_system_time = new_use_system_time
	notify_property_list_changed()


func _set_time_scale(new_time_scale: float) -> void:
	time_scale = new_time_scale
	if Engine.is_editor_hint():
		return
	if not animation_player:
		return
	# The current animation length (in seconds) corresponds to 1 day.
	var animation_scale := SECONDS_PER_DAY / animation_player.current_animation_length
	animation_player.speed_scale = time_scale / animation_scale


func _seek_animation(new_time: float) -> void:
	if not animation_player:
		return
	animation_player.seek(new_time)


func _schedule_in_one_day(timer: Timer) -> void:
	timer.wait_time = SECONDS_PER_DAY / time_scale
	timer.start()


func _schedule_timer(timer: Timer, time: float, current_time: float) -> void:
	var time_difference := time - current_time
	if time_difference == 0:
		_schedule_in_one_day(timer)
		return
	var wait_time := fposmod(time_difference, 24) * 60 * 60 / time_scale
	timer.wait_time = wait_time
	timer.start()


## Set the time.
## [br][br]
## The parameter new_time is a float between 0.0 and 24.0,
## representing the time of day.
func set_time(new_time: float) -> void:
	_seek_animation(new_time)

	# Change game state darkness so artificial lights can turn on/off.
	var lights_on := new_time < 5 or new_time >= 19
	GameState.change_lights(lights_on, true)
	_schedule_timer(lights_off_timer, 5, new_time)
	_schedule_timer(lights_on_timer, 19, new_time)

	# Cloud shadows during the day:
	clouds_shadow.visible = new_time >= 6 and new_time < 17
	_schedule_timer(clouds_shadow_start_timer, 6, new_time)
	_schedule_timer(clouds_shadow_stop_timer, 17, new_time)

	# Fog during late night and early in the morning:
	fog.visible = new_time < 5 or new_time >= 22
	_schedule_timer(fog_start_timer, 22, new_time)
	_schedule_timer(fog_stop_timer, 5, new_time)


## Get the current time.
## [br][br]
## This is no other than the current animation cycle position.
func get_current_time() -> float:
	return animation_player.current_animation_position


## Get the current sky color.
## [br][br]
## Use this to tint reflecting surfaces (like water).
func get_sky_color() -> Color:
	return world_environment.environment.background_color


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"start_time":
			if use_system_time:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if use_system_time:
		var unix_time := Time.get_unix_time_from_system()
		var system_seconds := fmod(unix_time, SECONDS_PER_DAY)
		var system_hour := system_seconds / 60.0 / 60.0
		var scaled_hour := fmod(system_hour * time_scale, 24)
		set_time(scaled_hour)
	else:
		set_time(start_time)
	_set_time_scale(time_scale)
	debug_label.visible = show_debug_label
	debug_label.process_mode = (
		Node.PROCESS_MODE_INHERIT if show_debug_label else Node.PROCESS_MODE_DISABLED
	)


func _on_lights_on_timer_timeout() -> void:
	GameState.change_lights(true)
	_schedule_in_one_day(lights_on_timer)


func _on_lights_off_timer_timeout() -> void:
	GameState.change_lights(false)
	_schedule_in_one_day(lights_off_timer)


func _on_clouds_shadow_start_timer_timeout() -> void:
	if clouds_shadow.has_method("randomize"):
		await clouds_shadow.randomize()
	if clouds_shadow.has_method("fade_in"):
		clouds_shadow.fade_in()
	_schedule_in_one_day(clouds_shadow_start_timer)


func _on_clouds_shadow_stop_timer_timeout() -> void:
	if clouds_shadow.has_method("fade_out"):
		clouds_shadow.fade_out()
	_schedule_in_one_day(clouds_shadow_stop_timer)


func _on_fog_start_timer_timeout() -> void:
	if fog.has_method("randomize"):
		await fog.randomize()
	if fog.has_method("fade_in"):
		fog.fade_in()
	_schedule_in_one_day(fog_start_timer)


func _on_fog_stop_timer_timeout() -> void:
	if fog.has_method("fade_out"):
		fog.fade_out()
	_schedule_in_one_day(fog_stop_timer)
