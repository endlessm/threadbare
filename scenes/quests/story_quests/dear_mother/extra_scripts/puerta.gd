extends Area2D

@export_file("*.tscn") var next_scene: String

@export var entrada_directa: bool = false 

@onready var ui_popup: CanvasLayer = $UIPopup
@onready var btn_si: Button = $UIPopup/Panel/HBoxContainer/BtnSi
@onready var btn_no: Button = $UIPopup/Panel/HBoxContainer/BtnNo
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	ui_popup.hide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Character": 
		if entrada_directa:
			iniciar_transicion()
		else:
			ui_popup.show() 

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Character":
		ui_popup.hide()

func _on_btn_si_pressed() -> void:
	ui_popup.hide()
	iniciar_transicion()

func _on_btn_no_pressed() -> void:
	ui_popup.hide()

func iniciar_transicion() -> void:
	if next_scene != "":
		get_tree().call_group("chasing_enemy", "set_process_mode", Node.PROCESS_MODE_DISABLED)
		
		set_deferred("monitoring", false)
		
		if anim_sprite:
			anim_sprite.play("Open")
		
		await get_tree().create_timer(0.9).timeout
		
		SceneSwitcher.change_to_file_with_transition(
			next_scene,
			"",
			Transition.Effect.FADE,
			Transition.Effect.FADE
		)
	else:
		print("¡Error! No has asignado una escena destino a esta puerta en el Inspector.")
