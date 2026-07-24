extends Projectile
func _ready() -> void:
	super()
	
func got_repelled(repel_direction: Vector2) -> void:
	super(repel_direction)
	_set_can_hit_enemy(true)
