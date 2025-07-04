extends Control

var texts : Array = [
	"Holaaaa",
	"sdsdsd"
]

var current_text : int = 0

@onready var visual_text : RichTextLabel = $PanelContainer/RichTextLabel
@onready var animation_mark : AnimationPlayer = $PanelContainer/AnimationPlayer
@onready var mark : Control = $PanelContainer/Control
#@onready var animation_text : AnimationPlayer = $PanelContainer/AnimationPlayer

func _ready():
	visual_text.text = texts[current_text]
	mark.visible = 0
	show_text()

func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		next_text()
		set_process(false)

func next_text():
	if current_text < texts.size()-1:
		current_text +=1
		visual_text.text = texts[current_text]
		mark.visible = 0
		show_text()

func show_text():
	var tween = create_tween()
	tween.tween_property(visual_text,)
	pass

func finish_show_text():
	mark.visible = 1
	animation_mark.play("MasTexto")
	set_process(true)
