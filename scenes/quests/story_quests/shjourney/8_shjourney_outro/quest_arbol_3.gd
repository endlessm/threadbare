extends Node2D

var arboles_contactados: int = 0
const PREGUNTAS_NECESARIOS := 1

func _ready() -> void:
	# Busca en TODO el árbol de la escena, recursivamente, nodos de tipo ArbolFantasma1
	var arboles: Array = get_tree().get_root().find_children("*", "ArbolFantasma3", true, false)
	var conectados := 0
	for a in arboles:
		# Evita conexiones duplicadas
		if not a.dialogo_terminado3.is_connected(reportar_arbol_contactado3):
			a.dialogo_terminado3.connect(reportar_arbol_contactado3)
			conectados += 1
	print("Árboles ArbolFantasma1 encontrados:", arboles.size(), " | Conectados ahora:", conectados)

func reportar_arbol_contactado3() -> void:
	arboles_contactados += 1
	print("Progreso árboles: ", arboles_contactados, "/", PREGUNTAS_NECESARIOS)
	if arboles_contactados >= PREGUNTAS_NECESARIOS:
		abrir_camino()

func abrir_camino() -> void:
	var obstaculo3 := get_tree().get_nodes_in_group("bloqueo_camino3")
	print("Meta alcanzada. Obstáculos encontrados en 'bloqueo_camino3': ", obstaculo3.size())
	#for o in obstaculos:
	obstaculo3[0].queue_free()
	print("Camino abierto.")


func _on_arbol_fantasma_3_dialogo_terminado_3() -> void:
	pass # Replace with function body.
