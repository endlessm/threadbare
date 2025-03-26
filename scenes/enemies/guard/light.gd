@tool
extends PointLight2D

@warning_ignore("unused_private_class_variable")
@export_tool_button("Generate sibling collision shape")
var _generate_collision_shape := generate_collision_shape
@export var debug_view: bool = false:
	set = set_debug_view

var debug_sprite_2d: Sprite2D


func _ready() -> void:
	toggle_debug_sprite_2d(debug_view)


func set_debug_view(new_value: bool) -> void:
	debug_view = new_value
	if is_inside_tree():
		toggle_debug_sprite_2d(debug_view)


func toggle_debug_sprite_2d(should_show: bool) -> void:
	if not Engine.is_editor_hint():
		return
	if should_show:
		if not debug_sprite_2d:
			debug_sprite_2d = Sprite2D.new()
			add_child(debug_sprite_2d)
	else:
		if debug_sprite_2d:
			debug_sprite_2d.queue_free()


func generate_collision_shape() -> void:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image(), 0.6)
	bitmap.resize(Vector2(bitmap.get_size()) * scale * texture_scale)
	var polygons := bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), bitmap.get_size()))
	for polygon: PackedVector2Array in polygons:
		var collider := CollisionPolygon2D.new()
		collider.polygon = polygon
		get_parent().add_child(collider, true)
		collider.owner = owner


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if debug_sprite_2d:
		debug_sprite_2d.texture = texture
		debug_sprite_2d.offset = offset
