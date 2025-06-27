extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print("+1 moneda") # Replace with function body.
	queue_free()#borrrar moneda


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	print("Soy una moneda") #se ejecuta cuando inicia el juego


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
