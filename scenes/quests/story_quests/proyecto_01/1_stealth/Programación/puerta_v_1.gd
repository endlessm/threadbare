extends StaticBody2D

var abierta: bool = false

func AbrirPuerta():
	if abierta:
		return
	abierta = true
	print("🚪 Puerta abierta correctamente")

	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")

	if col:
		col.set_deferred("disabled", true) # ✅ importante
	if sprite:
		sprite.visible = false
