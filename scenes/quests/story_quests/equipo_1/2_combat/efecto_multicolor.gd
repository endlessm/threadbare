extends ColorRect
@export var enemigo:CharacterBody2D;
@onready var animador_efectos = %AnimadorEfectos

func arrancar_efecto():
	
	if is_instance_valid(enemigo):
		var pos_guardia = enemigo.global_position
		
		var inicio_mapa = global_position 
		var tamano_mapa = size           
		
		var pos_shader_x = (pos_guardia.x - inicio_mapa.x) / tamano_mapa.x
		var pos_shader_y = (pos_guardia.y - inicio_mapa.y) / tamano_mapa.y
		
		var pos_shader = Vector2(pos_shader_x, pos_shader_y)
	
		material.set_shader_parameter("posicion_jugador", pos_shader)
	
	animador_efectos.play("super_transicion")

func pausar_efecto()->void:
	animador_efectos.pause()
func reanudar_efecto()->void:
	animador_efectos.play()	
func resetear_efecto()->void:
	animador_efectos.play("RESET")
