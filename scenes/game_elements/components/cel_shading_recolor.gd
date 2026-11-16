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
## [b]Note:[/b] This behavior will only work if the [member shader_material] is a
## duplicate of "cel_shading_recolor_material.tres".
## [br][br]
## [b]Note:[/b] A node can be set in [member node_to_recolor] as a shortcut to
## use its material directly.
## [br][br]
## One possible use of this is to apply different skin tones to characters.
## [br][br]
## Share the [member shader_material] to apply the same recoloring to multiple
## sprites (multiple parts of the same character, for instance).

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

const HAIR_COLORS: Dictionary[String, Color] = {
	"blonde": Color(0.93, 0.852, 0.273, 1.0),
	"dark blonde": Color(0.831, 0.698, 0.264, 1.0),
	"dark blonde 2": Color(0.813, 0.623, 0.198, 1.0),
	"medium brown": Color(0.629, 0.406, 0.165, 1.0),
	"dark brown": Color(0.466, 0.322, 0.139, 1.0),
	"dark brown 2": Color(0.41, 0.241, 0.116, 1.0),
	"black": Color(0.133, 0.194, 0.247, 1.0),
	"black 2": Color(0.066, 0.064, 0.112, 1.0),
	"auburn": Color(0.598, 0.324, 0.279, 1.0),
	"red": Color(0.772, 0.325, 0.274, 1.0),
	"gray": Color(0.755, 0.812, 0.842, 1.0),
	"white": Color(0.898, 0.923, 0.936, 1.0),
}

const LINE_COLOR := Color(0x161c2eff)
const LINE_COLOR_LIGHT := Color(0x364356ff)

const CLOTH_COLORS: Dictionary[String, Color] = {
	"magnolia": Color(0.805, 0.676, 0.461, 1.0),
	"dusty rose": Color(0.662, 0.41, 0.425, 1.0),
	"orange": Color(0.809, 0.322, 0.105, 1.0),
	"violet": Color(0.437, 0.279, 0.492, 1.0),
	"amaranth purple": Color(0.662, 0.109, 0.446, 1.0),
	"red": Color(0.773, 0.109, 0.239, 1.0),
	"blue": Color(0.177, 0.341, 0.542, 1.0),
	"blue velvet": Color(0.024, 0.235, 0.698, 1.0),
	"dark grey": Color(0.281, 0.366, 0.453, 1.0),
	"brown": Color("af5d23"),
	"green": Color(0.399, 0.546, 0.437, 1.0),
	"black": Color(0.018, 0.039, 0.023, 1.0),
}

const SKIN_PALETTE_INDEX := 0
const HAIR_PALETTE_INDEX := 4
const CLOTH_PALETTE_INDEX := 8

const TOWNIE_KEYS_PALETTE = preload("uid://bt0d8ui0rahnd")

## The shader material to modify.
## If [member node_to_recolor] has a material of type [ShaderMaterial], that one will be used.
## [b]Note:[/b] This behavior will only work if this
## material is a duplicate of "cel_shading_recolor_material.tres".
@export var shader_material: ShaderMaterial

## The node that will be recolored
## [br][br]
## [b]Note:[/b] This behavior will only work if it has the
## material "cel_shading_recolor_material.tres" applied to it.
@export var node_to_recolor: CanvasItem:
	set = _set_node_to_recolor

## The source or "key" colors to change.
@export var key_colors_palette: ColorPalette = TOWNIE_KEYS_PALETTE

## The output or final colors. Each key color in [member key_colors] will map to a color
## of the same index position in this palette.
@export var new_colors_palette: ColorPalette

## Click this button to update the colors.
@export_tool_button("Update") var update_button: Callable = colorize

## Click this button to pick random skin, hair and cloth colors.
@export_tool_button("Randomize") var randomize_button: Callable = randomize

## Click this button to pick a random color from a list of known skin colors.
@export_tool_button("Random Skin Color")
var random_skin_color_button: Callable = set_random_skin_color

## Click this button to pick a random color from a list of known hair colors.
@export_tool_button("Random Hair Color")
var random_hair_color_button: Callable = set_random_hair_color

## Click this button to pick a random color from a list of known cloth colors.
@export_tool_button("Random Cloth Color")
var random_cloth_color_button: Callable = set_random_cloth_color


func _ready() -> void:
	colorize()


func _set_node_to_recolor(new_node_to_recolor: CanvasItem) -> void:
	node_to_recolor = new_node_to_recolor
	if not shader_material and node_to_recolor:
		shader_material = node_to_recolor.material as ShaderMaterial
		update_configuration_warnings()
		colorize()


## Apply the colors by setting the shader parameters
func colorize() -> void:
	if not new_colors_palette:
		new_colors_palette = ColorPalette.new()
	if not shader_material:
		return

	var color_count := new_colors_palette.colors.size()

	var source: PackedInt32Array
	source.resize(color_count * 3)

	var output: PackedVector3Array
	output.resize(color_count)

	for i in range(key_colors_palette.colors.size()):
		var source_color := key_colors_palette.colors[i]
		source[i * 3 + 0] = source_color.r8
		source[i * 3 + 1] = source_color.g8
		source[i * 3 + 2] = source_color.b8

	for i in range(color_count):
		var color := new_colors_palette.colors[i]
		output[i] = Vector3(color.r, color.g, color.b)

	shader_material.set_shader_parameter("color_count", color_count)
	shader_material.set_shader_parameter("key_colors", source)
	shader_material.set_shader_parameter("new_colors", output)


func _change_colors(
	in_colors: PackedColorArray,
	colors_data: Dictionary[String, Color],
	palette_index: int,
	rng: RandomNumberGenerator = null
) -> PackedColorArray:
	var out_colors := in_colors.duplicate()
	if out_colors.size() < palette_index + 4:
		out_colors.resize(palette_index + 4)

	var random_int: int = rng.randi() if rng else randi()
	var index := random_int % colors_data.size()
	var medium_color: Color = colors_data.values()[index]
	var high_color := medium_color.lightened(0.2)
	var low_color := medium_color.darkened(0.2)

	out_colors.set(palette_index + 0, high_color)
	out_colors.set(palette_index + 1, medium_color)
	out_colors.set(palette_index + 2, low_color)

	if low_color.v < 0.3:
		out_colors.set(palette_index + 3, LINE_COLOR_LIGHT)  #medium_color.lightened(0.7))
	else:
		out_colors.set(palette_index + 3, LINE_COLOR)

	return out_colors


## Pick random colors for skin, hair and cloth.
func randomize(rng: RandomNumberGenerator = null) -> void:
	if not new_colors_palette:
		new_colors_palette = ColorPalette.new()
	var skin_colors := _change_colors(
		new_colors_palette.colors, SKIN_COLORS, SKIN_PALETTE_INDEX, rng
	)
	var skin_hair_colors := _change_colors(skin_colors, HAIR_COLORS, HAIR_PALETTE_INDEX, rng)
	var skin_hair_cloth_colors := _change_colors(
		skin_hair_colors, CLOTH_COLORS, CLOTH_PALETTE_INDEX, rng
	)
	new_colors_palette.set_colors(skin_hair_cloth_colors)
	colorize()


## Pick a random color from [constant SKIN_COLORS] and automatically set high/low shades from it.
func set_random_skin_color(rng: RandomNumberGenerator = null) -> void:
	var new_colors := _change_colors(
		new_colors_palette.colors, SKIN_COLORS, SKIN_PALETTE_INDEX, rng
	)
	new_colors_palette.set_colors(new_colors)
	colorize()


## Pick a random color from [constant HAIR_COLORS] and automatically set high/low shades from it.
func set_random_hair_color(rng: RandomNumberGenerator = null) -> void:
	var new_colors := _change_colors(
		new_colors_palette.colors, HAIR_COLORS, HAIR_PALETTE_INDEX, rng
	)
	new_colors_palette.set_colors(new_colors)
	colorize()


## Pick a random color from [constant CLOTH_COLORS] and automatically set high/low shades from it.
func set_random_cloth_color(rng: RandomNumberGenerator = null) -> void:
	var new_colors := _change_colors(
		new_colors_palette.colors, CLOTH_COLORS, CLOTH_PALETTE_INDEX, rng
	)
	new_colors_palette.set_colors(new_colors)
	colorize()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not shader_material:
		warnings.append("The shader material must be set.")
		return warnings
	if not shader_material.shader:
		warnings.append("The shader material must have a shader.")
		return warnings
	for uniform_name: String in ["color_count", "key_colors", "new_colors"]:
		if shader_material.get_shader_parameter(uniform_name) == null:
			warnings.append("The material must have an uniform %s." % uniform_name)
	return warnings
