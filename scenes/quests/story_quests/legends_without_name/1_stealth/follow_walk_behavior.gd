# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends FollowWalkBehavior

func _ready() -> void:
	super._ready()
	process_priority = 100 # Prioridad alta para ejecutarse después de la plantilla
	
	if Engine.is_editor_hint():
		return
		
	# Desactiva el procesamiento del comportamiento de patrulla original sin borrarlo
	var guard_movement := get_node_or_null("../GuardMovement")
	if guard_movement:
		guard_movement.process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if Engine.is_editor_hint():
		return

	var sprite := get_node_or_null("../AnimatedSprite2D") as AnimatedSprite2D
	if not sprite:
		sprite = get_node_or_null("%PlayerSprite") as AnimatedSprite2D

	if character and is_instance_valid(sprite):
		# Giro de dirección horizontal según la velocidad
		if character.velocity.x < -10.0:
			sprite.flip_h = true
		elif character.velocity.x > 10.0:
			sprite.flip_h = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var sprite := get_node_or_null("../AnimatedSprite2D") as AnimatedSprite2D
	if not sprite:
		sprite = get_node_or_null("%PlayerSprite") as AnimatedSprite2D

	if character and is_instance_valid(sprite):
		# Sobrescribe la animación en _process utilizando la velocidad real
		if character.velocity.length_squared() > 25.0:
			if sprite.animation != &"walk":
				sprite.play(&"walk")
		else:
			if sprite.animation != &"idle":
				sprite.play(&"idle")
