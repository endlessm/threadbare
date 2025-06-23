extends Area2D

@onready var timer: Timer=$Timer
func _on_body_entered(body: Node2D) -> void: #metodo a utilizar cuando el jugador cruce el limite de zona de muerte
	print("Game Over :( ") 
	Engine.time_scale = 0.5 #dura mas tiempo es como un video de youtube xd
	body.get_node("CollisionShape2D").queue_free() #eliminamos la colision para que empiece a caerce del mapa
	timer.start()
	



func _on_timer_timeout() -> void:
	Engine.time_scale = 1 # dejar tiuempo normal
	get_tree().reload_current_scene() #reinicia la escenea 
