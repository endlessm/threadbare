extends CanvasLayer
@export var boss:ThrowingEnemy
@export var barra_jefe: ProgressBar
@export var barra_player: ProgressBar

signal fase2
signal fase3
var vida_maxima: int = 360
var vida_actual: int = 360

var vida_maxima_player: int = 100
var vida_actual_player: int = 100

signal jefe_derrotado
signal player_derrotado

var can_be_defeated:bool = true
var player_can_be_damaged=true

func _ready() -> void:
	barra_jefe.max_value = vida_maxima
	barra_jefe.value = vida_actual
	barra_player.max_value = vida_maxima_player
	barra_player.value = vida_actual_player
	
func recibir_danio(cantidad:int)->void:
	vida_actual -= cantidad
	vida_actual = max(vida_actual, 0)
	barra_jefe.value = vida_actual
	
	if(vida_actual==240):
		fase2.emit()
	
	if(vida_actual==120):
		fase3.emit()	
		
	if vida_actual <= 0:
		can_be_defeated=false
		barra_jefe.visible=false
		barra_player.visible=false
		jefe_derrotado.emit()
			

func recibir_danio_player(cantidad:int)->void:
	if !player_can_be_damaged:
		return
		
	vida_actual_player -= cantidad
	vida_actual_player = max(vida_actual_player, 0)
	barra_player.value = vida_actual_player
	if vida_actual_player <= 0 && can_be_defeated:
		player_derrotado.emit()		
