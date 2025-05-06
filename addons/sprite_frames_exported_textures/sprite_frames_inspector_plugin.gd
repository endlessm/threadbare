extends EditorInspectorPlugin

const SpriteFramesEditorProperty = preload(
	"res://addons/sprite_frames_exported_textures/sprite_frames_editor_property.gd"
)
const SpriteFramesHelper = preload(
	"res://addons/sprite_frames_exported_textures/sprite_frames_helper.gd"
)


func _can_handle(object: Object) -> bool:
	return object is SpriteFrames


func _parse_begin(object: Object) -> void:
	if object is SpriteFrames:
		var sprite_frames: SpriteFrames = object
		for base_texture: Texture2D in SpriteFramesHelper.base_textures_used(sprite_frames):
			var sprite_frames_editor_property = SpriteFramesEditorProperty.new(
				base_texture, sprite_frames
			)
			add_property_editor(base_texture.resource_path, sprite_frames_editor_property, true)
