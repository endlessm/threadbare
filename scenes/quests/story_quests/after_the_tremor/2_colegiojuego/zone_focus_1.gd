extends Area2D

@export var target_camera: NodePath
@export var fallback_camera: NodePath

func _ready() -> void:
	# conectar señales solo si no están conectadas
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var cam := get_node_or_null(target_camera)
		if cam:
			cam.make_current()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var cam := get_node_or_null(fallback_camera)
		if cam:
			cam.make_current()
