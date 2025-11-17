extends FillGameLogic
## Wizzy Quest combat puzzle game logic
##
## Extends base FillGameLogic with custom features:
## - Custom barrel win condition (2 barrels instead of 3)
## - Enemy shake feedback when barrel is completed
##
## The inverted barrel mechanic is handled in wizzy_filling_barrel.gd

## Number of barrels that must be emptied to win (inverted mechanic)
@export var custom_barrels_to_win: int = 4


func _ready() -> void:
	barrels_to_win = custom_barrels_to_win
	super._ready()


## Extends barrel completion with enemy shake feedback
func _on_barrel_completed() -> void:
	_shake_all_enemies()
	super._on_barrel_completed()


## Triggers shake animation on all throwing enemies as visual feedback
func _shake_all_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("throwing_enemy"):
		if enemy.has_method("shake"):
			enemy.shake()
