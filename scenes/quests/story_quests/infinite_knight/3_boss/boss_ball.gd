extends CharacterBody2D

var velocidad: float = 200.0
var direccion: Vector2 = Vector2.ZERO
var es_devuelta: bool = false

func _physics_process(delta: float) -> void:
	var _colision: KinematicCollision2D = move_and_collide(direccion * velocidad * delta)
	
	if _colision:
		var objeto_golpeado: Object = _colision.get_collider()
		
		if objeto_golpeado.name == "Player" and es_devuelta == false:
			var golpes: int = 0
			if objeto_golpeado.has_meta("golpes_jefe"):
				golpes = objeto_golpeado.get_meta("golpes_jefe")
				
			golpes += 1
			objeto_golpeado.set_meta("golpes_jefe", golpes)
			
			if golpes >= 3:
				if objeto_golpeado.has_method("defeat"):
					objeto_golpeado.defeat()
			else:
				objeto_golpeado.modulate = Color(1, 0, 0)
				var tween: Tween = objeto_golpeado.create_tween()
				tween.tween_property(objeto_golpeado, "modulate", Color(1, 1, 1), 0.3)
				
			queue_free() 
			
		elif objeto_golpeado.name != "Boss":
			queue_free()

func got_repelled(_dir_repel: Vector2) -> void:
	if es_devuelta:
		return
		
	es_devuelta = true
	direccion = direccion * -1
	velocidad += 150.0
	modulate = Color(0, 1, 0) 

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
