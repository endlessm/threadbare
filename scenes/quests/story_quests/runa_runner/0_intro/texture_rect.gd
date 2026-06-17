extends TextureRect

@onready var anim = $"../AnimationPlayer"

var indice = 0

var imagenes = [
	preload("res://scenes/quests/story_quests/runa_runner/0_intro/Picture Intro/intro1.jpg"),
	preload("res://scenes/quests/story_quests/runa_runner/0_intro/Picture Intro/intro2.jpg"),
	preload("res://scenes/quests/story_quests/runa_runner/0_intro/Picture Intro/intro3.jpg")
]

func _ready():
	texture = imagenes[0]
	anim.play("fade_in")

func _input(event):

	if event is InputEventKey and event.pressed:

		indice += 1

		if indice < imagenes.size():

			anim.play("fade_out")

			await anim.animation_finished

			texture = imagenes[indice]

			anim.play("fade_in")

		else:
			get_tree().change_scene_to_file(
				"res://scenes/quests/story_quests/runa_runner/0_intro/jugable_intro.tscn"
			)
