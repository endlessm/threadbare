# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

## Prefixes to try adding to non-absolute path in URL hash, which may have been stripped to make it
## more human-readable.
const _SCENE_PREFIXES = [
	"res://",
	"res://scenes/",
]

## Suffix stripped from path to make it more human-readable
const _SCENE_SUFFIX = ".tscn"

## Proxy object for the 'window' DOM object, or null if not running on the web
var _window: JavaScriptObject

## Proxy object for the [method _on_hash_changed] callback, or null if not running on the web
var _on_hash_changed_ref: JavaScriptObject

## The last URL that was set by [method _set_hash], if running on the web.
## If we observe the URL changing to something different, the user has edited the URL manually.
var _current_url: String

## Matches the expected absolute path for a scene, with a capture group
## representing a more human-readable substring.
var _scene_rx := RegEx.create_from_string(
	"^" + _SCENE_PREFIXES[-1] + "(?<scene>.+)\\" + _SCENE_SUFFIX + "$"
)


func _ready() -> void:
	if OS.has_feature("web"):
		_window = JavaScriptBridge.get_interface("window")
		_restore_from_hash.call_deferred()
		_on_hash_changed_ref = JavaScriptBridge.create_callback(_on_hash_changed)
		_window.onhashchange = _on_hash_changed_ref


## On the web, load the world indicated by the URL hash, if any.
func _restore_from_hash() -> void:
	var url_hash: String = _window.location.hash as String
	if url_hash:
		var path: String = url_hash.right(-1).uri_decode()

		if path.is_relative_path():
			if not path.ends_with(_SCENE_SUFFIX):
				path += _SCENE_SUFFIX

			for prefix: String in _SCENE_PREFIXES:
				if ResourceLoader.exists(prefix + path, "PackedScene"):
					path = prefix + path
					break
		# otherwise, this is an absolute uid:// or res:// path

		if ResourceLoader.exists(path, "PackedScene"):
			if GameState.can_restore() and GameState.get_scene_to_restore() == path:
				# Continue if the path matches the saved scene. This would happen
				# if the player reloads the page while playing.
				GameState.restore()
			else:
				# Otherwise, treat it as the player is debugging a scene from the web.
				# In that case, do not persist progress and clear the game state.
				# This is the same behavior as if the scene is ran from the editor
				# for testing or debugging.
				GameState.persist_progress = false
				GameState.clear()

			# In theory, we might like to avoid switching scene if the specified
			# scene is the default scene. In practice, that will not happen, and
			# if it does, it's harmless enough.
			change_to_file(path)
		else:
			print("Path ", path, " from URL hash ", url_hash, " is not a scene; ignoring")


## On the web, update or clear the URL hash to indicate the current world.
func _set_hash(resource_path: String) -> void:
	if _window:
		var rx_match: RegExMatch = _scene_rx.search(resource_path)
		var url_hash: String = rx_match.get_string("scene") if rx_match else resource_path

		var url: JavaScriptObject = JavaScriptBridge.create_object("URL", _window.location.href)
		url.hash = "#" + url_hash
		# Replace the current URL rather than simply updating window.location to
		# avoid creating misleading history entries that don't work if you press
		# the browser's back button.
		_current_url = url.href
		_window.location.replace(url.href)


func _on_hash_changed(args: Array) -> void:
	var event := args[0] as JavaScriptObject
	var new_url := event.newURL as String
	if new_url != _current_url:
		_restore_from_hash()


func change_to_file_with_transition(
	scene_path: String,
	spawn_point: NodePath = ^"",
	enter_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE,
	exit_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
) -> void:
	var err := ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		push_error("Failed to start loading %s: %s" % [scene_path, error_string(err)])
		return

	Transitions.do_transition(
		func() -> void: change_to_packed(ResourceLoader.load_threaded_get(scene_path), spawn_point),
		enter_transition,
		exit_transition
	)


func change_to_packed_with_transition(
	scene: PackedScene,
	spawn_point: NodePath = ^"",
	enter_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE,
	exit_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
) -> void:
	Transitions.do_transition(
		change_to_packed.bind(scene, spawn_point), enter_transition, exit_transition
	)


func reload_with_transition(
	enter_transition: Transition.Effect = Transition.Effect.RIGHT_TO_LEFT_WIPE,
	exit_transition: Transition.Effect = Transition.Effect.LEFT_TO_RIGHT_WIPE
) -> void:
	Transitions.do_transition(get_tree().reload_current_scene, enter_transition, exit_transition)


func change_to_file(scene_path: String, spawn_point: NodePath = ^"") -> void:
	var scene: PackedScene = load(scene_path)
	if scene:
		change_to_packed(scene, spawn_point)


func change_to_packed(scene: PackedScene, spawn_point: NodePath = ^"") -> void:
	if get_tree().change_scene_to_packed(scene) == OK:
		_set_hash(scene.resource_path)
		GameState.set_scene(scene.resource_path, spawn_point)
