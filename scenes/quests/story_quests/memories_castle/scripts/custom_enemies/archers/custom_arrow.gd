class_name CustomArrow extends Projectile

func _ready() -> void:
	super._ready()
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.0
	pm.friction = 1.0
	physics_material_override = pm

func got_hit(player: Player) -> void:
	self.explode()
