extends Area2D

@onready var timer: Timer=$Timer
func _on_body_entered(body: Node2D) -> void: #metodo a utilizar cuando el jugador cruce el limite
	print("Game Over :( ") # Replace with function body.
	timer.start()
	



func _on_timer_timeout() -> void:
	get_tree().reload_current_scene() #reinicia la escenea
