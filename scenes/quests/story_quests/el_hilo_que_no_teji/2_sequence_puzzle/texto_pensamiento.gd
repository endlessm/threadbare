# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

@onready var label: Label = $Label
@onready var timer: Timer = $Label/Timer

var animacion_actual: Tween
var jugador_objetivo: Node2D
var offset_flotante: Vector2 = Vector2.ZERO
var distancia_cabeza: float = 65.0 

func _ready() -> void:
	hide()
	jugador_objetivo = get_tree().get_first_node_in_group("player")
	
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

func _process(delta: float) -> void:
	if visible and is_instance_valid(jugador_objetivo):
		var posicion_en_pantalla = jugador_objetivo.get_global_transform_with_canvas().origin
		var destino_final = posicion_en_pantalla - Vector2(size.x / 2.0, size.y + distancia_cabeza) + offset_flotante
		position = position.lerp(destino_final, 10.0 * delta)

func mostrar_pensamiento(nuevo_texto: String) -> void:
	if animacion_actual and animacion_actual.is_valid():
		animacion_actual.kill()
		
	label.text = nuevo_texto
	label.visible_ratio = 0.0 
	offset_flotante = Vector2(0, 20)
	
	# Forzamos el recálculo del tamaño mínimo antes de centrar el pivote
	reset_size()
	
	if is_instance_valid(jugador_objetivo):
		position = jugador_objetivo.get_global_transform_with_canvas().origin - Vector2(size.x / 2.0, size.y + distancia_cabeza) + offset_flotante

	# Clavamos el pivote en el centro exacto para que nazca y muera desde el medio
	pivot_offset = size / 2.0
	scale = Vector2(0.5, 0.5) 
	modulate.a = 0.0
	show()
	
	animacion_actual = create_tween().set_parallel(true)
	# Entrada: aparece desde el centro hacia afuera
	animacion_actual.tween_property(self, "offset_flotante:y", 0.0, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacion_actual.tween_property(self, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	animacion_actual.tween_property(self, "modulate:a", 1.0, 0.8)
	
	var tiempo_escritura = min(nuevo_texto.length() * 0.04, 3.5) 
	animacion_actual.tween_property(label, "visible_ratio", 1.0, tiempo_escritura)
	
	timer.start(tiempo_escritura + 2.5)

func _on_timer_timeout() -> void:
	if animacion_actual and animacion_actual.is_valid():
		animacion_actual.kill()
		
	# Nos aseguramos de que el pivote siga en el centro antes de encogerlo
	pivot_offset = size / 2.0
		
	animacion_actual = create_tween().set_parallel(true)
	# Salida: Se encoge hacia adentro (escala a 0) lentamente
	animacion_actual.tween_property(self, "scale", Vector2(0.0, 0.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animacion_actual.tween_property(self, "modulate:a", 0.0, 1.2)
	
	animacion_actual.chain().tween_callback(hide)
