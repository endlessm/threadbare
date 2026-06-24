extends CollectibleItem

signal collected;

@export var es_textura_custom:bool = false
@export var textura_custom:Texture2D
func _ready() -> void:
	super._ready();
	
func _on_interacted(player: Player, _from_right: bool) -> void:
	collected.emit(self);
	super(player,_from_right)	
	

func _set_item(new_value: InventoryItem) -> void:
	item = new_value

	if sprite_2d:
		if not es_textura_custom:
			sprite_2d.texture = item.get_world_texture() if item else null
		else:
			sprite_2d.texture = textura_custom
	
	if interact_area:
		interact_area.action = "Collect " + item.type_name() if item else "Collect"

	update_configuration_warnings()
