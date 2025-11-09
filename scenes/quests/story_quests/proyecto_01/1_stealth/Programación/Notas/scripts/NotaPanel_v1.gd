extends CanvasLayer

@onready var imagen: TextureRect = $TextureRect

func mostrar(tex: Texture2D) -> void:
	visible = true
	imagen.texture = tex

func ocultar() -> void:
	visible = false
