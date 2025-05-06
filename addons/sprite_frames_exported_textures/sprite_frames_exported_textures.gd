@tool
extends EditorPlugin

const SpriteFramesInspectorPlugin = preload(
	"res://addons/sprite_frames_exported_textures/sprite_frames_inspector_plugin.gd"
)

var sprite_frames_inspector_plugin: EditorInspectorPlugin


func _enter_tree() -> void:
	sprite_frames_inspector_plugin = SpriteFramesInspectorPlugin.new()
	add_inspector_plugin(sprite_frames_inspector_plugin)


func _exit_tree() -> void:
	if sprite_frames_inspector_plugin:
		remove_inspector_plugin(sprite_frames_inspector_plugin)
		sprite_frames_inspector_plugin = null
