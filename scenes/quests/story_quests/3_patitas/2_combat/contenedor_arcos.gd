# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

# Esta señal avisará al cerebro del juego que este arco fue destruido
signal arco_golpeado

func _ready() -> void:
	# Conectamos la colisión consigo mismo por código para evitar errores de clics
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si lo que tocó el arco es Nox (el jugador)
	if body.name.to_lower().contains("player") or body.name.to_lower().contains("nox") or body.is_in_group("player"):
		registrar_impacto()

func registrar_impacto() -> void:
	# Desactivamos las colisiones de inmediato para que no se golpee dos veces
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Emitimos la señal hacia el juego principal
	arco_golpeado.emit()
	
	# Efecto visual de explosión/desaparición rápida
	var tween : Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.12)
	tween.tween_callback(queue_free)
