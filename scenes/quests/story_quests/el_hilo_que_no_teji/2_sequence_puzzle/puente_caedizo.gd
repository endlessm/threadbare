extends TileMapLayer

@export var tiempo_caida: float = 0.7 
@export var jugador: Node2D 
@export var ajuste_pies_y: float = 16.0 

# Variable para controlar el tiempo POST CINEMATICA
@export var tiempo_respiro_post_cinematica: float = 1.25 

var celdas_originales: Array[Vector2i] = []
var celdas_cayendo: Dictionary = {}
var lino_cayendo: bool = false

# --- VARIABLES PARA PAUSA CINEMÁTICA ---
var estaba_en_cinematica: bool = false
var tiempo_respiro_restante: float = 0.0

func _ready() -> void:
	celdas_originales = get_used_cells()

func _physics_process(delta: float) -> void:
	if not visible or not jugador or lino_cayendo:
		return
		
	# 1. Comprobamos si Lino está congelado por el sistema (Cinemática activa)
	var en_cinematica = (jugador.mode == jugador.Mode.SYSTEM_CONTROLLED)
	
	if en_cinematica:
		estaba_en_cinematica = true
		return # Abortamos el cálculo de caída. El puente se vuelve de piedra.
		
	# 2. Si Lino acaba de recuperar el control, activamos el "escudo temporal"
	if estaba_en_cinematica:
		estaba_en_cinematica = false
		tiempo_respiro_restante = tiempo_respiro_post_cinematica 
		
	# 3. Consumimos el tiempo de respiro antes de volver a la normalidad
	if tiempo_respiro_restante > 0.0:
		tiempo_respiro_restante -= delta
		return 

	# --- LÓGICA NORMAL DE CAÍDA ---
	var posicion_pies = jugador.global_position + Vector2(0, ajuste_pies_y)
	var pos_local = to_local(posicion_pies)
	var posicion_celda = local_to_map(pos_local)

	if posicion_celda in celdas_originales:
		
		if get_cell_source_id(posicion_celda) != -1:
			if not celdas_cayendo.has(posicion_celda):
				celdas_cayendo[posicion_celda] = tiempo_caida
		else:
			_matar_a_lino()

	var celdas_a_borrar = []
	for celda in celdas_cayendo.keys():
		celdas_cayendo[celda] -= delta
		if celdas_cayendo[celda] <= 0:
			set_cell(celda, -1) 
			celdas_a_borrar.append(celda)

	for celda in celdas_a_borrar:
		celdas_cayendo.erase(celda)

func _matar_a_lino() -> void:
	lino_cayendo = true
	
	if jugador.has_method("take_control"):
		jugador.take_control(self)
	
	jugador.velocity = Vector2.ZERO
	
	var animacion_caida = create_tween()
	animacion_caida.tween_property(jugador, "scale", Vector2.ZERO, 0.9).set_trans(Tween.TRANS_SINE)
	animacion_caida.tween_property(jugador, "rotation", PI * 4, 0.9)
	
	await animacion_caida.finished
	
	GameState.decrement_lives()
	
	if GameState.current_lives > 0:
		var ruta_actual = get_tree().current_scene.scene_file_path
		SceneSwitcher.change_to_file_with_transition(ruta_actual)
	else:
		if jugador.has_method("_handle_game_over"):
			jugador._
