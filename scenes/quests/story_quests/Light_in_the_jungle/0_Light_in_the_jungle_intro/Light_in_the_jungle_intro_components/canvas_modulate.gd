extends CanvasModulate

@export var end_color : Color = Color(1.0, 0.26, 0.298)  # Color final, como #ff434c
@export var delay_after_dialogue : float = 2.0  # Tiempo después del diálogo antes de cambiar el color
@export var transition_duration : float = 3.0  # Duración de la transición del color
@export var target_dialogue : DialogueResource  # El diálogo específico que debe terminar

func _ready():
	# Conectar al DialogueManager para escuchar cuando termine el diálogo
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	print("CanvasModulate: Script iniciado, esperando fin del diálogo")

func _on_dialogue_ended(dialogue_resource: DialogueResource):
	print("CanvasModulate: Diálogo terminado detectado")
	
	# Solo cambiar el color si es el diálogo específico que queremos
	if target_dialogue and dialogue_resource != target_dialogue:
		print("CanvasModulate: No es el diálogo objetivo, ignorando")
		return
	
	print("CanvasModulate: ¡Es nuestro diálogo! Iniciando cambio de color...")
	
	# Esperar un poco (delay_after_dialogue) antes de cambiar el color
	await get_tree().create_timer(delay_after_dialogue).timeout
	
	print("CanvasModulate: Iniciando transición de color")
	
	# Guardar el color inicial para la animación
	var initial_color = color
	
	# Crear una animación suave usando un Tween
	var tween = create_tween()
	tween.tween_property(self, "color", end_color, transition_duration)
	
	# Opcional: añadir easing para una transición más dramática
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	print("CanvasModulate: Transición de color completada")
