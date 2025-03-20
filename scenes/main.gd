extends Node2D
@onready var camera_2d: Camera2D = %Camera2D
@onready var deform_floor_effect: ColorRect = %DeformFloorEffect
@onready var player_point_light_2d: PointLight2D = %PlayerPointLight2D
@onready var talker_point_light_2d: PointLight2D = %TalkerPointLight2D
@onready var canvas_modulate: CanvasModulate = %CanvasModulate
@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var lights_button: CheckButton = $CanvasLayer/MarginContainer/VBoxContainer/LightsButton
@onready var deform_button: CheckButton = $CanvasLayer/MarginContainer/VBoxContainer/DeformButton
@onready var frayed_button: CheckButton = $CanvasLayer/MarginContainer/VBoxContainer/FrayedButton

const TILESET: TileSet = preload("res://scenes/tileset.tres")
const TEXTURE_A: Texture2D = preload("res://assets/tiny-swords/Terrain/Ground/Tilemap_Flat.png")
const TEXTURE_B: Texture2D = preload("res://assets/tileset-textures/Tilemap_Flat-04.png")

var lights_enabled: bool
var deform_floor_enabled: bool
var frayed_enabled: bool

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	event = event as InputEventMouseButton
	if not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera_2d.zoom /= 2 
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera_2d.zoom *= 2
	update_deform_floor_effect()

func _ready() -> void:
	lights_enabled = lights_button.button_pressed
	deform_floor_enabled = deform_button.button_pressed
	frayed_enabled = frayed_button.button_pressed
	lights_button.toggled.connect(on_lights_button_toggled)
	deform_button.toggled.connect(on_deform_button_toggled)
	frayed_button.toggled.connect(on_frayed_button_toggled)
	update_lights_effect()
	update_deform_floor_effect()
	update_tileset_texture()

func on_lights_button_toggled(toggled: bool) -> void:
	lights_enabled = toggled
	update_lights_effect()

func on_deform_button_toggled(toggled: bool) -> void:
	deform_floor_enabled = toggled
	update_deform_floor_effect()

func on_frayed_button_toggled(toggled: bool) -> void:
	frayed_enabled = toggled
	update_tileset_texture()

func update_deform_floor_effect() -> void:
	deform_floor_effect.material.set_shader_parameter(&"zoom", camera_2d.zoom.x)
	deform_floor_effect.material.set_shader_parameter(&"enabled", deform_floor_enabled)
	deform_floor_effect.visible = deform_floor_enabled

func update_lights_effect() -> void:
	for node in [player_point_light_2d, talker_point_light_2d, canvas_modulate]:
		node.visible = lights_enabled
	world_environment.environment.adjustment_enabled = lights_enabled
 
func update_tileset_texture() -> void:
	var tileset_source: TileSetAtlasSource = TILESET.get_source(1)
	tileset_source.texture.diffuse_texture = TEXTURE_B if frayed_enabled else TEXTURE_A
