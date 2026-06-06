extends Node

var items_count: int
var items_collected: int

func _ready():
	items_count = get_child_count(false)
	items_collected = 0;
	
func are_all_collected()->bool:
	return items_collected==items_count;
	
func item_collected()->void:
	items_collected+=1;
	
	
