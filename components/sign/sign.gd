@tool
class_name Sign
extends Node2D
## A signpost that shows a message when the player-character is near.
##
## The signpost itself is blank, but you could try changing the texture property
## on the Sprite node in sign.tscn.

## The text to show when the player-character is close to the sign.
## [br][br]
## You can use
## [url=https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html
## ]BBCode[/url]
## to add bold, italics, and other formatting.
@export_multiline var text: String:
	# When this property is changed in the inspector, call the set_text() method.
	set = set_text

# Number of players currently standing in front of the sign.
var _players_detected := 0

@onready var player_detector: Area2D = $PlayerDetector
@onready var label: RichTextLabel = $Label


func _ready() -> void:
	# Set the initial text on the label now that the 'label' variable is available.
	set_text(text)

	# This is a @tool script so that we can preview the text on the sign in the editor. But we do
	# not want to detect the player while running in the editor.
	if Engine.is_editor_hint():
		return

	# Connect to signals that tell us when the player moves in front of the sign or moves away.
	player_detector.body_entered.connect(_on_player_entered)
	player_detector.body_exited.connect(_on_player_exited)

	# Update the initial visibility of the text.
	_update_visibility()


## Update the text shown on the sign.
func set_text(new_text: String) -> void:
	text = new_text

	# When the scene is loaded, the text is restored before the label is available. We will call
	# this again from the _ready() method.
	if is_node_ready():
		label.text = text


func _on_player_entered(_body: Node2D) -> void:
	_players_detected += 1
	_update_visibility()


func _on_player_exited(_body: Node2D) -> void:
	# Just because one player moved away from the front of the sign, we can't necessarily hide the
	# text because there might be another player there.
	# Update our count of players and then check whether we need to hide the text.
	_players_detected -= 1
	_update_visibility()


func _update_visibility() -> void:
	if _players_detected > 0:
		label.visible = true
	else:
		label.visible = false
