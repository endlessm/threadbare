extends FillingBarrel
## Inverted barrel mechanic for Wizzy Quest combat puzzle
##
## Unlike standard barrels:
## - Starts FULL (frame 0)
## - Active projectiles INCREMENT (fill more, bad for player)
## - Disabled projectiles DECREMENT (empty, good for player)
## - Goal: DECREMENT to 0 to complete the barrel
##
## Visual mapping (inverted):
## - Frame 0 = Full barrel (initial state)
## - Last frame = Empty barrel (completed state)


func _ready() -> void:
	super._ready()
	await get_tree().process_frame
	
	# Start full (inverted from standard barrel)
	_amount = needed_amount
	animated_sprite_2d.frame = 0
	
	_configure_disabled_projectile_detection()


## Configures HitBox to detect disabled projectiles (NON_WALKABLE_FLOOR layer)
func _configure_disabled_projectile_detection() -> void:
	var hit_box := get_node_or_null("HitBox")
	if hit_box:
		hit_box.set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)


## Decrements barrel amount (inverted mechanic - this is good for player)
func decrement(by: int = 1) -> void:
	if _amount <= 0:
		_complete_barrel()
		return
	
	animation_player.play(&"increment")
	_amount = max(0, _amount - by)
	_update_inverted_visual()
	
	if _amount == 0:
		decrement(0)  # Trigger completion


## Increments barrel amount (inverted mechanic - this is bad for player)
func increment(by: int = 1) -> void:
	if _amount >= needed_amount:
		return
	
	animation_player.play(&"increment")
	_amount = min(needed_amount, _amount + by)
	_update_inverted_visual()


## Updates sprite frame based on inverted progress (0=full, last=empty)
func _update_inverted_visual() -> void:
	var emptiness_progress := float(needed_amount - _amount) / needed_amount
	animated_sprite_2d.frame = floor(emptiness_progress * (_total_frames() - 1))


## Handles barrel completion sequence
func _complete_barrel() -> void:
	_disable_collisions.call_deferred()
	completed.emit()  # Emit immediately for instant feedback
	animation_player.play(&"completed")
	await animation_player.animation_finished
	queue_free()
