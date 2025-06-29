extends Node2D
class_name cinematica
signal cinematica_terminada

## Diálogo inicial (no cambiar)
@export var dialogue: DialogueResource = preload("uid://b7ad8nar1hmfs")
## Diálogos adicionales
@export var tiempo_dialogue: DialogueResource
@export var perder_dialogue: DialogueResource
@export var ganar_dialogue: DialogueResource
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
var primera_vez := true
var perdidas: int = 0
var ha_ganado: bool = false

func _ready() -> void:
	# Solo muestra el primer diálogo una vez
	await DialogueManager.show_dialogue_balloon(dialogue, "", [self])
	await DialogueManager.dialogue_ended
	cinematica_terminada.emit()

func mostrar_dialogo_por_evento() -> void:
	if ha_ganado:
		await DialogueManager.show_dialogue_balloon(ganar_dialogue, "", [self])
	elif perdidas == 1:
		await DialogueManager.show_dialogue_balloon(tiempo_dialogue, "", [self])
	else:
		await DialogueManager.show_dialogue_balloon(perder_dialogue, "", [self])
	await DialogueManager.dialogue_ended
	cinematica_terminada.emit()


func notificar_perdida() -> void:
	perdidas += 1
	mostrar_dialogo_por_evento()


func notificar_ganador() -> void:
	ha_ganado = true
	mostrar_dialogo_por_evento()
	_on_cambio_de_escena()

func _on_cambio_de_escena() -> void:
	if next_scene:
		SceneSwitcher.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
