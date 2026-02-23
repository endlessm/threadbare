extends Node
## Global script to sync current scene with URL hash on web platform
##
## On the web platform, this script allows loading a specific scene by placing its filename in the
## URL hash; and updates the URL hash when the scene changes.

# Prefixes to try adding to non-absolute path in URL hash, which may have been stripped to make it
# more human-readable.
const _SCENE_PREFIXES = [
	"res://",
]

# Suffix stripped from path to make it more human-readable
const _SCENE_SUFFIX = ".tscn"

# Proxy object for the 'window' DOM object, or null if not running on the web
var _window: JavaScriptObject

# Proxy object for the [method _on_hash_changed] callback, or null if not running on the web
var _on_hash_changed_ref: JavaScriptObject

# The last URL that was set by [method _set_hash], if running on the web.
# If we observe the URL changing to something different, the user has edited the URL manually.
var _current_url: String

# Matches the expected absolute path for a scene, with a capture group
# representing a more human-readable substring.
var _scene_rx := RegEx.create_from_string(
	"^" + _SCENE_PREFIXES[-1] + "(?<scene>.+)\\" + _SCENE_SUFFIX + "$"
)

# The main scene of the game. The URL hash will be cleared if this is the current scene.
@onready var _main_scene: String = ProjectSettings.get("application/run/main_scene")


func _ready() -> void:
	if OS.has_feature("web"):
		_window = JavaScriptBridge.get_interface("window")
		# Load any scene specified in the URL hash
		_restore_from_hash.call_deferred()

		# Monitor the URL hash for changes
		_on_hash_changed_ref = JavaScriptBridge.create_callback(_on_hash_changed)
		_window.onhashchange = _on_hash_changed_ref

		# Monitor for the current scene changing. There is no built-in way to switch scenes but this
		# may change when the game is modded!
		get_tree().scene_changed.connect(_on_scene_changed)


# On the web, load the world indicated by the URL hash, if any.
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
			get_tree().change_scene_to_file(path)
		else:
			prints("Path", path, "from URL hash", url_hash, "is not a scene; ignoring")


# On the web, update or clear the URL hash to indicate the current scene.
func _set_hash(resource_path: String) -> void:
	if _window:
		var rx_match: RegExMatch = _scene_rx.search(resource_path)
		var url_hash: String

		if resource_path == _main_scene:
			url_hash = ""
		elif rx_match:
			url_hash = rx_match.get_string("scene")
		else:
			url_hash = resource_path

		var url: JavaScriptObject = JavaScriptBridge.create_object("URL", _window.location.href)
		url.hash = "#" + url_hash
		# Replace the current URL rather than simply updating window.location to
		# avoid creating misleading history entries that don't work if you press
		# the browser's back button.
		_current_url = url.href
		_window.location.replace(url.href)


# When the browser tells us the hash has changed, potentially switch scene.
func _on_hash_changed(args: Array) -> void:
	var event := args[0] as JavaScriptObject
	var new_url := event.newURL as String
	if new_url != _current_url:
		_restore_from_hash()


# When Godot tells us the current scene has changed, update the URL hash.
func _on_scene_changed() -> void:
	_set_hash(get_tree().current_scene.scene_file_path)
