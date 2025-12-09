# Copyright 2024 iseesharp83
# Copyright 2025 Endless Access LLC
# SPDX-License-Identifier: MIT
#
# Derived from
# https://bitbucket.org/iseesharp83workspace/kenney-spritesheet-importer-godot-plugin.
@tool
extends EditorScript

const BASE_PATH := "res://assets/third_party/inputs/atlas_kenney_input_prompts_1.4"
const SHEETS := [
	"xbox/xbox-series_sheet_default.xml",
	"playstation/playstation-series_sheet_default.xml",
	"keyboard/keyboard-&-mouse_sheet_default.xml",
	"steam-deck/steam-deck_sheet_default.xml",
	"nintendo_switch/nintendo-switch_sheet_default.xml",
]

# Whether to import new assets, or just refresh existing ones
const IMPORT_NEW := true


func import(spritesheet_xml_file: String) -> void:
	var atlas := read_kenney_sprite_sheet(spritesheet_xml_file)
	if not atlas:
		return

	var source_file: String = atlas["imagePath"]
	var full_image: Texture2D = load(source_file)
	if not full_image:
		printerr("Failed to load image file: " + source_file)
		return

	var folder := spritesheet_xml_file.get_base_dir()
	create_atlas_textures(folder, full_image, atlas)


func create_atlas_textures(folder: String, full_image: Texture2D, atlas: Dictionary):
	for sprite: Dictionary in atlas.sprites:
		if not create_atlas_texture(folder, full_image, sprite):
			return false
	return true


func create_atlas_texture(folder: String, full_image: Texture2D, sprite: Dictionary):
	var name := "%s/%s.%s" % [folder, sprite.name, "tres"]
	var texture: AtlasTexture
	if ResourceLoader.exists(name, "AtlasTexture"):
		texture = ResourceLoader.load(name, "AtlasTexture")
	elif IMPORT_NEW:
		texture = AtlasTexture.new()
	else:
		return true

	# The Sparrow/Kenney y-axis is inverted compared to Godot's
	var y: float = full_image.get_height() - (sprite.y + sprite.height)
	var region := Rect2(sprite.x, y, sprite.width, sprite.height)

	if texture.atlas == full_image and texture.region == region:
		# Don't re-save the texture if it hasn't changed, avoiding Godot
		# re-generating the scene file resource IDs sometimes
		return true

	texture.atlas = full_image
	texture.region = Rect2(
		sprite.x, full_image.get_height() - (sprite.y + sprite.height), sprite.width, sprite.height
	)
	return save_resource(name, texture)


func save_resource(name: String, texture: AtlasTexture) -> bool:
	var status = ResourceSaver.save(texture, name)
	if status != OK:
		printerr("Failed to save resource " + name)
		return false
	return true


func read_kenney_sprite_sheet(source_file: String) -> Dictionary:
	var atlas: Dictionary
	var sprites: Array[Dictionary]
	var parser := XMLParser.new()
	if OK == parser.open(source_file):
		var read = parser.read()
		if read == OK:
			atlas["sprites"] = sprites
		while read != ERR_FILE_EOF:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT:
				var node_name = parser.get_node_name()
				match node_name:
					"TextureAtlas":
						atlas["imagePath"] = source_file.get_base_dir().path_join(
							parser.get_named_attribute_value("imagePath")
						)
					"SubTexture":
						var sprite = {}
						sprite["name"] = parser.get_named_attribute_value("name")
						sprite["x"] = float(parser.get_named_attribute_value("x"))
						sprite["y"] = float(parser.get_named_attribute_value("y"))
						sprite["width"] = float(parser.get_named_attribute_value("width"))
						sprite["height"] = float(parser.get_named_attribute_value("height"))
						sprites.append(sprite)
			read = parser.read()
	return atlas


func _run() -> void:
	for relative_path: String in SHEETS:
		var source_file := BASE_PATH.path_join(relative_path)
		prints("Importing sprites from", source_file)
		import(source_file)
