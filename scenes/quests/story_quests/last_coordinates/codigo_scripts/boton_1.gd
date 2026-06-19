extends CharacterBody2D

@export var textura_presionado: Texture2D

# Esta es la magia: Creamos una variable para decirle a este botón 
# a quién debe esperar antes de activarse.
@export var boton_anterior: CharacterBody2D 

var ya_presionado: bool = false

func presionar() -> void:
	# 1. Si ya me presionaron antes, no hago nada
	if ya_presionado:
		return
		
	# 2. Si tengo un botón anterior asignado, y ese botón AÚN NO está presionado, cancelo
	if boton_anterior != null and not boton_anterior.ya_presionado:
		return
		
	# 3. Si pasé las reglas anteriores, me presiono y cambio mi textura
	ya_presionado = true
	$Sprite2D.texture = textura_presionado
	
	# EL FIX: Apagamos el recorte del Sprite2D para que no corte la nueva textura
	$Sprite2D.region_enabled = false
	# (Opcional para el futuro) Aquí podríamos avisarle al nivel que un botón fue presionado
