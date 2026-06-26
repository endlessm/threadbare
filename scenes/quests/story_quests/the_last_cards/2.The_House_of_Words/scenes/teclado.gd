@tool
extends VBoxContainer
signal letra_presionada(letra)

var fila1 = "QWERTYUIOP"
var fila2 = "ASDFGHJKL"
var fila3 = "ZXCVBNM"

var color_normal = Color(0.01, 0.159, 0.176, 1.0)
var color_hover = Color(0.099, 0.268, 0.188, 1.0)
var color_pressed = Color(0.1, 0.4, 0.8)
var color_texto = Color(1, 1, 1)

func _ready():
	_crear_fila($Fila1, fila1)
	_crear_fila($Fila2, fila2)
	_crear_fila($Fila3, fila3)

func _crear_estilo(color: Color, radio: int = 8) -> StyleBoxFlat:
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.corner_radius_top_left = radio
	estilo.corner_radius_top_right = radio
	estilo.corner_radius_bottom_left = radio
	estilo.corner_radius_bottom_right = radio
	return estilo

func _crear_fila(contenedor, letras):
	for letra in letras:
		var boton = Button.new()
		boton.text = letra
		boton.custom_minimum_size = Vector2(60, 60)
		boton.add_theme_stylebox_override("normal", _crear_estilo(color_normal))
		boton.add_theme_stylebox_override("hover", _crear_estilo(color_hover))
		boton.add_theme_stylebox_override("pressed", _crear_estilo(color_pressed))
		boton.add_theme_color_override("font_color", color_texto)
		boton.pressed.connect(
			func():
				emit_signal("letra_presionada", letra)
				boton.add_theme_stylebox_override("normal", _crear_estilo(color_normal))
		)
		contenedor.add_child(boton)
