extends CanvasLayer

@onready var narrador_texto := $Control/NarradorTexto

var lineas: Array[String] = [
	"[b]Hace muchos años, en el sistema de Andromeda...[/b]",
	"[b]Un vínculo entre una ex-spartan y máquina estaba por restaurarse.[/b]",
	"[b]Nexus... Un planeta quebrado por el tiempo.[/b]",
	"[b]Un experimento perdido entre ruinas forerunner.[/b]",
	"[b]Y una sombra que persiste tras el colapso...[/b]",
	"[b]De las cenizas de una misión fallida,\n una figura despierta entre metal, arena y ecos.[/b]",
	"[b]Su nombre olvidado. Su propósito, fragmentado.[/b]",
	"[b]Pero algo dentro de ella aún resiste...[/b]",
	"[b]Unidad Sierra-7... iniciando reconexión.[/b]"
]

var linea_actual := 0
var esperando_input := false
var esta_tipeando := false

@export var velocidad_tipeo: float = 0.05  # segundos entre letras
@export var siguiente_escena: String = "res://scenes/quests/story_quests/FragmentOfNexus/0_FragmentOfNexus_intro/FragmentOfNexus_intro.tscn"

func _ready() ->void:
	narrador_texto.clear()
	mostrar_linea(lineas[linea_actual])

func _unhandled_input( event : InputEvent) ->void:
	if event.is_action_pressed("ui_accept"):
		if esta_tipeando:
			saltar_tipeo()
		elif esperando_input:
			linea_actual += 1
			if linea_actual < lineas.size():
				mostrar_linea(lineas[linea_actual])
			else:
				SceneSwitcher.change_to_file_with_transition(
					siguiente_escena,
					"",
					Transition.Effect.FADE,
					Transition.Effect.FADE
				)

func mostrar_linea(texto: String) ->void:
	narrador_texto.clear()
	esperando_input = false
	esta_tipeando = true
	_type_text(texto)

func saltar_tipeo() ->void:
	narrador_texto.visible_characters = -1
	esta_tipeando = false
	esperando_input = true

func _type_text(texto: String) -> void:
	narrador_texto.bbcode_text = texto
	narrador_texto.visible_characters = 0
	var total: int  = narrador_texto.get_total_character_count()

	await get_tree().process_frame  # Asegura que el texto esté cargado

	for i in range(total):
		if not esta_tipeando:
			break
		narrador_texto.visible_characters = i + 1
		await get_tree().create_timer(velocidad_tipeo).timeout

	esta_tipeando = false
	esperando_input = true
