extends Node

## Prefix to strip from scene path when setting URL hash
const _SCENE_PREFIX = "res://scenes/"

## Suffix to strip from scene path when setting URL hash
const _SCENE_SUFFIX = ".tscn"

## Proxy object for the 'window' DOM object, or null if not running on the web
var _window: JavaScriptObject

## Matches the expected absolute path for a scene, with a capture group
## representing a more human-readable substring.
var _scene_rx := RegEx.create_from_string(
	"^" + _SCENE_PREFIX + "(?<scene>.+)\\" + _SCENE_SUFFIX + "$"
)


func _ready() -> void:
	if OS.has_feature("web"):
		_window = JavaScriptBridge.get_interface("window")
		_restore_from_hash.call_deferred()


## On the web, load the world indicated by the URL hash, if any.
func _restore_from_hash() -> void:
	var url_hash: String = _window.location.hash as String
	if url_hash:
		var path: String = url_hash.right(-1).uri_decode()

		if path.is_relative_path():
			path = _SCENE_PREFIX + path

			if not path.ends_with(_SCENE_SUFFIX):
				path += _SCENE_SUFFIX
		# otherwise, this is an absolute uid:// or res:// path

		if ResourceLoader.exists(path, "PackedScene"):
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
		_window.location.replace(url.href)


func change_to_file_with_transition(scene_path: String, spawn_point: NodePath = ^""):
	# We should probably pause the game during transitions. But pause is
	# not trivial, so I suggest first tackling it in another issue, then we can
	# add it here.

	await Transitions.leave_scene(Transition.Effect.RIGHT_TO_LEFT_WIPE)
	change_to_file(scene_path, spawn_point)
	await Transitions.introduce_scene(Transition.Effect.LEFT_TO_RIGHT_WIPE)


func change_to_file(scene_path: String, spawn_point: NodePath = ^"") -> void:
	var scene: PackedScene = load(scene_path)
	if scene:
		change_to_packed(scene, spawn_point)


func change_to_packed(scene: PackedScene, spawn_point: NodePath = ^"") -> void:
	if get_tree().change_scene_to_packed(scene) == OK:
		_set_hash(scene.resource_path)
		if spawn_point != ^"":
			GameState.current_spawn_point = spawn_point
