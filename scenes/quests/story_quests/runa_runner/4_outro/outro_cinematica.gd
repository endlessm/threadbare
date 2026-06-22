extends Node

@export_file("*.tscn") var next_scene: String = "res://scenes/world_map/frays_end.tscn"

@onready var label: RichTextLabel = $CanvasLayer/Control/RichTextLabel
@onready var imagen: TextureRect = $CanvasLayer/Control/TextureRect

var secuencia: Array[Dictionary] = [
	{
		"texto": "Tras la batalla final, Wari desperto en un lugar cubierto por una luz blanca infinita, sin comprender donde estaba ni como habia llegado alli.",
		"imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/01.png"),
	},
	{
		"texto": "Frente a ella aparecio la misteriosa entidad, revelando que nunca fue un enemigo, sino un guia con una mision mucho mas importante.",
		"imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/02.png"),
	},
	{
		"texto": "A su alrededor surgieron recuerdos del Valle Sagrado, Sacsayhuaman, las llamas, el laberinto y Machu Picchu, mostrando fragmentos de una historia olvidada.",
		"imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/03.png"),
	},
	{
		"texto": "La entidad le explico que aquellas tradiciones y conocimientos formaban parte de su identidad, y que aun era posible preservar ese legado.",
		"imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/04.png"),
	},
	{
		"texto": "Con una nueva comprension de sus raices, el protagonista regreso al Cusco futurista, decidido a que la historia de su pueblo nunca fuera olvidada.",
		"imagen": preload("res://scenes/quests/story_quests/runa_runner/4_outro/ELEMENTOS/05.png"),
	},
	{"texto": "Muchas gracias por jugar.", "imagen": null},
	{"texto": "RUNA RUNNER", "imagen": null},
]


func _ready() -> void:
	imagen.visible = false
	label.visible = false
	await get_tree().create_timer(0.5).timeout
	await reproducir_cinematica()
	if not next_scene.is_empty():
		SceneSwitcher.change_to_file(next_scene)


func reproducir_cinematica() -> void:
	for paso: Dictionary in secuencia:
		var texto: String = paso["texto"] as String
		var textura: Texture2D = paso["imagen"] as Texture2D

		label.text = texto
		label.visible_ratio = 0.0
		label.visible = true
		imagen.visible = false

		await fadeIn(label)

		var tween: Tween = create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, texto.length() * 0.05)
		await tween.finished
		await get_tree().create_timer(1.5).timeout

		await fadeOut(label)

		if textura != null:
			imagen.texture = textura
			imagen.visible = true
			await fadeIn(imagen)
			await get_tree().create_timer(2.5).timeout
			await fadeOut(imagen)


func fadeIn(nodo: CanvasItem) -> void:
	nodo.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(nodo, "modulate:a", 1.0, 0.6)
	await tween.finished


func fadeOut(nodo: CanvasItem) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(nodo, "modulate:a", 0.0, 0.6)
	await tween.finished
