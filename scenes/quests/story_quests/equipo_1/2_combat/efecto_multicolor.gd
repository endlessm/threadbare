extends ColorRect
@onready var enemigo = %Balder;
@onready var animador_efectos = %AnimadorEfectos

func arrancar_efecto():
	
	print("animacion en curso")
	
	if is_instance_valid(enemigo):
		# 1. Conseguimos la posición global del enemigo en ESTE milisegundo
		var pos_guardia = enemigo.global_position
		
		# 2. Conseguimos los límites exactos de este ColorRect gigante
		var inicio_mapa = global_position # Esquina superior izquierda
		var tamano_mapa = size            # El tamaño estirado en píxeles
		
		# 3. REGLA DE TRES: Calculamos el porcentaje estático (0.0 a 1.0)
		var pos_shader_x = (pos_guardia.x - inicio_mapa.x) / tamano_mapa.x
		var pos_shader_y = (pos_guardia.y - inicio_mapa.y) / tamano_mapa.y
		
		var pos_shader = Vector2(pos_shader_x, pos_shader_y)
	
		# 🎯 Enviamos el vector al shader (se quedará fijo en esta posición)
		material.set_shader_parameter("posicion_jugador", pos_shader)
	
	# 🎬 Disparamos la animación del AnimationPlayer
	animador_efectos.play("super_transicion")

func pausar_efecto()->void:
	animador_efectos.pause()
func reanudar_efecto()->void:
	animador_efectos.play()	
func resetear_efecto()->void:
	animador_efectos.play("RESET")
