# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const DIALOGO_STEALTH = preload("res://scenes/quests/story_quests/el_hilo_que_no_teji/1_stealth/stealth_components/el_hilo_que_no_teji_stealth.dialogue")

@onready var canvas_modulate = $CanvasModulate
@onready var sonido_ladrido = $ZonaClimax/LadridoLuto
@onready var particulas_doradas = $TileMapLayers/Tree/ParticulasDoradas
@onready var flecha = $TileMapLayers/Tree/Flecha
@onready var color_rect: ColorRect = $HUD/ColorRect

static var hilos_totales = 0
static var hilo1_tomado = false
static var hilo2_tomado = false
static var hilo3_tomado = false

# NUESTRO ESCUDO: Sabrá si la escena está en medio de una transición de Stella
var nivel_apagandose = false

func _ready():
	nivel_apagandose = false

	GameState.item_collected.connect(_on_item_collected)

	# Aplicar saturación actual al entrar al nivel
	_actualizar_saturacion()

	# Le decimos al nivel que avise un milisegundo antes de ser arrancado de la pantalla
	self.tree_exiting.connect(_activar_escudo)

	if hilo1_tomado and has_node("CollectibleItem"):
		$CollectibleItem.queue_free()

	if hilo2_tomado and has_node("CollectibleItem2"):
		$CollectibleItem2.queue_free()

	if hilo3_tomado and has_node("CollectibleItem3"):
		$CollectibleItem3.queue_free()

	actualizar_color()

func actualizar_color():
	canvas_modulate.color = Color(0.55, 0.55, 0.60)
	
	if hilos_totales >= 3 and flecha:
		flecha.visible = true


func _actualizar_saturacion() -> void:
	if not color_rect:
		return

	var shader_material: ShaderMaterial = color_rect.material as ShaderMaterial

	if not shader_material:
		return

	var saturation: float = min(
		float(GameState.items_collected().size()) * 0.03,
		1.0
	)

	shader_material.set_shader_parameter(
		"saturation",
		saturation
	)


func _on_item_collected(_item) -> void:
	_actualizar_saturacion()


# Esta función se ejecuta justo antes de que el nivel desaparezca por morir o cambiar de mapa
func _activar_escudo():
	nivel_apagandose = true


# --- EVENTOS DE LOS HILOS ---

func _on_collectible_item_tree_exited() -> void:
	# Si el escudo está activo, ignoramos este evento (fue una transición, no Lino)
	if nivel_apagandose:
		return

	if not hilo1_tomado:
		hilo1_tomado = true
		hilos_totales += 1
		actualizar_color()


func _on_collectible_item_2_tree_exited() -> void:
	if nivel_apagandose:
		return

	if not hilo2_tomado:
		hilo2_tomado = true
		hilos_totales += 1
		actualizar_color()


func _on_collectible_item_3_tree_exited() -> void:
	if nivel_apagandose:
		return

	if not hilo3_tomado:
		hilo3_tomado = true
		hilos_totales += 1
		actualizar_color()

# En el script de la raíz de tu nivel actual:
@onready var player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D

func _process(_delta: float) -> void:
	# Verificamos si el jugador está reproduciendo la animación normal
	if player_sprite.animation == "walk":
		player_sprite.animation = "c_walk"
	elif player_sprite.animation == "idle":
		player_sprite.animation = "c_idle"


func _on_zona_climax_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):

		if hilos_totales >= 3:
			print("¡CLÍMAX ALCANZADO!")

			# FIX ARQUITECTÓNICO: Frenamos a Lino en seco y le quitamos el control al usuario
			body.velocity = Vector2.ZERO
			body.take_control(self)

			$ZonaClimax.set_deferred("monitoring", false)

			if has_node("EnemyGuards"):
				$EnemyGuards.queue_free()

			particulas_doradas.emitting = true

			if flecha:
				flecha.visible = false

			# sonido_ladrido.play()

			DialogueManager.show_dialogue_balloon(
				DIALOGO_STEALTH,
				"arbol_climax"
			)

			await DialogueManager.dialogue_ended

			SceneSwitcher.change_to_file_with_transition(
				"res://scenes/quests/story_quests/el_hilo_que_no_teji/2_bridge/el_hilo_que_no_teji_combat.tscn"
			)

		else:
			print("Faltan hilos. Lino no puede enfrentar su culpa todavía.")
			# No hacemos nada, Lino sigue en modo USER_CONTROLLED y se aleja
