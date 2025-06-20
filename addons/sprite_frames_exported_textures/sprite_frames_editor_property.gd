# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends EditorProperty

const SpriteFramesHelper = preload(
	"res://addons/sprite_frames_exported_textures/sprite_frames_helper.gd"
)

var texture: Texture2D:
	set(new_value):
		texture = new_value
		if texture_preview:
			texture_preview.texture = texture
		if texture_picker:
			texture_picker.edited_resource = texture
		label = texture.resource_path.get_file()
var sprite_frames: SpriteFrames
var texture_picker: EditorResourcePicker
var texture_preview: TextureRect
var editor_undo_redo_manager: EditorUndoRedoManager


func _init(the_texture: Texture2D, the_sprite_frames: SpriteFrames) -> void:
	texture = the_texture

	sprite_frames = the_sprite_frames

	texture_picker = EditorResourcePicker.new()
	texture_picker.edited_resource = texture
	texture_picker.base_type = "Texture2D"

	texture_preview = TextureRect.new()
	texture_preview.texture = texture
	texture_preview.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	texture_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_preview.visible = false

	editor_undo_redo_manager = EditorPlugin.new().get_undo_redo()

	add_child(texture_picker)
	add_child(texture_preview)

	texture_picker.resource_changed.connect(self.on_resource_changed)


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	get_viewport().gui_focus_changed.connect(self.on_gui_focus_changed)
	label = texture.resource_path.get_file()


func on_gui_focus_changed(new_focus_owner: Node):
	if self.is_ancestor_of(new_focus_owner) or self == new_focus_owner:
		select()
		texture_preview.visible = true
		set_bottom_editor(texture_preview)
	else:
		texture_preview.visible = false
		set_bottom_editor(null)


func on_resource_changed(new_texture: Texture2D) -> void:
	select()

	if texture == new_texture:
		return

	if not new_texture:
		_push_error_toast(
			(
				"Texture %s cannot be cleared from the inspector because that would break the animations."
				% texture.resource_path.get_file()
			)
		)
		texture_picker.edited_resource = texture
		return

	if new_texture and texture.get_size() != new_texture.get_size():
		_push_error_toast(
			(
				"New texture's size (%dx%d) doesn't match old texture's size (%dx%d)"
				% [
					new_texture.get_width(),
					new_texture.get_height(),
					texture.get_width(),
					texture.get_height(),
				]
			)
		)
		texture_picker.edited_resource = texture
		return

	if new_texture in SpriteFramesHelper.base_textures_used(sprite_frames):
		_push_error_toast(
			(
				"Texture %s was already being used in the SpriteFrames"
				% new_texture.resource_path.get_file()
			)
		)
		texture_picker.edited_resource = texture
		return

	editor_undo_redo_manager.create_action(
		"Replace texture", UndoRedo.MergeMode.MERGE_DISABLE, sprite_frames
	)
	editor_undo_redo_manager.add_do_method(
		self, "replace_texture", texture, new_texture, sprite_frames
	)
	editor_undo_redo_manager.add_do_property(self, "texture", new_texture)
	editor_undo_redo_manager.add_undo_method(
		self, "replace_texture", new_texture, texture, sprite_frames
	)
	editor_undo_redo_manager.add_undo_property(self, "texture", texture)
	editor_undo_redo_manager.commit_action()


func replace_texture(texture, new_texture, sprite_frames) -> void:
	SpriteFramesHelper.replace_texture(texture, new_texture, sprite_frames)
	_push_notificiation_toast(
		(
			"Texture %s successfully changed for %s"
			% [texture.resource_path.get_file(), new_texture.resource_path.get_file()]
		)
	)
	refresh_sprite_frames_editor()


## This is a bit of a hack that forces to redraw the SpriteFramesEditor, so the
## changes can in the animation can be seen immediately.
func refresh_sprite_frames_editor() -> void:
	var sprite_frames_editor = (
		EditorInterface
		. get_base_control()
		. find_children("", "SpriteFramesEditor", true, false)
		. front()
	)
	if not sprite_frames_editor:
		return

	var animations_tree: Tree = sprite_frames_editor.find_children("", "Tree", true, false).front()
	if not animations_tree:
		return

	var tree_item: TreeItem = animations_tree.get_selected()
	if not tree_item:
		return

	tree_item.select(0)


func _push_error_toast(message: String) -> void:
	EditorInterface.get_editor_toaster().push_toast(message, EditorToaster.SEVERITY_ERROR)


func _push_notificiation_toast(message: String) -> void:
	EditorInterface.get_editor_toaster().push_toast(message, EditorToaster.SEVERITY_INFO)
