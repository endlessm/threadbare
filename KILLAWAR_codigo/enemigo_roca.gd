extends Node2D

const VELOCIDAD=60
var direccion = 1
@onready var ray_castizquierda: RayCast2D = $RayCastizquierda
@onready var ray_castderecha: RayCast2D = $RayCastderecha
@onready var animated: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	if ray_castderecha.is_colliding():
		direccion=-1
		animated.flip_h=true
	if ray_castizquierda.is_colliding():
		direccion=1
		animated.flip_h=false
		
	position.x += direccion * VELOCIDAD * delta # direccion +1 sera a la derecha si cambia -1 pues ira a la izquierda
	
	
	
