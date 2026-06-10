extends Node2D

##no cambiar
@onready var player = get_parent();
var timer_viento;
var direccion_anterior = 1;
var intento_activar_viento =0;##si llega a x intentos se activa el viento
var viento_activo= false;
var tiempo_viento = 0.0;
var direccion = -1;
var empezar=true
@onready var aviso_viento: Label=$"../AvisoViento";

func _ready()->void:
	aviso_viento.hide();
	await DialogueManager.dialogue_ended
	timer_viento = Timer.new();
	add_child(timer_viento);
	timer_viento.one_shot = false;
	timer_viento.start(0.5);
	timer_viento.timeout.connect(_on_timer_viento_timeout);
	


func direccion_es_igual(actual)-> bool:
	return direccion_anterior==actual;

func _on_timer_viento_timeout()->void:
	
	if(!empezar):
		return;
	
	if(viento_activo):
		return;
		
	var direccion_actual = 0;
	if(player.velocity.x>0):
		direccion_actual = 1;
	elif(player.velocity.x<0):
		direccion_actual = -1;

		
	if(direccion_es_igual(direccion_actual)):
		intento_activar_viento+=1;
	else:
		intento_activar_viento = 0;
			
	direccion_anterior = direccion_actual;	
	if(intento_activar_viento>8):
		viento_activo = true;
		intento_activar_viento = 0;
		aviso_viento.show();

func _physics_process(delta: float) -> void:
	if not viento_activo:
		return;
		
	tiempo_viento +=delta;
	if(tiempo_viento<5):	
		player.velocity.x = -200;
	else:
		tiempo_viento=0.0;
		viento_activo=false;
		aviso_viento.hide();

func _reset_all_attributes()->void:
	direccion_anterior = 1;
	intento_activar_viento =0;##si llega a x intentos se activa el viento
	viento_activo= false;
	tiempo_viento = 0.0;
	direccion = -1;
	aviso_viento.hide();
