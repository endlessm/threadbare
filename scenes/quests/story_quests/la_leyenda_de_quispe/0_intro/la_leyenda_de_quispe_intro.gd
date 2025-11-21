extends Node2D

@export var dialogue_resource: DialogueResource
@onready var animation_player: AnimationPlayer = $OnTheGround/AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $OnTheGround/Personajes

func _ready() -> void:
	DatosGlobales.cinematica_actual = self
	DatosGlobales.anim_player_intro = animation_player
	await get_tree().process_frame
	start_intro()

func start_intro() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func cambiar_sprite(nombre_anim: String) -> void:
	if animated_sprite.sprite_frames.has_animation(nombre_anim):
		animated_sprite.play(nombre_anim)
	else:
		print("⚠️ Error: No existe la animación de sprite: ", nombre_anim)

func mover_personaje(nombre_anim: String) -> void:
	if animation_player.has_animation(nombre_anim):
		animation_player.play(nombre_anim)
	else:
		print("⚠️ Error: No existe la animación de movimiento: ", nombre_anim)
