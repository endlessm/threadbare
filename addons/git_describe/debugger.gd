extends EditorDebuggerPlugin

signal session_stopped


func _setup_session(session_id: int) -> void:
	get_session(session_id).stopped.connect(
			# Wrapped in lambda function to work in Godot 4.2.
			func () -> void: session_stopped.emit()
	)
