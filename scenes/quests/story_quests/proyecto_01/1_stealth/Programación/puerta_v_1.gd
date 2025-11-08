extends StaticBody2D

var abierta: bool = false

func AbrirPuerta():
	if abierta:
		return
	abierta = true
	print("🚪 Puerta abierta")

	var sprite = get_node_or_null("Sprite2D")
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = true
	if sprite:
		sprite.visible = false
