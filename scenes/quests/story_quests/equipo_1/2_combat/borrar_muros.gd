extends Node

@onready var muros = %Muros;
@onready var dialogo = %Dialogo;

@export var dialogue_title = "start";

@export var dialogue_correct: DialogueResource:
	set(new_value):
		dialogue_correct= new_value
		notify_property_list_changed()
		
@export var dialogue_incorrect: DialogueResource:
	set(new_value):
		dialogue_incorrect= new_value
		notify_property_list_changed()

var guardian_correcto =1;
func _ready() -> void:
	var hijos = get_children()
	for h in hijos:
		h.borrar_muro.connect(eliminar_muro)
		h.reloj.collected.connect(item_recolectado)
		
func eliminar_muro(coords:Array[Vector2i]):
	for c in coords:
		muros.set_cell(c,-1)

func item_recolectado(item:CollectibleItem):
	var guardian = item.get_parent();
	var correcto= guardian.codigo==guardian_correcto
	item.get_parent().area_interactuable.can_use=true;
	await DialogueManager.dialogue_ended
	eliminar_muro(guardian.posiciones_item_muro)
	if !correcto:
		guardian._activar_enemigos()		
	dialogo.puede_avanzar=true
	
