extends Area2D
@export var can_use = false;
@export var can_use_area = false;
signal event
signal event_area
func _ready() -> void:
	body_entered.connect(_on_body_entered);
	area_entered.connect(_on_area_entered);
	
func _on_body_entered(body:Node2D) -> void:
	
	if !can_use:
		return
	if body is Player:
		set_deferred("monitoring", false)
		var player: Player = body;
		event.emit()
		queue_free();	
		
func _on_area_entered(area:Area2D):
	if !can_use_area:
		return
	if area == %DeteccionGuardian:
		event_area.emit()
		queue_free();	
