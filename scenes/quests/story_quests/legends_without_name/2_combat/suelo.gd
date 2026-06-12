# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

#onready espera a q el nodo este listo antes de buscarlo
@onready var sprite_baldosa= $Sprite2D
@onready var timercaida= $Timer
@onready var timerregen= $Timer2

#vars para que se regenere el suelo
#var regen_timer: Timer
var scale_original: Vector2
var color_ori: Color

#estado de la trampa
var estado= "intacto" #podria ser: "intacto", "cayendo", "hueco"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#baldosas, info para restaurarlas
	scale_original= sprite_baldosa.scale
	color_ori= sprite_baldosa.modulate
	
	#timer de caida
	timercaida.wait_time= 2.0
	timercaida.one_shot= true
	
	#baldosa timer regen
	#regen_timer= Timer.new()
	timerregen.wait_time= 2.5
	timerregen.one_shot= true
	timerregen.timeout.connect(_on_timer_timeout_regen)
	#add_child(regen_timer)
	
	body_entered.connect(_on_body_entered)
	timercaida.timeout.connect(_on_timer_timeout)
	
	  # Replace with function body.

func _on_body_entered(body: Node2D) -> void: 
	if body.is_in_group("player"):
		if estado == "intacto":
			#el jugador pisa por primera vez
			estado= "cayendo"
			#se puede cambiar un poco el color
			sprite_baldosa.modulate= Color(0.8, 0.6, 0.6)
			timercaida.start()
		elif estado == "hueco":
			#el jugador camino hacia un hueco ya abierto
			reiniciar_nivel()
			
func _on_timer_timeout() -> void: 
	#ilusion optica de q la baldosa se cae al fondo
	var tween= create_tween()
	
	#perspectiva cenital, achicar el sprite y hacerlo transparente para simular profundidad
	tween.tween_property(sprite_baldosa, "scale", Vector2(0.2, 0.2), 0.3).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite_baldosa, "modulate:a", 0.0, 0.3)
	
	#cuando termine la animacio de caida confirmamos el hueco
	tween.tween_callback(convertir_en_hueco)

func convertir_en_hueco() ->void: 
	estado= "hueco"
	#$CollisionShape2D.set_deferred("disabled", true)
	timerregen.start()
	#se revisa si el player se quedo parado esperando a q cayera, 
	#get_overlapping_bodies() devuelve todo lo q este dentro del area2d en ese instante
	for cuerpo in get_overlapping_bodies(): 
		if cuerpo.is_in_group("player"): 
			reiniciar_nivel()
			
func _on_timer_timeout_regen() -> void:
#	$CollisionShape2D.set_deferred("disabled", false)
	estado= "intacto"
	var tween= create_tween()
	tween.tween_property(sprite_baldosa, "scale", scale_original, 0.4).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(sprite_baldosa, "modulate", color_ori, 0.4)

func reiniciar_nivel() -> void:
	#reinicia la escena completa
	get_tree().call_deferred("reload_current_scene")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
