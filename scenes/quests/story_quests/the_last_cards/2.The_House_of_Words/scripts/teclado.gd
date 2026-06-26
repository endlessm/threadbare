@tool
extends VBoxContainer

signal letra_presionada(letra: String)

var fila1: String = "QWERTYUIOP"
var fila2: String = "ASDFGHJKL"
var fila3: String = "ZXCVBNM"
var color_normal: Color = Color(0.01, 0.159, 0.176, 1.0)
var color_hover: Color = Color(0.099, 0.268, 0.188, 1.0)
var color_pressed: Color = Color(0.1, 0.4, 0.8)
var color_texto: Color = Color(1, 1, 1)


func _ready() -> void:
	_crear_fila($Fila1, fila1)
	_crear_fila($Fila2, fila2)
	_crear_fila($Fila3, fila3)


func _crear_estilo(color: Color, radio: int = 8) -> StyleBoxFlat:
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.corner_radius_top_left = radio
	estilo.corner_radius_top_right = radio
	estilo.corner_radius_bottom_left = radio
	estilo.corner_radius_bottom_right = radio
	return estilo


func _crear_fila(contenedor: Node, letras: String) -> void:
	for letra: String in letras:
		var boton: Button = Button.new()
		boton.text = letra
		boton.custom_minimum_size = Vector2(60, 60)
		boton.add_theme_stylebox_override("normal", _crear_estilo(color_normal))
		boton.add_theme_stylebox_override("hover", _crear_estilo(color_hover))
		boton.add_theme_stylebox_override("pressed", _crear_estilo(color_pressed))
		boton.add_theme_color_override("font_color", color_texto)
		boton.pressed.connect(
			func() -> void:
				emit_signal("letra_presionada", letra)
				boton.add_theme_stylebox_override("normal", _crear_estilo(color_normal))
		)
		contenedor.add_child(boton)
