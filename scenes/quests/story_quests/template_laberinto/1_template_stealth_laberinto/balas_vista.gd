extends CanvasLayer

@onready var imagenes_balas := [
	$balas/Panel/b1,
	$balas/Panel/b2,
	$balas/Panel/b3,
	$balas/Panel/b4,
	$balas/Panel/b5
]

@onready var recarga_bar: ProgressBar = $balas/Panel/RecargaBar  # Reemplaza HSlider

var balas: int = 5
var recargando: bool = false
var tiempo_recarga: float = 3.0  # Segundos para recargar 1 bala

func _ready():
	for img in imagenes_balas:
		img.visible = true
	recarga_bar.visible = false
	recarga_bar.min_value = 0
	recarga_bar.max_value = tiempo_recarga
	recarga_bar.value = 0

func procesar_disparo() -> bool:
	if balas > 0:
		balas -= 1
		imagenes_balas[balas].visible = false
		
		# Iniciar recarga si no está en curso
		if not recargando:
			recargando = true
			recarga_bar.visible = true
			recarga_bar.value = 0
		return true
	else:
		return false

func _process(delta):
	if recargando:
		recarga_bar.value += delta
		if recarga_bar.value >= tiempo_recarga:
			recarga_bar.value = 0.0
			if balas < 5:
				imagenes_balas[balas].visible = true
				balas += 1
			if balas >= 5:
				recargando = false
				recarga_bar.visible = false
