extends FillingBarrel
## Custom filling barrel for Wizzy Quest
## Los proyectiles encendidos incrementan, los apagados decrementan
## El objetivo es DECREMENTAR a 0, no llenar a 3

## Decrementa la cantidad (inverso de increment)
func decrement(by: int = 1) -> void:
	if _amount <= 0:
		_disable_collisions.call_deferred()
		animation_player.play(&"completed")
		await animation_player.animation_finished
		queue_free()
		completed.emit()
		return
	
	animation_player.play(&"increment")
	_amount = max(0, _amount - by)
	
	# Frame invertido: 0=lleno, último=vacío
	var progress := float(needed_amount - _amount) / needed_amount
	animated_sprite_2d.frame = floor(progress * (_total_frames() - 1))
	
	if _amount == 0:
		decrement(0)


## Sobrescribir increment para que NO complete el barril
func increment(by: int = 1) -> void:
	if _amount >= needed_amount:
		return
	
	animation_player.play(&"increment")
	_amount = min(needed_amount, _amount + by)
	
	# Frame invertido: 0=lleno, último=vacío
	var progress := float(needed_amount - _amount) / needed_amount
	animated_sprite_2d.frame = floor(progress * (_total_frames() - 1))


func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	
	# Iniciar lleno con frame 0 (invertido)
	_amount = needed_amount
	animated_sprite_2d.frame = 0
	
	# Configurar HitBox para detectar proyectiles apagados
	var hit_box = get_node_or_null("HitBox")
	if hit_box:
		hit_box.set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)
