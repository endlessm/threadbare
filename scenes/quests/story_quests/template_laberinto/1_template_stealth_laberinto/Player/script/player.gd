extends CharacterBody2D
class_name Player_l

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_arma: AnimatedSprite2D = $arma/AnimatedSprite2D
@onready var stamina_bar: ProgressBar = $Stamina
@onready var pistola: Node2D = $arma
@onready var keys_label: Label = $CanvasLayer/Keys_label
@export var escena_bala: PackedScene
@export var vida_maxima := 100
@onready var camara := get_viewport().get_camera_2d()

var vida_actual := vida_maxima
@onready var vida_bar: ProgressBar = safe_get_node("../barra vida/ProgressBar")
@onready var balas_vista = safe_get_node("../BalasVista")

@export var WALK_SPEED = 300.0
@export var RUN_SPEED = 500.0

var current_speed = WALK_SPEED
var last_direction = Vector2.DOWN

const MAX_STAMINA = 100.0
var current_stamina = MAX_STAMINA
const STAMINA_DRAIN_RATE = 20.0
const STAMINA_REGEN_RATE = 6.0
var is_running = false
var can_run = true

var current_chest: Chest = null
var keys_collected: int = 0
var current_door: Puerta = null

func safe_get_node(path: NodePath) -> Node:
	if has_node(path):
		return get_node(path)
	return null

func configurar_inputs():
	if not InputMap.has_action("disparar"):
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.add_action("disparar")
		InputMap.action_add_event("disparar", mouse_event)
	if not InputMap.has_action("Interact"):
		var key_e := InputEventKey.new()
		key_e.physical_keycode = KEY_E
		InputMap.add_action("Interact")
		InputMap.action_add_event("Interact", key_e)
		
	if not InputMap.has_action("run"):
		var shift_event := InputEventKey.new()
		shift_event.physical_keycode = KEY_SHIFT  # O KEY_SHIFT_L / KEY_SHIFT_R si quieres especificar
		InputMap.add_action("run")
		InputMap.action_add_event("run", shift_event)
	if not InputMap.has_action("recargar"):
		var key_r := InputEventKey.new()
		key_r.physical_keycode = KEY_R
		InputMap.add_action("recargar")
		InputMap.action_add_event("recargar", key_r)

func _ready() -> void:
	add_to_group("player")
	configurar_inputs()
	setup_stamina_bar()
	if vida_bar:
		vida_bar.max_value = vida_maxima
		vida_bar.value = vida_actual
		actualizar_color_vida()

func setup_stamina_bar() -> void:
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = current_stamina
	stamina_bar.show_percentage = false
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	stamina_bar.add_theme_stylebox_override("background", bg_style)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	stamina_bar.add_theme_stylebox_override("fill", fill_style)

func _physics_process(delta: float) -> void:
	if camara and keys_label:
		var screen_position = camara.get_screen_center_position() + (global_position - camara.global_position)
		keys_label.position = screen_position + Vector2(-720, -280)  # Ajusta Y según necesites
	handle_stamina(delta)
	actualizar_pistola()
	if Input.is_action_just_pressed("disparar"):
		disparar()
	if Input.is_action_just_pressed("recargar"):
		recargar()
	if Input.is_action_pressed("run") && can_run && current_stamina > 0:
		current_speed = RUN_SPEED
		is_running = true
	else:
		current_speed = WALK_SPEED
		is_running = false

	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	velocity = input_vector * current_speed
	handle_animations(input_vector)
	move_and_slide()
	handle_interaction()

func handle_stamina(delta: float) -> void:
	if is_running:
		current_stamina -= STAMINA_DRAIN_RATE * delta
		if current_stamina <= 0:
			current_stamina = 0
			can_run = false
	else:
		current_stamina += STAMINA_REGEN_RATE * delta
		if current_stamina >= MAX_STAMINA:
			current_stamina = MAX_STAMINA
			can_run = true
	update_stamina_bar()

func update_stamina_bar() -> void:
	var tween = create_tween()
	tween.tween_property(stamina_bar, "value", current_stamina, 0.1)
	var fill_style = stamina_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		var style = fill_style as StyleBoxFlat
		if current_stamina > 60:
			style.bg_color = Color(0.2, 0.8, 0.3, 1.0)
		elif current_stamina > 30:
			style.bg_color = Color(0.8, 0.8, 0.2, 1.0)
		else:
			style.bg_color = Color(0.8, 0.2, 0.2, 1.0)

func actualizar_pistola():
	var direccion = (get_global_mouse_position() - global_position).normalized()
	var angulo = direccion.angle()
	pistola.rotation = angulo
	var radio = 23.0
	pistola.position = Vector2.RIGHT.rotated(angulo) * radio
	animated_arma.flip_v = rad_to_deg(angulo) > 90 or rad_to_deg(angulo) < -90

func recargar():
	animated_arma.play("arma_recarga")
	print("recargar")

func disparar():
	if balas_vista and balas_vista.procesar_disparo():
		animated_arma.play("disparo_revolver")
		var bala = escena_bala.instantiate()
		bala.global_position = $arma/Marker2D.global_position
		bala.direction = Vector2.RIGHT.rotated($arma.global_rotation)
		get_tree().current_scene.add_child(bala)
	else:
		print("¡Sin balas!")

func handle_animations(movement_vector: Vector2) -> void:
	if movement_vector != Vector2.ZERO:
		last_direction = movement_vector
	var is_moving = movement_vector != Vector2.ZERO
	var anim_name = ""
	if is_moving:
		if abs(movement_vector.x) >= abs(movement_vector.y):
			anim_name = "MoveDerecha" if movement_vector.x > 0 else "MoveIzquierda"
		else:
			anim_name = "MoveAbajo" if movement_vector.y > 0 else "MoveArriba"
	else:
		if abs(last_direction.x) >= abs(last_direction.y):
			anim_name = "IdleDerecha" if last_direction.x > 0 else "IdleIzquierda"
		else:
			anim_name = "IdleAbajo" if last_direction.y > 0 else "IdleArriba"
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func handle_interaction():
	if current_chest and Input.is_action_pressed("Interact"):
		current_chest.start_interaction()
	elif current_chest and not Input.is_action_pressed("Interact"):
		current_chest.stop_interaction()
	if current_door and Input.is_action_just_pressed("Interact"):
		current_door.interact()

func set_current_chest(chest: Chest):
	if current_chest and current_chest != chest:
		current_chest.player_exit()
	current_chest = chest

func clear_current_chest():
	current_chest = null

func set_current_door(door: Puerta):
	if current_door and current_door != door:
		current_door.player_exit()
	current_door = door

func clear_current_door():
	current_door = null

func collect_key():
	keys_collected += 1
	print("¡Llave obtenida! Total: ", keys_collected)
	update_keys_ui()
	if current_door:
		current_door.check_door_status()

func update_keys_ui():
	keys_label.text = "Llaves obtenidas: " + str(keys_collected)

func recibir_daño(cantidad: int):
	print("Recibiendo daño:", cantidad)
	vida_actual -= cantidad
	vida_actual = max(vida_actual, 0)
	if vida_bar:
		vida_bar.value = vida_actual
		print("valor actualizado en ProgressBar:", vida_bar.value)
		actualizar_color_vida()
	if vida_actual <= 0:
		morir()

func actualizar_color_vida():
	if not vida_bar:
		return
	var barra := vida_bar.get_theme_stylebox("fill")
	if barra is StyleBoxFlat:
		var color := Color(0.2, 0.8, 0.3)
		if vida_actual <= 30:
			color = Color(0.8, 0.2, 0.2)
		elif vida_actual <= 60:
			color = Color(0.8, 0.8, 0.2)
		barra.bg_color = color

signal jugador_derrotado
func morir():
	emit_signal("jugador_derrotado")
	visible = false
	GameStateLaberinto.reset()
	get_tree().reload_current_scene()
	print("¡Jugador derrotado!")

func get_cofres_abiertos() -> Array:
	var ids: Array = []
	for cofre in get_tree().get_nodes_in_group("cofre"):
		if cofre.is_opened:
			ids.append(cofre.name)
	return ids

func set_cofres_abiertos(ids: Array):
	for cofre in get_tree().get_nodes_in_group("cofre"):
		if cofre.name in ids:
			cofre.abrir_sin_interaccion()
