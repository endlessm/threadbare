extends Node
@onready var decision:bool = true;

@onready var puede_avanzar = true;

@onready var guardian_nombre:String="guardian prueba";
@export_category("Dialogue")
@export var dialogue_title = "start";
@export var dialogue_no_pass: DialogueResource:
	set(new_value):
		dialogue_no_pass = new_value
		notify_property_list_changed()
