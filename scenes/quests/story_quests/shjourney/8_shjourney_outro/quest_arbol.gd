extends Node2D

var arboles_contactados: int = 0
const ARBOLES_NECESARIOS := 1

func _ready() -> void:
	# Busca en TODO el árbol de la escena, recursivamente, nodos de tipo ArbolFantasma1
	var arboles: Array = get_tree().get_root().find_children("*", "ArbolFantasma1", true, false)
	var conectados := 0
	for a in arboles:
		# Evita conexiones duplicadas
		if not a.dialogo_terminado.is_connected(reportar_arbol_contactado):
			a.dialogo_terminado.connect(reportar_arbol_contactado)
			conectados += 1
	print(" Árboles ArbolFantasma1 encontrados:", arboles.size(), " | Conectados ahora:", conectados)

func reportar_arbol_contactado() -> void:
	arboles_contactados += 1
	print("Progreso árboles: ", arboles_contactados, "/", ARBOLES_NECESARIOS)
	if arboles_contactados >= ARBOLES_NECESARIOS:
		abrir_camino()

func abrir_camino() -> void:
	var obstaculo1 := get_tree().get_nodes_in_group("bloqueo_camino1")
	print(" Meta alcanzada. Obstáculos encontrados en 'bloqueo_camino': ", obstaculo1.size())
	obstaculo1[0].queue_free()
	print("Camino abierto.")
