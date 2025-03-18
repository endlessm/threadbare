## A talker who can also play a musical instrument
@tool
class_name Bard
extends Talker

@export var xylophone: MusicalRockXylophone


func _on_interaction_started() -> void:
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	super()


func _on_got_dialogue(line: DialogueLine) -> void:
	# TODO: This is kind of an abuse of the tag system. It would be better to
	# use mutations so the dialogue waits for the play_note() method to finish.
	for tag: String in line.tags:
		if tag.begins_with("note-"):
			await xylophone.play_note(tag.right(-"note-".length()))


func _on_dialogue_ended(dialogue_resource: DialogueResource) -> void:
	DialogueManager.got_dialogue.disconnect(_on_got_dialogue)
	super(dialogue_resource)
