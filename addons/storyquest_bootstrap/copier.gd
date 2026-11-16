# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends RefCounted

const STORYQUESTS_PATH := "res://scenes/quests/story_quests/"
const TEMPLATE_PREFIX := "NO_EDIT"
const TEMPLATE_PATH := STORYQUESTS_PATH + TEMPLATE_PREFIX + "/"
const QUEST_FILENAME := "quest.tres"

## Map from UID to already-copied resource
var orig_uid_to_copy: Dictionary[String, Resource]

## Name of root directory of quest, e.g. [code]"stella"[/code]
var quest_name: String

## Root directory of copied StoryQuest,
## i.e. [code]STORYQUESTS_PATH.path_join(quest_name)[/code]
var target_path: String

var _title: String
var _description: String

var _debugging: bool = true
var _depth: int = 0


func _init(filename: String, title: String, description: String) -> void:
	quest_name = filename
	target_path = STORYQUESTS_PATH.path_join(filename)
	self._title = title
	self._description = description


func _debug(args: Array[Variant]) -> void:
	if _debugging:
		print("  ".repeat(_depth) + " ".join(args.map(str)))


func is_template_uid(uid: String) -> bool:
	return uid.begins_with("uid://") and ResourceUID.uid_to_path(uid).begins_with(TEMPLATE_PATH)


func is_template_resource(resource: Resource) -> bool:
	return resource.resource_path.begins_with(TEMPLATE_PATH)


func reimport(_path: String) -> void:
	var fs := EditorInterface.get_resource_filesystem()
	# TODO: The following should be enough instead of a full scan, but it doesn't work.
	#
	# for f in files_to_reimport:
	# 	fs.update_file(f)
	# fs.reimport_files(files_to_reimport)
	#
	# Where files_to_reimport contains the paths of files copied with DirAccess.copy_absolute()
	_debug(["Starting reimport"])

	fs.scan()
	if fs.is_scanning():
		_debug(["Awaiting resources_reimported"])
		# TODO: add a timeout, sometimes this signal is apparently missed
		await fs.resources_reimported

	_debug(["Reimport finished"])


func maybe_copy_properties(
	node: Node,
	path: String,
) -> void:
	for property: Dictionary in node.get_property_list():
		var name: String = property["name"]
		var value_copy: Variant = null
		match property["type"]:
			TYPE_STRING:
				var value: String = node.get(name)
				if is_template_uid(value):
					_debug([path, name, "needs copy"])
					value_copy = await copy_uid(value)
			TYPE_OBJECT:
				var value: Variant = node.get(name)
				if value is Resource and is_template_resource(value):
					_debug([path, name, "needs copy"])
					value_copy = await copy_resource(value)

		if value_copy != null:
			node.set(name, value_copy)


func copy_packed_scene(packed_scene: PackedScene, copy_path: String) -> Resource:
	var copied: PackedScene = packed_scene.duplicate(true)
	var scene := copied.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
	var scene_state := copied.get_state()

	for node_idx: int in scene_state.get_node_count():
		var path := scene_state.get_node_path(node_idx)
		var node := scene.get_node(path)

		await maybe_copy_properties(node, path)

	copied.resource_path = copy_path

	var result := copied.pack(scene)
	assert(result == OK, error_string(result))

	result = ResourceSaver.save(copied)
	assert(result == OK, error_string(result))

	return copied


func copy_quest(quest: Quest, copy_path: String) -> Quest:
	var copied := quest.duplicate()
	copied.title = _title
	copied.description = _description

	var first_scene := await copy_uid(quest.first_scene)
	copied.first_scene = first_scene
	copied.resource_path = copy_path
	var result := ResourceSaver.save(copied)
	assert(result == OK, "Failed to save %s to %s" % [copied, copy_path])

	return copied


func copy_sprite_frames(sprite_frames: SpriteFrames, copy_path: String) -> Resource:
	var copied: SpriteFrames = sprite_frames.duplicate()
	for anim: String in copied.get_animation_names():
		for idx: int in range(copied.get_frame_count(anim)):
			var tex := copied.get_frame_texture(anim, idx)
			assert(tex is AtlasTexture, "Expected AtlasTexture, got %s" % tex)
			assert(
				tex.is_built_in(),
				"Expected built-in texture, got %s %s" % [tex, tex.resource_path],
			)
			if is_template_resource(tex.atlas):
				tex.atlas = await copy_resource(tex.atlas) as Texture2D

	copied.resource_path = copy_path
	var result := ResourceSaver.save(copied)
	assert(result == OK, "Failed to save %s to %s" % [copied, copy_path])

	return copied


func copy_as_file(resource: Resource, copy_path: String) -> Resource:
	var result := DirAccess.copy_absolute(resource.resource_path, copy_path)
	assert(
		result == OK,
		"Failed to copy %s to %s: %s" % [resource.resource_path, copy_path, error_string(result)]
	)
	await reimport(copy_path)
	return load(copy_path)


func copy(uid: String, resource: Resource) -> Resource:
	assert(uid.begins_with("uid://"), "'%s' is not a uid" % uid)
	assert(
		resource.resource_path.begins_with(TEMPLATE_PATH),
		"'%s' is not a storyquest resource" % resource
	)

	if uid in orig_uid_to_copy:
		return orig_uid_to_copy[uid]

	var subpath := resource.resource_path.right(-TEMPLATE_PATH.length())
	var subdir := subpath.get_base_dir()
	var filename := subpath.get_file()

	subdir = subdir.replace(TEMPLATE_PREFIX + "_", "")
	filename = filename.replace(TEMPLATE_PREFIX, quest_name)
	var copy_path := target_path.path_join(subdir).path_join(filename)

	_debug(["Copying", uid, resource.resource_path, "to", copy_path])
	_depth += 1

	var result := DirAccess.make_dir_recursive_absolute(copy_path.get_base_dir())
	assert(result == OK, "Failed to make directories for %s" % copy_path)

	var copied: Resource
	if resource is PackedScene:
		copied = await copy_packed_scene(resource, copy_path)
	elif resource is Quest:
		copied = await copy_quest(resource, copy_path)
	elif resource is CompressedTexture2D or resource is DialogueResource:
		copied = await copy_as_file(resource, copy_path)
	elif resource is SpriteFrames:
		copied = await copy_sprite_frames(resource, copy_path)
	else:
		assert(false, "Don't know how to copy %s" % resource)

	_debug(["⇒", uid, "copied as", copied.resource_path])
	_depth -= 1
	assert(uid not in orig_uid_to_copy)
	orig_uid_to_copy[uid] = copied
	return copied


func copy_resource(resource: Resource) -> Resource:
	assert(resource.resource_path, "%s has no path" % resource)
	var uid := ResourceUID.path_to_uid(resource.resource_path)
	assert(uid, "%s has no uid" % resource)
	return await copy(uid, resource)


func copy_uid(uid: String) -> String:
	var copied := await copy(uid, ResourceLoader.load(uid))
	var copied_uid := ResourceUID.path_to_uid(copied.resource_path)
	assert(
		copied_uid.begins_with("uid://"), "%s %s %s" % [copied, copied.resource_path, copied_uid]
	)
	return copied_uid


func create_storyquest() -> void:
	var quest: Quest = load(TEMPLATE_PATH.path_join(QUEST_FILENAME))
	await copy_resource(quest)
	EditorInterface.save_all_scenes()
