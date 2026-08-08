extends Node2D

##solo llamar a este metodo una vez
var rectos: Array[Node2D] = []  # Norte, Sur, Este, Oeste
var diagonales: Array[Node2D] = []  # Noreste, Noroeste, Sureste, Suroeste
var cardinales: Array=[]
func _ready() -> void:
	print("creando circulos")
	crear_circulo(200,40)
	cardinales.push_front(rectos)
	cardinales.push_front(diagonales)
	
func crear_circulo(radio: float, cantidad_puntos: int) -> void:
	for i in range(cantidad_puntos):
		var angulo = i * (TAU / cantidad_puntos)
		var x = radio * cos(angulo)
		var y = radio * sin(angulo)
		
		var punto = Node2D.new()
		punto.position = Vector2(x, y)
		
		var visual = ColorRect.new()
		visual.size = Vector2(10, 10) 
		visual.color = Color.MEDIUM_SPRING_GREEN 
		visual.position = Vector2(-5, -5) 
		
		punto.add_child(visual)
		add_child(punto)
		
		var dir_x = cos(angulo)
		var dir_y = sin(angulo)
		
		if is_equal_approx(dir_x, 0.0) or is_equal_approx(dir_y, 0.0):
			rectos.append(punto)
			visual.color = Color.RED 

		elif is_equal_approx(abs(dir_x), abs(dir_y)):
			diagonales.append(punto)
			visual.color = Color.ORANGE
