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
		jefe_derrotado.emit()
			

func recibir_danio_player(cantidad:int)->void:
	vida_actual_player -= cantidad
	vida_actual_player = max(vida_actual_player, 0)
	barra_player.value = vida_actual_player
	if vida_actual_player <= 0:
		player_derrotado.emit()		
