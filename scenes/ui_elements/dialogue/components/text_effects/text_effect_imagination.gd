@tool
# Having a class name is handy for picking the effect in the Inspector.
class_name ImaginationTextEffect
extends RichTextEffect

# To use this effect:
# - Use [Memory]hello[/Memory] in text.
var bbcode := "Imagination"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var text_color := Color("#7C6000")
	var text_markup := Color("c49f23ff")

	var speed: float = 4.0
	var span: float = 2.0

	# Cálculo de la onda seno suave entre 0.0 y 1.0 basada en el tiempo y la posición
	var factor_seno = sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5

	char_fx.color = text_color.lerp(text_markup, factor_seno)
	char_fx.offset = Vector2(0, -factor_seno * 2)
	return true
