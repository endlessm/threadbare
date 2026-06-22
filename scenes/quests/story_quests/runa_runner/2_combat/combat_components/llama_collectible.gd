extends Area2D

signal rescued

@export var llama_id: StringName
@export var rescue_state_path: NodePath
@export var bob_height: float = 4.0
@export var bob_speed: float = 2.5

@onready var sprite: Sprite2D = %Sprite2D

var _base_sprite_y := 0.0
var _rescued := false


func _ready() -> void:
	_base_sprite_y = sprite.position.y
	if String(llama_id).is_empty():
		llama_id = StringName(name)

	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if _rescued:
		return

	sprite.position.y = _base_sprite_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height


func _on_body_entered(body: Node2D) -> void:
	if _rescued or not body.is_in_group("player"):
		return

	var rescue_state := _get_rescue_state()
	if rescue_state and rescue_state.has_method("rescue_llama"):
		_rescued = rescue_state.call("rescue_llama", llama_id) == true
	else:
		_rescued = true

	if not _rescued:
		return

	rescued.emit()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	visible = false
	call_deferred("queue_free")


func _get_rescue_state() -> Node:
	if not rescue_state_path.is_empty():
		var state := get_node_or_null(rescue_state_path)
		if state:
			return state

	return get_tree().get_first_node_in_group("llama_rescue_state")
