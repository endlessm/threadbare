extends Node2D
@onready var balder = %Balder
@onready var player = %Player
@onready var efecto = %EfectoMulticolor

var deteccion_pos = Vector2i(-230.0,1308.0)

@export var entidades: Array[Node2D] =[]
@onready var estados_guardias: Array[Node.ProcessMode] =[]
signal pausado
signal reanudado

func _ready() -> void:
	entidades.assign(get_tree().get_nodes_in_group("Entidades"))
	
func _parar_tiempo(jugador_detectado:bool=false):
	efecto.arrancar_efecto()	
	await get_tree().create_timer(3).timeout
	
	##para aumentar la velocidad de balder
	%Balder.move_speed = %Balder.move_speed+15
	
	efecto.pausar_efecto()
	player.take_control(self)
	%DeteccionGuardian.global_position = player.global_position
	player.velocity = Vector2.ZERO
	entidades_pausadas(true)
	if player.has_node("PlayerSprite"):
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if(jugador_detectado):
		_atacar_jugador()
	pausado.emit(true)

func _parar_tiempo_deteccion():
	_parar_balder()
	_parar_tiempo(true) ##es para usarlo con deteccion de area
	
func _parar_balder():
	balder.guard_movement.stop_moving()
	balder.velocity = Vector2.ZERO
	balder.set_process(false)
	balder.animation_player.play(&"idle")
	
func _reanudar_jugador() -> void:
	player.process_mode = Node.PROCESS_MODE_INHERIT;	

func _atacar_jugador()->void:
	if balder and player:
		player.take_control(self)
		balder.set_collision_mask_value(5, false)##para que traspase paredes
		balder.last_seen_position = player.global_position
		balder.move_speed = 400
		balder.state = balder.State.INVESTIGATING
		balder.set_process(true)


func _reanudar_mundo()->void:
	efecto.reanudar_efecto()
	await get_tree().create_timer(1).timeout
	player.return_control(self)
	_reanudar_jugador()
	%DeteccionGuardian.global_position =deteccion_pos
	await get_tree().process_frame
	entidades_pausadas(false)
	efecto.resetear_efecto()
	reanudado.emit(false)

func entidades_pausadas(pausar:bool)->void:##true los pausa, false los devuelve a la normalidad
	var contador = 0
	for e in entidades:
		if(pausar):
			if(e is Guard):
				estados_guardias.append(e.process_mode)
			e.process_mode = Node.PROCESS_MODE_DISABLED
							
		else:
			if(e is Guard):
				e.process_mode = estados_guardias[contador]
				contador+=1
			else:
				e.process_mode = Node.PROCESS_MODE_INHERIT
	if not pausar:
		estados_guardias.clear()			

func activar_balder()->void:
	%Balder.process_mode = Node.PROCESS_MODE_INHERIT
	%Stones.set_cell(Vector2i(6, 23), -1)
	%Stones.set_cell(Vector2i(7, 23), -1)
	%Stones.set_cell(Vector2i(8, 23), -1)

func aumentar_velocidad(dato)->void:
	print("velocidad antigua:")
	print(%Balder.move_speed)
	%Balder.move_speed = %Balder.move_speed+10
	print("velocidad actual:")
	print(%Balder.move_speed)
