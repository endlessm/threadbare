extends Node

@onready var boss = %BalderFuturo
@onready var player = %Player
@export var animacion: ColorRect
@export var timer_time_stop: Timer
var es_barrido = false
var cantidad_disparos=1
var patron=0

var maximo = 1##para poner aleatoriamente los patrones que lanzara
##empieza en 1 porque solo queremos los patrones cruz y equis, se cambia
##a 2 cuando queremos todos los patrones

var recibir_danio = true
signal damage(cantidad:int)

func empezar_batalla()->void:
	boss.start()
	timer_time_stop.start()
	
func _time_stop(numero_patron:int = -1)->void:
	
	##parar ambos timers
	timer_time_stop.stop()
	boss.timer.stop()
	
	recibir_danio=false
	animacion.arrancar_efecto()
	boss._ejecutar_ataque_espera()
	boss.is_stopping = true
	await get_tree().create_timer(3).timeout	
	
	boss.is_stopping = false
	boss.time_stop=true
	boss.ataque_activo = false
	boss.pausar_projectiles()
	animacion.pausar_efecto()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	##Los parametros son:
	##1.Es rafaga o no, si es true significa que disparara 4 proyectiles mas por ataque,
	##si es false solo 1
	##2.Numero de veces que disparara por ataque
	##3. Patron de ataque, puede ser circular, cruz o en equis
	patron =_cambiar_patron(numero_patron)
	await boss.ataque_circular(es_barrido,cantidad_disparos,patron)
	
	animacion.reanudar_efecto()
	await get_tree().create_timer(1).timeout
	player.process_mode = Node.PROCESS_MODE_INHERIT
	boss.activar_projectiles()
	animacion.resetear_efecto()
	boss.time_stop=false
	await get_tree().create_timer(3).timeout
	boss.timer.start()
	recibir_danio=true
	timer_time_stop.start()	
	
func _on_damaged(body:Node2D)->void:
	if body is Projectile:
		##POR ALGUNA RAZON, ESTO NO FUNCIONABA BIEN, DETECTABA
		##AUNQUE LA COLISION SEA FALSA
		##UN RATO DESPUES FUNCIONO NORMAL PERO LUEGO SE ME CRASHEO
		## Y YA NO FUNCIONO XDD, ASI QUE LO DEJO ASI
		
		if not body.get_collision_mask_value(8): 
			return 
		
		if recibir_danio:
			recibir_danio=false
			damage.emit(20)
			##segundos de invulnerabilidad
			await get_tree().create_timer(3).timeout	
			recibir_danio=true

func fase_2()->void:
	print("ENTRANDO A LA FASE 2")
	
	print("PARANDO TIMERS")	
	boss.timer.stop()
	timer_time_stop.stop()
	print("AJUSTANDO ATAQUES")
	es_barrido = true
	cantidad_disparos = 1
	maximo=1
	boss.projectile_speed=100
	boss.espaciado =2
	
	for d in boss.disparos:
		d.projectile_speed=100
	boss.fase2 =true
	boss.fase1 =false
	print("PARANDO EL TIEMPO")
	_time_stop(1)

func fase_3()->void:
	
	print("PARANDO TIMERS")		
	boss.timer.stop()
	timer_time_stop.stop()
	print("AJUSTANDO ATAQUES")
	cantidad_disparos = 2
	boss.espaciado =1
	maximo=2
	boss.fase3 = true
	boss.fase2 =false
	boss.projectile_speed=120
	for d in boss.disparos:
		d.projectile_speed=120
	print("PARANDO EL TIEMPO")	
	_time_stop(2)
	
	
func _pausar()->void:
	boss.timer.stop();

func _reanudar()->void:
	boss.timer.start();	
	
func _cambiar_patron(patron:int)->int:
	var patron_random
	if patron<0 || patron>2:
		patron_random = randi_range(0, maximo)
	else:
		patron_random = patron
	return patron_random
	
	
