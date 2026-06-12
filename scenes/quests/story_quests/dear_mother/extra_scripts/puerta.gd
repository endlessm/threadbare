extends Area2D

## Escena a la que el jugador será transportado al hacer clic en "Sí".
@export_file("*.tscn") var next_scene: String

@onready var ui_popup: CanvasLayer = $UIPopup
@onready var btn_si: Button = $UIPopup/Panel/HBoxContainer/BtnSi
@onready var btn_no: Button = $UIPopup/Panel/HBoxContainer/BtnNo

func _ready()-> void:
	# Asegurarnos de que el popup esté oculto al iniciar el nivel
	ui_popup.hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("La puerta está tocando a: ", body.name)
	if body.name == "Player" or body.name == "Character": 
		ui_popup.show()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Character":
		ui_popup.hide()

func _on_btn_si_pressed() -> void:
	if next_scene != "":
		# Ocultamos el menú al momento de aceptar para que no estorbe en la transición
		ui_popup.hide()
		
		# Usamos SceneSwitcher
		SceneSwitcher.change_to_file_with_transition(
			next_scene,
			"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
	else:
		print("¡Error! No has asignado una escena destino a esta puerta en el Inspector.")

func _on_btn_no_pressed() -> void:
	# Si elige "Aún no", simplemente cerramos el popup
	ui_popup.hide()
