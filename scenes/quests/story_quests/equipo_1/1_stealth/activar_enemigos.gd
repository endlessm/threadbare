# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
var enemigos:Array =[]
@onready var vidas = 3
@onready var can_take_damage = true;
@onready var viento=%VientoScript
signal derrota;

func _ready() -> void:
	enemigos = get_children() # Replace with function body.

func _activar_enemigos()->void:
	viento._set_estado_viento(500,3)##fuerza de 500 hacia atras y se activa cada 3 segundos
	for e in enemigos:
		e.visible= true
		e.start();

func _desactivar_enemigos()->void:
	can_take_damage = false
	for e in enemigos:
		e.remove();

func _reducir_vida_jugador(body:Node2D)->void:
	if(!can_take_damage):
		return
	body = body as Projectile   
	if not body:
		return
	vidas=vidas-1;
	if(vidas <1):
		derrota.emit()	
				
