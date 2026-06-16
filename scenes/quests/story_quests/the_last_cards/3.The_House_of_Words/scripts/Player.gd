# player.gd
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

const MOVE_SPEED: float = 250.0
const LOOK_AT_TURN_SPEED: float = 10.0

signal letra_iluminada(node: Node2D)
signal letra_oscurecida(node: Node2D)

@onready var detection_area: Area2D               = %DetectionArea
@onready var sight_ray_cast: RayCast2D            = %SightRayCast
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer    = $AnimationPlayer
@onready var luz: PointLight2D                    = $PointLight2D

var _last_direction: Vector2 = Vector2.RIGHT
var _mini_camera: Camera2D = null

func _ready() -> void:
	add_to_group("player")
	detection_area.add_to_group("player")
	detection_area.area_entered.connect(_on_detection_area_area_entered)
	detection_area.area_exited.connect(_on_detection_area_area_exited)
	_configurar_luz()
	_configurar_mini_vista()

func _configurar_luz() -> void:
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(1, 1, 1, 1))
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura = GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 150
	textura.height = 150
	luz.texture = textura
	luz.color = Color(0.981, 0.987, 0.998, 1.0)
	luz.energy = 1
	luz.texture_scale = 1

func _configurar_mini_vista() -> void:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(200, 150)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = get_viewport().world_2d

	_mini_camera = Camera2D.new()
	
	var escena_ancho = 3520.0
	var escena_alto = 1300.0
	
	var zoom_x = 200.0 / escena_ancho
	var zoom_y = 150.0 / escena_alto
	var zoom_final = min(zoom_x, zoom_y)
	
	_mini_camera.zoom = Vector2(zoom_final, zoom_final)
	
	#  valores para centrar está tu escena
	var centro_x = 1760.0  # mitad del ancho
	var centro_y = 650.0   # mitad del alto
	_mini_camera.global_position = Vector2(centro_x, centro_y)
	
	# Fondo negro en lugar de gris
	viewport.transparent_bg = true
	
	viewport.add_child(_mini_camera)

	var container = SubViewportContainer.new()
	container.stretch = true
	container.size = Vector2(200, 150)
	container.add_child(viewport)

	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	canvas.add_child(container)

	container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	container.offset_left = -210
	container.offset_top = -160
	container.offset_right = -10
	container.offset_bottom = -10
	
func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x = 1.0
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1.0
		animated_sprite_2d.flip_h = true
	if Input.is_action_pressed("ui_up"):
		input_dir.y = -1.0
	elif Input.is_action_pressed("ui_down"):
		input_dir.y = 1.0

	velocity = input_dir.normalized() * MOVE_SPEED
	move_and_slide()

	if not input_dir.is_zero_approx():
		_last_direction = input_dir.normalized()

	var target_angle := _last_direction.angle()
	detection_area.rotation = rotate_toward(
		detection_area.rotation,
		target_angle,
		delta * LOOK_AT_TURN_SPEED
	)
	_update_animation()

	# Actualizar posición de la mini cámara
	if _mini_camera:
		_mini_camera.global_position = global_position

func _update_animation() -> void:
	if velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		animation_player.play(&"walk")

func _on_detection_area_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hidden_letter"):
		return
	if _is_sight_to_point_blocked(area.global_position):
		return
	letra_iluminada.emit(area)

func _on_detection_area_area_exited(area: Area2D) -> void:
	if not area.is_in_group("hidden_letter"):
		return
	letra_oscurecida.emit(area)

func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()
