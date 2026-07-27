# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Object

const DEBUG := true


## Return a list of all scenes in the project that match the filter.
## filter accepts one argument, the path to a scene, and returns a boolean,
## true if the scene matches the filter.
static func find_scenes(
	root_folder: String = "res://",
	filter: Callable = func(_scene_path: String) -> bool: return true,
) -> Array[PackedScene]:
	var packed_scenes: Array[PackedScene] = []
	var err: Error

	var dirs: Array[String] = [root_folder]
	while not dirs.is_empty():
		var current_dir: String = dirs.pop_back()
		var dir := DirAccess.open(current_dir)
		if not dir:
			err = DirAccess.get_open_error()
			push_error("Failed to open", dir, ":", error_string(err))
			continue

		err = dir.list_dir_begin()
		if err != OK:
			push_error("Failed to list directory", dir, ":", error_string(err))
			continue

		var file_name := dir.get_next()
		while file_name != "":
			var path := current_dir.path_join(file_name)
			if dir.current_is_dir():
				dirs.push_back(path)
			elif file_name.ends_with(".tscn"):
				# The filter accepts a path rather than a PackedScene because
				# load()ing a PackedScene is expensive. Benchmarking crudely on
				# one laptop: with a filter that rejects all scenes, the loop
				# takes 60ms if the load() is after the filter call, but 4000 ms
				# if load() is before. During that time the editor UI is frozen.
				if filter.call(path):
					var scene := load(path) as PackedScene
					if scene:
						packed_scenes.push_back(scene)
			file_name = dir.get_next()
		dir.list_dir_end()

	return packed_scenes
