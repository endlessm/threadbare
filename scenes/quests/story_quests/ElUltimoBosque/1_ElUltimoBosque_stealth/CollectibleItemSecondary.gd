extends Node2D

@export var item: InventoryItem
@export var revealed: bool = true
@export_file("*.tscn") var next_scene: String
@export var collected_dialogue: DialogueResource
@export var dialogue_title: StringName = ""

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var appear_sound: AudioStreamPlayer = %AppearSound

func _ready() -> void:
	sprite_2d.texture = item.get_world_texture()
	interact_area.interaction_started.connect(_on_interacted)

func _on_interacted(player: Player, _from_right: bool) -> void:
	# Mostrar animación
	z_index += 1
	animation_player.play("collected")
	await animation_player.animation_finished

	# Enviar al HUD si es CustomInventoryItem y va al SecondaryHUD
	if item is CustomInventoryItem and item.target_hud == "SecondaryHUD":
		var hud = get_tree().get_current_scene().find_child("SecondaryHUD", true, false)
		if hud:
			hud.add_item(item)

	# Mostrar diálogo si hay
	if collected_dialogue:
		DialogueManager.show_dialogue_balloon(collected_dialogue, dialogue_title, [self, player])
		await DialogueManager.dialogue_ended

	interact_area.end_interaction()
	queue_free()

	# Cambiar de escena si corresponde
	if next_scene:
		SceneSwitcher.change_to_file_with_transition(next_scene)
