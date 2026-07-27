# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Flower
extends Decoration
## A decoration which deterministically picks its texture from a hardcoded list of directories.
##
## The goal here is to be able to add new flowers to a flowerbed in Fray's End by adding a file to
## the repository, without touching any scene in a conflict-prone way.

const TEXTURE_DIRECTORIES := [
	"res://scenes/game_elements/props/decoration/crochenthemum/",
	"res://scenes/game_elements/props/decoration/mushroom/",
	"res://scenes/game_elements/props/decoration/flower/assets/",
]
static var _textures: Array[Texture2D]


static func _load_textures_from(directory_path: String) -> void:
	var files := ResourceLoader.list_directory(directory_path)
	files.sort()
	for file: String in files:
		var path := directory_path.path_join(file)
		var resource := ResourceLoader.load(path)
		if resource is Texture2D:
			_textures.append(resource)
		else:
			push_warning("%s is not a Texture2D" % path)


# Initialises the static _textures list, if not already done
static func _initialise_textures() -> void:
	if _textures:
		return

	for directory_path: String in TEXTURE_DIRECTORIES:
		_load_textures_from(directory_path)


func _validate_property(property: Dictionary) -> void:
	if property.name == "texture":
		# Prevent modifying texture property in inspector: it would be re-set next time the scene
		# loads.
		property.usage |= PROPERTY_USAGE_READ_ONLY
		property.usage |= PROPERTY_USAGE_NO_INSTANCE_STATE

		# Don't store the texture in the scene file: it would be overwritten when new flower images
		# are added.
		property.usage &= ~PROPERTY_USAGE_STORAGE


func _init() -> void:
	_initialise_textures()


func _enter_tree() -> void:
	# Assign a texture to this instance of the flower, in a fashion that is deterministic so long
	# as the set of flowers does not change.
	var tree := get_tree()
	var current_scene := tree.edited_scene_root if Engine.is_editor_hint() else tree.current_scene

	# Don't save a texture in flower.tscn's Sprite2D
	if Engine.is_editor_hint() and self == current_scene:
		return

	var path := current_scene.get_path_to(self)
	texture = _textures[path.hash() % _textures.size()]
