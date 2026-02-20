# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CelShadingRecolor
extends Node
## @experimental
##
## Behavior to recolor a 3-colors cel-shading sprite.
##
## This technique is also called "palette swapping".
## But instead of dealing with a full palette, this will recolor 3 shades.
## Which is the style expected in Threadbare.
## [br][br]
## [b]Note:[/b] This behavior will only work if the [member node_to_recolor] has the
## material "cel_shading_recolor_material.tres" applied to it.
## [br][br]
## One possible use of this is to apply different skin tones to characters.

## Named skin colors
## [br][br]
## From [url]https://carissa-taylor.blogspot.com/p/exploring-racial-diversity-with-your.html[/url]
const SKIN_COLORS: Dictionary[String, Color] = {
	"obsidian": Color(0.2, 0.161, 0.106, 1.0),
	"black": Color(0.251, 0.208, 0.133, 1.0),
	"dark brown": Color(0.31, 0.255, 0.165, 1.0),
	"olive brown": Color(0.392, 0.322, 0.212, 1.0),
	"topaz": Color(0.502, 0.404, 0.271, 1.0),
	"hazel": Color(0.596, 0.482, 0.325, 1.0),
	"sandstone": Color(0.686, 0.553, 0.373, 1.0),
	"olive": Color(0.792, 0.667, 0.494, 1.0),
	"taupe": Color(0.847, 0.749, 0.663, 1.0),
	"birch": Color(0.886, 0.839, 0.816, 1.0),
	"onyx": Color(0.2, 0.165, 0.016, 1.0),
	"umber": Color(0.286, 0.184, 0.024, 1.0),
	"rich brown": Color(0.392, 0.239, 0.027, 1.0),
	"sienna": Color(0.502, 0.275, 0.035, 1.0),
	"copper": Color(0.6, 0.341, 0.114, 1.0),
	"ochre": Color(0.663, 0.451, 0.204, 1.0),
	"bronze": Color(0.769, 0.576, 0.298, 1.0),
	"golden": Color(0.835, 0.686, 0.463, 1.0),
	"sand": Color(0.933, 0.824, 0.651, 1.0),
	"deep brown": Color(0.2, 0.051, 0.016, 1.0),
	"chestnut": Color(0.286, 0.133, 0.098, 1.0),
	"sepia": Color(0.392, 0.2, 0.173, 1.0),
	"warm brown": Color(0.51, 0.239, 0.196, 1.0),
	"clay": Color(0.612, 0.345, 0.282, 1.0),
	"light brown": Color(0.678, 0.439, 0.341, 1.0),
	"deep tan": Color(0.78, 0.537, 0.4, 1.0),
	"tan": Color(0.847, 0.651, 0.514, 1.0),
	"beige": Color(0.91, 0.761, 0.686, 1.0),
	"alabaster": Color(1.0, 0.871, 0.835, 1.0),
	"ebony": Color(0.2, 0.039, 0.086, 1.0),
	"mahogany": Color(0.275, 0.098, 0.09, 1.0),
	"deep brown 2": Color(0.373, 0.149, 0.2, 1.0),
	"rosy brown": Color(0.471, 0.239, 0.243, 1.0),
	"russet": Color(0.643, 0.329, 0.31, 1.0),
	"terracota": Color(0.718, 0.369, 0.349, 1.0),
	"coral": Color(0.796, 0.482, 0.412, 1.0),
	"ruddy": Color(0.867, 0.639, 0.6, 1.0),
	"blush": Color(0.922, 0.745, 0.729, 1.0),
	"pale blossom": Color(0.996, 0.855, 0.859, 1.0),
	"jet black": Color(0.173, 0.016, 0.216, 1.0),
	"night black": Color(0.282, 0.145, 0.251, 1.0),
	"sunset": Color(0.388, 0.176, 0.282, 1.0),
	"rosewood": Color(0.549, 0.278, 0.349, 1.0),
	"soft brown": Color(0.631, 0.369, 0.404, 1.0),
	"dusky rose": Color(0.733, 0.467, 0.506, 1.0),
	"rosy": Color(0.808, 0.596, 0.655, 1.0),
	"blossom": Color(0.882, 0.702, 0.741, 1.0),
	"pink": Color(0.922, 0.78, 0.812, 1.0),
	"pearl": Color(0.949, 0.867, 0.894, 1.0),
}

## The node that will be recolored
## [br][br]
## [b]Note:[/b] This behavior will only work if it has the
## material "cel_shading_recolor_material.tres" applied to it.
@export var node_to_recolor: CanvasItem:
	set = _set_node_to_recolor

## Medium or unshaded color of a 3-colors cel-shading palette
## [br][br]
## Defaults to yellow emoji-like color.
@export var medium_color: Color = Color(0.9, 0.9, 0.0, 1.0):
	set = _set_medium_color

## High or lightened color of a 3-colors cel-shading palette
@export var high_color: Color:
	set = _set_high_color

## Low or darkened color of a 3-colors cel-shading palette
@export var low_color: Color:
	set = _set_low_color

## Whether to the high and low colors from the medium color
@export var automatic_shades: bool = true:
	set = _set_automatic_shades

## Click this button to pick a random color from a list of known skin colors
@export_tool_button("Random Skin Color")
var random_skin_color_button: Callable = set_random_skin_color


func _enter_tree() -> void:
	if not node_to_recolor and get_parent() is CanvasItem:
		node_to_recolor = get_parent()
		medium_color = medium_color


func _set_node_to_recolor(new_node_to_recolor: CanvasItem) -> void:
	node_to_recolor = new_node_to_recolor
	update_configuration_warnings()
	colorize()


func _set_medium_color(new_medium_color: Color) -> void:
	medium_color = new_medium_color
	if automatic_shades:
		high_color = medium_color.lightened(0.2)
		low_color = medium_color.darkened(0.2)
	colorize()


func _set_high_color(new_high_color: Color) -> void:
	high_color = new_high_color
	if automatic_shades:
		return
	colorize()


func _set_low_color(new_low_color: Color) -> void:
	low_color = new_low_color
	if automatic_shades:
		return
	colorize()


func _set_automatic_shades(new_automatic_shades: bool) -> void:
	automatic_shades = new_automatic_shades
	notify_property_list_changed()
	if automatic_shades:
		medium_color = medium_color


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"high_color", "low_color":
			if automatic_shades:
				property.usage |= PROPERTY_USAGE_READ_ONLY


## Apply the colors by setting the shader parameters
func colorize() -> void:
	if not node_to_recolor:
		return
	node_to_recolor.set_instance_shader_parameter("shade_medium_new", medium_color)
	node_to_recolor.set_instance_shader_parameter("shade_high_new", high_color)
	node_to_recolor.set_instance_shader_parameter("shade_low_new", low_color)


## Pick a random color from [constant SKIN_COLORS] and automatically set all shades from it.
func set_random_skin_color() -> void:
	automatic_shades = true
	medium_color = SKIN_COLORS.values().pick_random()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not node_to_recolor:
		warnings.append("The Skin Node must be set.")
		return warnings
	var shader_material: ShaderMaterial = node_to_recolor.material as ShaderMaterial
	if not shader_material:
		warnings.append("The Skin Node material must be a ShaderMaterial.")
		return warnings
	if not shader_material.shader:
		warnings.append("The Skin Node material must have a shader.")
		return warnings
	for uniform_name: String in ["shade_medium_new", "shade_high_new", "shade_low_new"]:
		if node_to_recolor.get_instance_shader_parameter(uniform_name) == null:
			warnings.append("The Node To Recolor must have an instance uniform %s." % uniform_name)
	return warnings
