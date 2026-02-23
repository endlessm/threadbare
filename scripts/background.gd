@tool
extends ParallaxBackground

## Use this to tint the texture of the background a different color.
@export var tint: Color = Color.WHITE:
	set = _set_tint

@onready var parallax_layers = [
	%ParallaxLayer,
	%ParallaxLayer2,
	%ParallaxLayer3,
]


func _set_tint(new_tint: Color):
	tint = new_tint
	if is_node_ready():
		for _layer in parallax_layers:
			_layer.modulate = tint


func _ready():
	_set_tint(tint)
