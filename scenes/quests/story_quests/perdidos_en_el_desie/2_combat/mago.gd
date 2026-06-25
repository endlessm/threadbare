# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var recurso_dialogo: DialogueResource
var esta_hablando: bool = false
var ya_hablo: bool = false


func _ready() -> void:
	$AnimatedSprite2D.play("default")


func _on_body_entered(_body: Node2D) -> void:
	if _body.name == "Player" and not esta_hablando and not ya_hablo:
		esta_hablando = true

		var player := get_tree().current_scene.find_child("Player", true, false) as Player
		if player:
			player.velocity = Vector2.ZERO
			player.mode = Player.Mode.SYSTEM_CONTROLLED

		var balloon_scene := load(
			"res://scenes/quests/story_quests/perdidos_en_el_desie/2_combat/balloon_guardian.tscn"
		)
		var balloon = balloon_scene.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(recurso_dialogo, "inicio_guardian")

		await balloon.tree_exited
		esta_hablando = false
		ya_hablo = true

		if player:
			player.mode = Player.Mode.USER_CONTROLLED

		var controller := get_tree().current_scene.get_node_or_null("CombatController")
		if controller:
			controller.activar_disparo()

		monitoring = false
		var sprite_mago := get_tree().current_scene.find_child("PixilartSprite(2)", true, false)
		if sprite_mago:
			sprite_mago.queue_free()
		queue_free()
