@tool
class_name CustomInventoryItem
extends InventoryItem


@export var custom_world_texture: Texture2D
@export var custom_texture: Texture2D  # Para el HUD
@export var target_hud: String = "HUD"  # "MainHUD" o "SecondaryHUD"

func get_world_texture() -> Texture2D:
	return custom_world_texture if custom_world_texture else super.get_world_texture()

func texture() -> Texture2D:
	return custom_texture if custom_texture else super.texture()
