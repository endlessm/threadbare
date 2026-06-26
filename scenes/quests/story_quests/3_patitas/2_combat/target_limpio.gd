# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Area2D

signal arco_golpeado
signal toco_suelo

var velocidad_caida : float = 120.0 # Qué tan rápido caen los meteoritos
var fue_defendido : bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Línea nueva: Hace que cada meteorito empiece un poco más arriba de forma aleatoria
	position.y -= randf_range(0.0, 400.0)
func _process(delta: float) -> void:
	# Si Nox no lo ha bateado, el meteorito sigue cayendo
	if not fue_defendido:
		position.y += velocidad_caida * delta
		
		# Si pasa del límite de la pantalla (abajo en el suelo)
		if position.y > 350: 
			toco_suelo.emit()
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Detecta el golpe de Nox
	if body.name.to_lower().contains("player") or body.name.to_lower().contains("nox") or body.is_in_group("player"):
		# Si tu jugador ya lo manda a volar por física, solo avisamos al cerebro
		if not fue_defendido:
			fue_defendido = true
			arco_golpeado.emit()
			
			# Efecto opcional: Se desvanece poco a poco mientras vuela por los aires
			var tween : Tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.6)
			tween.tween_callback(queue_free)
