@tool
class_name ImaginationTextEffect
extends RichTextEffect

var bbcode := "Imagination"

var text_color := Color("#7C6000")
var text_markup := Color("c49f23ff")

var speed: float = 4.0
var span: float = 2.0


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var time_var := sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5

	char_fx.color = text_color.lerp(text_markup, time_var)
	char_fx.offset = Vector2(0, -time_var * 2)

	return true
