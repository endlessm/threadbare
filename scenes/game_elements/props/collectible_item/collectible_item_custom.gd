extends CollectibleItem

signal collected;
func _ready() -> void:
	super._ready();
	
func _on_interacted(player: Player, _from_right: bool) -> void:
	collected.emit();
	super(player,_from_right)	
	
	
