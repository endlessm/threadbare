extends Node2D

@export_group("Mushroom Vision")
@export var mushroom_zoom: Vector2 = Vector2(0.45, 0.45)
@export var mushroom_view_duration: float = 2.0
@export var mushroom_zoom_transition_time: float = 0.25

@onready var area_2d: Area2D = $Area2D

var consumed: bool = false


func _ready() -> void:
	area_2d.body_entered.connect(_on_area_body_entered)


func _on_area_body_entered(body: Node2D) -> void:
	if consumed:
		return

	if not body.is_in_group("player"):
		return

	consumed = true

	var camera := body.get_node_or_null("Camera2D") as Camera2D
	var rules := get_tree().get_first_node_in_group(&"el_abandonado_labyrinth_rules")
	if camera and rules and rules.has_method("activate_mushroom_vision"):
		rules.activate_mushroom_vision(
			camera,
			mushroom_zoom,
			mushroom_view_duration,
			mushroom_zoom_transition_time
		)

	queue_free()
