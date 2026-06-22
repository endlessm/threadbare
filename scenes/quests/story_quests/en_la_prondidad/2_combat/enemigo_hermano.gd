extends CharacterBody2D

signal combate_completado

@export var escena_combate: PackedScene
@export var contenedor_combate: Node
@export var player: Node
@export var camara_jugador: Camera2D
@export var animacion: AnimatedSprite2D

@export var oso: Sprite2D

@export var interact_area: InteractArea
@export var talk_behavior: TalkBehavior

@export var dialogo_final: DialogueResource
@export var titulo_dialogo_final: String = ""

var combate_actual: Node = null
var combate_activo: bool = false
var combate_ganado: bool = false

func _ready() -> void:
	if interact_area != null:
		interact_area.disabled = false
		interact_area.interaction_ended.connect(_on_dialogo_inicial_terminado)
		animacion.play("idle")
		

func _on_dialogo_inicial_terminado() -> void:
	if combate_ganado:
		return

	if combate_activo:
		return

	iniciar_combate.call_deferred()

func iniciar_combate() -> void:
	if escena_combate == null:
		return

	if contenedor_combate == null:
		return

	if player == null:
		return

	combate_activo = true

	if interact_area != null:
		interact_area.disabled = true

	bloquear_player()

	if camara_jugador != null:
		camara_jugador.enabled = false

	combate_actual = escena_combate.instantiate()
	contenedor_combate.add_child(combate_actual)

	if combate_actual.has_signal("combate_ganado"):
		combate_actual.combate_ganado.connect(_on_combate_ganado)

	var camara_combate: Camera2D = combate_actual.get_node_or_null("Camera2D")

	if camara_combate != null:
		camara_combate.enabled = true
		camara_combate.make_current()

func bloquear_player() -> void:
	if player == null:
		return

	if player is Player:
		player.mode = Player.Mode.SYSTEM_CONTROLLED
	elif player.has_method("take_control"):
		player.take_control(self)

	if player is CharacterBody2D:
		player.velocity = Vector2.ZERO

func devolver_player() -> void:
	if player == null:
		return

	if player is Player:
		player.mode = Player.Mode.USER_CONTROLLED
	elif player.has_method("return_control"):
		player.return_control(self)

func _on_combate_ganado() -> void:
	combate_ganado = true
	combate_activo = false
	oso.visible =true

	if camara_jugador != null:
		camara_jugador.enabled = true
		camara_jugador.make_current()

	if dialogo_final != null:
		DialogueManager.show_dialogue_balloon(dialogo_final, titulo_dialogo_final, [self, player])
		await DialogueManager.dialogue_ended

	devolver_player()
	combate_completado.emit()
