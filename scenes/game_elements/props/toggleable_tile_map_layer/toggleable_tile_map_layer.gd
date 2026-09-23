# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ToggleableTileMapLayer
extends Toggleable
## Use a [TileMapLayer] as an unlockable door/barrier
##
## A [Toggleable] that disables a [TileMapLayer] when enabled, and enables it
## when disabled. Use this, for example, together with [QuestProgressUnlocker]
## to block off sections of Fray's End with water or void until the player has
## completed certain quests. (Depending on the level design, a door may be more
## appropriate.) To make the layer be [b]enabled[/b] when toggled on instead,
## set [member invert].
## [br][br]
## This script may be attached to a [TileMapLayer] directly; instantiated as a
## child of a [TileMapLayer]; or instantiated elsewhere in the tree, in which
## case [member target] must be set.

## Name of the shader parameter that drives the transition.
const PROGRESS_PARAMETER := &"progress"

## Property path of [constant PROGRESS_PARAMETER], to animate it with a [Tween].
const PROGRESS_PROPERTY := ^"shader_parameter/progress"

## The [TileMapLayer] to be toggled. If this script is attached directly to a
## [TileMapLayer], this property cannot be changed.
@export var target: TileMapLayer:
	set = _set_target

## If true, flip the toggled state, so that [method
## set_toggled][code](false)[/code] causes [member target] to be disabled rather
## than enabled.
@export var invert: bool = false

## Duration of a full fade transition. The state is committed halfway through it.
## A transition that interrupts another one is shorter, in proportion to the
## distance left to cover. Set to 0 for no animation, so that the state changes
## immediately.
@export_range(0.0, 10.0, 0.1, "suffix:s") var transition_duration: float = 3.0

var _transition_tween: Tween

## The material that drives the transition, or null when [member target] cannot
## be animated. Resolved once, when [member target] is set.
var _transition_material: ShaderMaterial


func _enter_tree() -> void:
	if not target:
		if (self as Node2D) is TileMapLayer:
			target = (self as Node2D) as TileMapLayer
		elif get_parent() is TileMapLayer:
			target = get_parent()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"target":
			if target == self:
				property.usage |= PROPERTY_USAGE_READ_ONLY
				property.usage &= ~PROPERTY_USAGE_STORAGE


func _set_target(value: TileMapLayer) -> void:
	target = value
	_transition_material = _find_transition_material()
	notify_property_list_changed()
	update_configuration_warnings()


## Returns the [ShaderMaterial] that drives the transition, looked up in [member
## target] first and then in its first ancestor [CanvasGroup], because the
## material may be applied to a group that composites this layer together with
## others instead of to the layer itself.
## [br][br]
## Returns null when neither has a usable material, in which case the state
## changes with no animation.
func _find_transition_material() -> ShaderMaterial:
	if not target:
		return null

	var own_material := _as_transition_material(target.material)
	if own_material:
		return own_material

	var ancestor := target.get_parent()
	while ancestor:
		if ancestor is CanvasGroup:
			return _as_transition_material((ancestor as CanvasGroup).material)
		ancestor = ancestor.get_parent()

	return null


## Returns [param material] if it can drive the transition, which means being a
## [ShaderMaterial] with a [constant PROGRESS_PARAMETER] parameter. Returns null
## otherwise.
static func _as_transition_material(target_material: Material) -> ShaderMaterial:
	var shader_material := target_material as ShaderMaterial
	if not shader_material:
		return null
	if shader_material.get_shader_parameter(PROGRESS_PARAMETER) == null:
		return null
	return shader_material


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not target and (self as Node2D) is not TileMapLayer:
		warnings.push_back("Target is not set")
	return warnings


func set_toggled(value: bool, immediate: bool = false) -> void:
	if _transition_tween:
		_transition_tween.kill()
	var enabled := value if invert else not value

	var can_animate := not immediate and transition_duration > 0.0 and _transition_material != null
	if not can_animate:
		# Settle the effect on the value it would have at the end of a
		# transition, so that the node is correctly initialized and a later
		# transition starts from a known state.
		if _transition_material:
			_transition_material.set_shader_parameter(PROGRESS_PARAMETER, 1.0 if enabled else 0.0)
		_set_interactions_enabled(enabled)
		target.enabled = enabled
		return

	# Keep the layer rendered and visible for the whole transition, so that the
	# shader has something to fade in or out.
	target.enabled = true

	# Split the tween in two halves. Halfway through, commit everything except
	# rendering, so that the change is felt in the middle of the transition.
	# Rendering is only disabled at the very end, because turning it off earlier
	# would hide the second half of the transition.
	# Each half lasts in proportion to the distance it covers, so that the effect
	# moves at a constant speed and interrupting a transition does not restart
	# the full duration.
	var current_progress: float = _transition_material.get_shader_parameter(PROGRESS_PARAMETER)
	var progress: float = 1.0 if enabled else 0.0
	var first_half := transition_duration * absf(0.5 - current_progress)
	var second_half := transition_duration * 0.5

	_transition_tween = create_tween()
	_transition_tween.tween_property(_transition_material, PROGRESS_PROPERTY, 0.5, first_half)
	_transition_tween.tween_callback(_set_interactions_enabled.bind(enabled))
	_transition_tween.tween_property(_transition_material, PROGRESS_PROPERTY, progress, second_half)
	_transition_tween.tween_callback(func() -> void: target.enabled = enabled)


## Enables or disables everything in [member target] that is not about rendering,
## so that the layer keeps being drawn while the transition finishes.
func _set_interactions_enabled(enabled: bool) -> void:
	target.collision_enabled = enabled
	target.navigation_enabled = enabled
	target.occlusion_enabled = enabled
