extends Node

@onready var label = $CanvasLayer/Control/RichTextLabel
@onready var imagen = $CanvasLayer/Control/TextureRect

# Edita aquí tu secuencia
var secuencia = [
	{"texto": "Tras la batalla final, Wari despertó en un lugar cubierto por una luz blanca 
	infinita, sin comprender dónde estaba ni cómo había llegado allí.", "imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/01.png")},
	{"texto": "Frente a ella apareció la misteriosa entidad, revelando que nunca 
	fue un enemigo, sino un guía con una misión mucho más importante.", "imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/02.png")},
	{"texto": "A su alrededor surgieron recuerdos del 
	Valle Sagrado, Sacsayhuamán, las llamas, el laberinto y Machu Picchu, 
	mostrando fragmentos de una historia olvidada.", "imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/03.png")},
	{"texto": "La entidad le explicó que aquellas tradiciones y conocimientos 
	formaban parte de su identidad, y que aún era posible preservar ese legado.", "imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/04.png")},
	{"texto": "Con una nueva comprensión de sus raíces, 
	el protagonista regresó al Cusco futurista, 
	decidido a que la historia de su pueblo nunca fuera olvidada.", "imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/05.png")},
	{"texto": "Muchas gracias por jugar.", "imagen": null},
	{"texto": "RUNA RUNNER", "imagen": null},
]

func _ready():
	imagen.visible = false
	label.visible = false
	await get_tree().create_timer(0.5).timeout
	await reproducir_cinematica()
	# Aquí puedes cambiar de escena al terminar:
	# get_tree().change_scene_to_file("res://menu.tscn")

func reproducir_cinematica():
	for paso in secuencia:
		# --- MOSTRAR TEXTO ---
		label.text = paso["texto"]
		label.visible_ratio = 0.0
		label.visible = true
		imagen.visible = false

		await fadeIn(label)

		# Efecto de escritura
		var tween = create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, len(paso["texto"]) * 0.05)
		await tween.finished
		await get_tree().create_timer(1.5).timeout

		await fadeOut(label)

		# --- MOSTRAR IMAGEN (si hay) ---
		if paso["imagen"] != null:
			imagen.texture = paso["imagen"]
			imagen.visible = true
			await fadeIn(imagen)
			await get_tree().create_timer(2.5).timeout
			await fadeOut(imagen)

func fadeIn(nodo: CanvasItem):
	nodo.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(nodo, "modulate:a", 1.0, 0.6)
	await tween.finished

func fadeOut(nodo: CanvasItem):
	var tween = create_tween()
	tween.tween_property(nodo, "modulate:a", 0.0, 0.6)
	await tween.finished
