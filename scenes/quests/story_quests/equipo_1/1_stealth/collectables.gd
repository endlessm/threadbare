extends Node

var items_count: int
var items_collected: int
signal open_path
signal dialogue_start
signal dialogue_finished
func _ready():
	items_count = get_child_count(false)
	items_collected = 0;
	for item in get_children(false):
		item.collected.connect(item_collected)
	
func item_collected(item:CollectibleItem)->void:
	dialogue_start.emit()
	items_collected+=1;
	if items_collected==items_count:
		open_path.emit();
	await DialogueManager.dialogue_ended
	dialogue_finished.emit()
