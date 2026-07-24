extends Node
@export var posiciones_muro: Array[Vector2i] =[]
@export var posiciones_item_muro: Array[Vector2i] =[]
@export var codigo:int =0;
@onready var guard_area =$NPC/GuardArea;
@onready var guard = $NPC;
@onready var reloj=$Reloj;
@onready var area_interactuable=$AreaBorrarMuro
var enemigos:Array =[];
var patron_muro;
signal borrar_muro;
@export var guard_name:String ="prueba";


@export_category("Dialogue")
@export var dialogue_title = "start";
@export var dialogue_guard: DialogueResource:
	set(new_value):
		dialogue_guard = new_value
		notify_property_list_changed()

func _ready() -> void:
	guard_area.interaction_started.connect(_on_player_interaction);
	patron_muro = %Muros.get_pattern(posiciones_muro)
	area_interactuable.event.connect(_reaparecer_muro)
	
	if codigo==0:
		for e in $NPCEnemigos.get_children():
			if(e.is_in_group("enemigos")):
				enemigos.append(e)

func _on_player_interaction(player: Player, from_right: bool)->void:
	%Dialogo.guardian_nombre = guard_name;
	
	if !%Dialogo.puede_avanzar:
		DialogueManager.show_dialogue_balloon(%Dialogo.dialogue_no_pass, dialogue_title, [self, player,%Dialogo])
		await DialogueManager.dialogue_ended
		guard_area.end_interaction()
		return;
		
	if dialogue_guard:
		DialogueManager.show_dialogue_balloon(dialogue_guard, dialogue_title, [self, player,%Dialogo])
		await DialogueManager.dialogue_ended
	guard_area.end_interaction()		
	if(%Dialogo.decision):
		borrar_muro.emit(posiciones_muro)
		guard.hide()
		guard.collision_layer = 0
		guard.collision_mask = 0
		guard_area.set_deferred("monitoring", false)
		guard_area.set_deferred("monitorable", false)	
		%Dialogo.puede_avanzar=false

func _player_enter_area():
	_reaparecer_muro()
		
func _reaparecer_muro():
	%Muros.set_pattern(posiciones_muro[0],patron_muro)	
	
func _activar_enemigos():
	for e in enemigos:
		e.visible=true;
		e.process_mode = Node.PROCESS_MODE_INHERIT		
