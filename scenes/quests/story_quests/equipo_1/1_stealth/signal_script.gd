extends Node2D
@onready var mapa = $TileMapLayers;
@onready var items = $Collectables;

@onready var final_area = $%FinalArea

@onready var viento_script =$%VientoScript
@onready var mensaje_pre_final = $%Mensaje
@export_file("*.tscn") var next_scene: String

@export_category("Dialogue")
@export var dialogue_title = "start";

@export var final_dialogue: DialogueResource:
	set(new_value):
		final_dialogue = new_value
		notify_property_list_changed()

		
func _ready() -> void:
	##conectamos la señal para borrar las piedras
	items.open_path.connect(mapa.delete_stones)
	
	##conectamos la señal del area interactuable con nuestra funcion
	##para mostrar el dialogo final
	final_area.interaction_started.connect(_on_player_interaction);
	
	##conectamos la señal de inicio y fin de mensaje e items
	##para que la mecanica no se active durante un dialogo
	items.dialogue_start.connect(_disable_wind)
	items.dialogue_finished.connect(_enable_wind)
	
	mensaje_pre_final.dialogue_start.connect(_disable_wind)
	mensaje_pre_final.dialogue_finished.connect(_enable_wind)

func _on_player_interaction(player: Player, from_right: bool)->void:
	if final_dialogue:
		DialogueManager.show_dialogue_balloon(final_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended
	final_area.end_interaction()
	queue_free()

	if next_scene:
		GameState.set_challenge_start_scene(next_scene)
		SceneSwitcher.change_to_file_with_transition(next_scene)	

func _disable_wind()->void:
	viento_script.empezar = false;
	viento_script._reset_all_attributes();
func _enable_wind()->void:
	viento_script.empezar = true;	
	
