# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Node2D

@export var recurso_dialogo : DialogueResource

@onready var barra_emergencia : Range = $UI/BarraEmergencia
@onready var contenedor_arcos : Node2D = $ContenedorArcos
@onready var visual_nucleo : ColorRect = $VisualNucleo
@onready var panel_final : Control = $UI/PanelFinal
@onready var label_mensaje : Label = $UI/PanelFinal/LabelMensaje

var vida_nucleo : float = 100.0
var juego_activo : bool = false 

func _ready() -> void:
	inicializar_juego()
	# Congelamos los meteoritos hasta que termine la intro
	if contenedor_arcos:
		contenedor_arcos.process_mode = PROCESS_MODE_DISABLED
	
	disparar_dialogo("start")

func inicializar_juego() -> void:
	vida_nucleo = 100.0
	panel_final.visible = false
	barra_emergencia.value = vida_nucleo
	
	# Conectamos las señales de forma segura
	for arco in contenedor_arcos.get_children():
		if not arco.is_connected("arco_golpeado", _on_meteorito_defendido):
			arco.connect("arco_golpeado", _on_meteorito_defendido)
		if not arco.is_connected("toco_suelo", _on_meteorito_impacto_nucleo):
			arco.connect("toco_suelo", _on_meteorito_impacto_nucleo)

func disparar_dialogo(titulo: String) -> void:
	# DialogueManager usará el pergamino definido en Configuración del Proyecto
	DialogueManager.show_dialogue_balloon(recurso_dialogo, titulo)
	DialogueManager.dialogue_ended.connect(_on_dialogo_terminado.bind(titulo), CONNECT_ONE_SHOT)

func _on_dialogo_terminado(_res: Resource, titulo: String) -> void:
	if titulo == "start":
		juego_activo = true
		contenedor_arcos.process_mode = PROCESS_MODE_INHERIT
	elif titulo == "well_done":
		# Aquí termina el juego con victoria
		print("Victoria finalizada, regresando al mapa...")
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/3_patitas/3_sequence_puzzle/3_patitas_sequence_puzzle.tscn")

func _on_meteorito_defendido() -> void:
	if not juego_activo: return
	verificar_victoria()

func _on_meteorito_impacto_nucleo() -> void:
	if not juego_activo: return
	
	vida_nucleo -= 20.0
	barra_emergencia.value = vida_nucleo
	
	# --- SOLUCIÓN DEL CRASHEO (BLINDAJE COGNITIVO) ---
	# Conseguimos el estilo de forma segura
	var estilo_original = barra_emergencia.get_theme_stylebox("fill")
	
	# Si el estilo original existe y es válido, hacemos el parpadeo rojo
	if estilo_original != null:
		var estilo_fill = estilo_original.duplicate()
		if "bg_color" in estilo_fill:
			estilo_fill.bg_color = Color.RED
			barra_emergencia.add_theme_stylebox_override("fill", estilo_fill)
			
			await get_tree().create_timer(0.2).timeout
			
			# Regresamos de forma segura al estilo original en vez de pasar un 'null' peligroso
			barra_emergencia.add_theme_stylebox_override("fill", estilo_original)
	else:
		# Si no hay estilo en el inspector, solo esperamos un instante sin tocar la UI
		await get_tree().create_timer(0.2).timeout
	# -------------------------------------------------
	
	if vida_nucleo <= 0:
		ejecutar_derrota()
	else:
		verificar_victoria()

func verificar_victoria() -> void:
	# El juego gana si NO quedan nodos en el contenedor
	if contenedor_arcos.get_child_count() <= 1 and vida_nucleo > 0: # <= 1 porque el que golpeaste sigue un instante ahí
		juego_activo = false
		contenedor_arcos.process_mode = PROCESS_MODE_DISABLED
		# Ocultamos la UI para que el pergamino sea el protagonista
		$UI.visible = false
		disparar_dialogo("well_done")

func ejecutar_derrota() -> void:
	juego_activo = false
	label_mensaje.text = "MISIÓN FALLIDA"
	panel_final.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
