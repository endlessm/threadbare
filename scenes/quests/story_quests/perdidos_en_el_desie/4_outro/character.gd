 
extends AnimatedSprite2D

func _ready() -> void:
	pass 
	
var speed:int = 120 #Velocidad de movimiento del personaje

#Función de movimiento al lugar final del recorrido
func mover_a_salida() -> void: 
	await get_tree().create_timer(2.0).timeout
	play("walk") #Caminar hacia derecha
	await mover_a(Vector2(500,200))
	play("attack_03") #Practica de batalla
	await get_tree().create_timer(3.0).timeout
	play("walk") #Caminar hacia la salida
	await mover_a(Vector2(670,200))
	await mover_a(Vector2(670,470))
	await mover_a(Vector2(1600,470))
	play("idle")
#Función a puntos espescificos
func mover_a(destino:Vector2) -> void: 
	while position.distance_to(destino) > 5 :
		var direccion:Vector2 = (destino - position).normalized()
		position += direccion * speed * get_process_delta_time()
		await get_tree().process_frame
