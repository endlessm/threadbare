extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_node: String = "start"
var player_is_near: bool = false
var player: Node2D = null
var is_dialogue_running: bool = false

func _ready() -> void:
	if dialogue_resource == null:
		print_rich("[color=red]ERROR: El NPC (%s) no tiene un 'Dialogue Resource' asignado.[/color]" % self.name)
		return

	if Engine.has_singleton("DialogueManager"):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
	else:
		print("ERROR: El Autoload 'DialogueManager' no se encontró.")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Jugador":
		player_is_near = true
		player = body 
		print("¡Jugador detectado!")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Jugador":
		player_is_near = false
		player = null 
		print("¡Jugador se fue!")

func _process(_delta: float) -> void:
	if player_is_near and Input.is_action_just_pressed("speak"):
		if not is_dialogue_running:
			start_npc_dialogue()

func start_npc_dialogue() -> void:
	print("Iniciando diálogo...")
	is_dialogue_running = true
	if player:
		player.set_physics_process(false) 
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_node)

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	print("El NPC fue notificado: el diálogo terminó.")
	is_dialogue_running = false
	if player:
		player.set_physics_process(true)
