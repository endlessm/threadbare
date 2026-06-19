extends Node

@onready var boss = %BalderFuturo
@onready var player = %Player
@export var animacion: ColorRect

func _time_stop()->void:
	animacion.arrancar_efecto()
	await get_tree().create_timer(3).timeout	
	animacion.pausar_efecto()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	await boss.ataque_circular(true,4)##aqui cambiamos parametros
	animacion.reanudar_efecto()
	await get_tree().create_timer(1).timeout
	player.process_mode = Node.PROCESS_MODE_INHERIT
	boss.activar_projectiles()
	animacion.resetear_efecto()
		

func _on_damaged(body:Node2D)->void:
	if body is Projectile:
		##POR ALGUNA RAZON, ESTO NO FUNCIONABA BIEN, DETECTABA
		##AUNQUE LA COLISION SEA FALSA
		##UN RATO DESPUES FUNCIONO NORMAL PERO LUEGO SE ME CRASHEO
		## Y YA NO FUNCIONO XDD, ASI QUE LO DEJO ASI
		
		if not body.get_collision_mask_value(8): 
			return 
			
		print("me han pegado (¡Este sí es real!)")

func ataque_barrido_prueba()->void:	
	##true para que dispare varios proyectiles en cada ataque (5)
	##false para que solo dispare 1
	
	##4 el numero de cadenas de repeticiones por ataque
	boss.ataque_circular(true,1)

func _pausar()->void:
	boss.timer.stop();

func _reanudar()->void:
	boss.timer.start();	
	
